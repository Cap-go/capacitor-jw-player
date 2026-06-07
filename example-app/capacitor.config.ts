import type { CapacitorConfig } from '@capacitor/cli';

import pkg from './package.json';

const config: CapacitorConfig = {
  appId: 'app.capgo.jw.player',
  appName: 'Jw Player Example',
  webDir: 'dist',
  plugins: {
    SplashScreen: {
      launchAutoHide: false,
    },
    CapacitorUpdater: {
      appId: 'app.capgo.jw.player',
      autoUpdate: true,
      autoSplashscreen: true,
      directUpdate: 'always',
      defaultChannel: 'production',
      version: pkg.version,
    },
  },
};

export default config;
