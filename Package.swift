// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapgoCapacitorJwPlayer",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CapgoCapacitorJwPlayer",
            targets: ["JwPlayerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0"),
        .package(url: "https://github.com/jwplayer/JWPlayerKit-package.git", .upToNextMajor(from: "4.21.3"))
    ],
    targets: [
        .target(
            name: "JwPlayerPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "JWPlayerKit", package: "JWPlayerKit-package"),
                .target(name: "GoogleCast")
            ],
            path: "ios/Sources/JwPlayerPlugin"),
        .binaryTarget(
            name: "GoogleCast",
            url: "https://dl.google.com/dl/chromecast/sdk/ios/GoogleCastSDK-ios-4.8.1_dynamic.xcframework.zip",
            checksum: "ab9dbab873fff677deb2cfd95ea60b9295ebd53b58ec8533e9e1110b2451e540"
        ),
        .testTarget(
            name: "JwPlayerPluginTests",
            dependencies: ["JwPlayerPlugin"],
            path: "ios/Tests/JwPlayerPluginTests")
    ]
)
