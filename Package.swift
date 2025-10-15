// swift-tools-version: 5.9
import PackageDescription

struct GoogleCastMetadata {
    static let version: String = "4.8.3"
    static let checksum: String = "bc2c3c2434ef2895a0388ac3f16932242d3d3ac11805f810dbe7d7bce3bb27f6"
}

let package = Package(
    name: "CapgoCapacitorJwPlayer",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapgoCapacitorJwPlayer",
            targets: ["JwPlayerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", exact: "7.4.2"),
        .package(url: "https://github.com/jwplayer/JWPlayerKit-package.git", .upToNextMajor(from: "4.23.1"))
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
