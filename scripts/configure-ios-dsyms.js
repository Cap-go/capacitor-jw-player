#!/usr/bin/env node

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const pluginName = 'CapgoCapacitorJwPlayer';
const frameworkNames = ['JWPlayerKit', 'GoogleCast'];
const phaseName = 'Capgo dSYMs for JWPlayerKit and GoogleCast';

function log(message) {
  console.log(`[${pluginName}] ${message}`);
}

function warn(message) {
  console.warn(`[${pluginName}] ${message}`);
}

function exists(filePath) {
  return fs.existsSync(filePath);
}

function stablePbxId(seed) {
  return crypto.createHash('sha1').update(seed).digest('hex').slice(0, 24).toUpperCase();
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function findExistingPhaseId(content) {
  const pattern = new RegExp(
    `([A-F0-9]{24}) /\\* ${escapeRegExp(phaseName)} \\*/ = \\{[\\s\\S]*?isa = PBXShellScriptBuildPhase;`,
    'm',
  );
  return pattern.exec(content)?.[1] || '';
}

function findProjectFile(rootDir) {
  const preferred = path.join(rootDir, 'ios', 'App', 'App.xcodeproj', 'project.pbxproj');
  if (exists(preferred)) {
    return preferred;
  }

  const iosDir = path.join(rootDir, 'ios');
  if (!exists(iosDir)) {
    return '';
  }

  const stack = [iosDir];
  while (stack.length) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      const entryPath = path.join(current, entry.name);
      if (entry.isDirectory() && entry.name.endsWith('.xcodeproj')) {
        const pbxproj = path.join(entryPath, 'project.pbxproj');
        if (exists(pbxproj)) {
          return pbxproj;
        }
        continue;
      }
      if (entry.isDirectory()) {
        stack.push(entryPath);
      }
    }
  }

  return '';
}

function shellScript() {
  return [
    'set -u',
    '',
    'if [ "${ACTION:-}" != "install" ]; then',
    '  exit 0',
    'fi',
    '',
    `log() { echo "[${pluginName} dSYMs] $1"; }`,
    '',
    'if [ -z "${DWARF_DSYM_FOLDER_PATH:-}" ]; then',
    '  log "Skipping because DWARF_DSYM_FOLDER_PATH is not set."',
    '  exit 0',
    'fi',
    '',
    'find_dsym_roots() {',
    '  for root in \\',
    '    "${PODS_ROOT:-}" \\',
    '    "${SRCROOT:-}" \\',
    '    "${PROJECT_DIR:-}" \\',
    '    "${BUILD_DIR:-}/../../SourcePackages/artifacts" \\',
    '    "${BUILD_DIR:-}/../SourcePackages/artifacts" \\',
    '    "${HOME:-}/Library/Developer/Xcode/DerivedData"',
    '  do',
    '    [ -d "$root" ] || continue',
    '    printf "%s\\n" "$root"',
    '  done',
    '}',
    '',
    'find_framework_binary_in_roots() {',
    '  framework="$1"',
    '  old_ifs="$IFS"',
    "  IFS='",
    "'",
    '  for root in $(find_dsym_roots); do',
    '    for binary in $(find "$root" -type f -path "*/$framework.framework/$framework" 2>/dev/null); do',
    '      case "$binary" in',
    '        *simulator*|*Simulator*) continue ;;',
    '      esac',
    '      if [ -f "$binary" ]; then',
    '        printf "%s\\n" "$binary"',
    '        IFS="$old_ifs"',
    '        return 0',
    '      fi',
    '    done',
    '  done',
    '  IFS="$old_ifs"',
    '  return 1',
    '}',
    '',
    'find_framework_binary() {',
    '  framework="$1"',
    '  for dir in \\',
    '    "${TARGET_BUILD_DIR:-}/${FRAMEWORKS_FOLDER_PATH:-}" \\',
    '    "${BUILT_PRODUCTS_DIR:-}/${FRAMEWORKS_FOLDER_PATH:-}" \\',
    '    "${TARGET_BUILD_DIR:-}/${WRAPPER_NAME:-}/Frameworks" \\',
    '    "${BUILT_PRODUCTS_DIR:-}/${WRAPPER_NAME:-}/Frameworks" \\',
    '    "${TARGET_BUILD_DIR:-}/Frameworks" \\',
    '    "${BUILT_PRODUCTS_DIR:-}/Frameworks"',
    '  do',
    '    [ -n "$dir" ] || continue',
    '    binary="$dir/$framework.framework/$framework"',
    '    if [ -f "$binary" ]; then',
    '      printf "%s\\n" "$binary"',
    '      return 0',
    '    fi',
    '  done',
    '  find_framework_binary_in_roots "$framework"',
    '}',
    '',
    'copy_prebuilt_dsym() {',
    '  framework="$1"',
    '  dsym_path="$2"',
    '  binary="$3"',
    '  binary_uuid="$(dwarfdump --uuid "$binary" 2>/dev/null | awk \'NR == 1 {print $2}\')"',
    '  [ -n "$binary_uuid" ] || return 1',
    '',
    '  old_ifs="$IFS"',
    "  IFS='",
    "'",
    '  for root in $(find_dsym_roots); do',
    '    for candidate in $(find "$root" -type d -name "$framework.framework.dSYM" 2>/dev/null); do',
    '      if dwarfdump --uuid "$candidate" 2>/dev/null | awk \'{print $2}\' | grep -qi "^$binary_uuid$"; then',
    '        rm -rf "$dsym_path"',
    '        cp -R "$candidate" "$dsym_path"',
    '        IFS="$old_ifs"',
    '        log "Copied vendor $framework.framework.dSYM."',
    '        return 0',
    '      fi',
    '    done',
    '  done',
    '  IFS="$old_ifs"',
    '  return 1',
    '}',
    '',
    'copy_to_archive() {',
    '  dsym_path="$1"',
    '  framework="$2"',
    '  for archive_dsyms in "${ARCHIVE_DSYMS_PATH:-}" "${ARCHIVE_PATH:-}/dSYMs"; do',
    '    case "$archive_dsyms" in',
    '      ""|"/dSYMs") continue ;;',
    '    esac',
    '    mkdir -p "$archive_dsyms"',
    '    rm -rf "$archive_dsyms/$framework.framework.dSYM"',
    '    cp -R "$dsym_path" "$archive_dsyms/"',
    '  done',
    '}',
    '',
    'mkdir -p "$DWARF_DSYM_FOLDER_PATH"',
    '',
    `for framework in ${frameworkNames.join(' ')}; do`,
    '  binary="$(find_framework_binary "$framework" || true)"',
    '  if [ -z "$binary" ]; then',
    '    log "Skipping $framework because a framework binary was not found."',
    '    continue',
    '  fi',
    '',
    '  dsym_path="$DWARF_DSYM_FOLDER_PATH/$framework.framework.dSYM"',
    '  rm -rf "$dsym_path"',
    '  if copy_prebuilt_dsym "$framework" "$dsym_path" "$binary"; then',
    '    copy_to_archive "$dsym_path" "$framework"',
    '    continue',
    '  fi',
    '',
    '  if xcrun dsymutil "$binary" -o "$dsym_path" >/dev/null; then',
    '    log "Prepared $framework.framework.dSYM."',
    '    copy_to_archive "$dsym_path" "$framework"',
    '  else',
    '    log "Failed to generate $framework.framework.dSYM."',
    '  fi',
    'done',
    '',
  ].join('\n');
}

