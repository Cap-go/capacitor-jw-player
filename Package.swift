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
        .package(url: "https://github.com/jwplayer/JWPlayerKit-package.git", .upToNextMajor(from: "4.16.0"))
    ],
    targets: [
        .target(
            name: "JwPlayerPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "JWPlayerKit", package: "JWPlayerKit-package")
            ],
            path: "ios/Sources/JwPlayerPlugin"),
        .testTarget(
            name: "JwPlayerPluginTests",
            dependencies: ["JwPlayerPlugin"],
            path: "ios/Tests/JwPlayerPluginTests")
    ]
)