function phaseObject(phaseId) {
  const quotedScript = JSON.stringify(shellScript());
  return `\t\t${phaseId} /* ${phaseName} */ = {
\t\t\tisa = PBXShellScriptBuildPhase;
\t\t\talwaysOutOfDate = 1;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\tinputFileListPaths = (
\t\t\t);
\t\t\tinputPaths = (
\t\t\t);
\t\t\tname = "${phaseName}";
\t\t\toutputFileListPaths = (
\t\t\t);
\t\t\toutputPaths = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t\tshellPath = /bin/sh;
\t\t\tshellScript = ${quotedScript};
\t\t};`;
}

function addShellScriptPhase(content, phaseId) {
  if (findExistingPhaseId(content)) {
    return content;
  }

  const object = phaseObject(phaseId);
  if (content.includes('/* Begin PBXShellScriptBuildPhase section */')) {
    return content.replace(
      '/* End PBXShellScriptBuildPhase section */',
      `${object}\n/* End PBXShellScriptBuildPhase section */`,
    );
  }

  return content.replace(
    '/* Begin PBXSourcesBuildPhase section */',
    `/* Begin PBXShellScriptBuildPhase section */\n${object}\n/* End PBXShellScriptBuildPhase section */\n\n/* Begin PBXSourcesBuildPhase section */`,
  );
}

function addPhaseToApplicationTarget(content, phaseId) {
  const targetPattern = /[A-F0-9]{24} \/\* [^*]+ \*\/ = \{[\s\S]*?\n\t\t\};/g;
  const targetMatch = Array.from(content.matchAll(targetPattern)).find((match) => {
    const targetBlock = match[0];
    return (
      targetBlock.includes('isa = PBXNativeTarget;') &&
      targetBlock.includes('productType = "com.apple.product-type.application";')
    );
  });

  if (!targetMatch) {
    warn('Skipping iOS dSYM configuration because no application target was found.');
    return content;
  }

  const targetBlock = targetMatch[0];
  if (targetBlock.includes(`${phaseId} /* ${phaseName} */`)) {
    return content;
  }

  const nextTargetBlock = targetBlock.replace(/buildPhases = \(([\s\S]*?)\n\t\t\t\);/, (_match, phases) => {
    return `buildPhases = (${phases}\n\t\t\t\t${phaseId} /* ${phaseName} */,\n\t\t\t);`;
  });

  if (nextTargetBlock === targetBlock) {
    warn('Skipping iOS dSYM configuration because the application target build phases could not be updated.');
    return content;
  }

  return content.replace(targetBlock, nextTargetBlock);
}

function configureIosDsyms() {
  if (process.env.CAPACITOR_PLATFORM_NAME !== 'ios') {
    return;
  }

  const rootDir = process.env.CAPACITOR_ROOT_DIR;
  if (!rootDir) {
    warn('Skipping iOS dSYM configuration because CAPACITOR_ROOT_DIR is missing.');
    return;
  }

  const projectFile = findProjectFile(rootDir);
  if (!projectFile) {
    warn('Skipping iOS dSYM configuration because no Xcode project was found.');
    return;
  }

  const currentContent = fs.readFileSync(projectFile, 'utf8');
  const phaseId = findExistingPhaseId(currentContent) || stablePbxId(phaseName);
  let nextContent = addShellScriptPhase(currentContent, phaseId);
  nextContent = addPhaseToApplicationTarget(nextContent, phaseId);

  if (nextContent === currentContent) {
    log('iOS vendor dSYM archive phase is already configured.');
    return;
  }

  fs.writeFileSync(projectFile, nextContent, 'utf8');
  log('Configured iOS vendor dSYM archive phase.');
}

configureIosDsyms();
