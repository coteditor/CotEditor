// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SyntaxMap",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "SyntaxMap", targets: ["SyntaxMap"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: Version(1, 3, 0)),
        .package(url: "https://github.com/jpsim/Yams", from: Version(5, 0, 0)),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: Version(0, 57, 0)),
    ],
    targets: [
        .executableTarget(
            name: "SyntaxMapBuilder",
            dependencies: [
                "SyntaxMap",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .target(name: "SyntaxMap", dependencies: ["Yams"]),
        
        .testTarget(
            name: "SyntaxMapTests",
            dependencies: ["SyntaxMap"],
            resources: [.copy("Syntaxes")]),
    ]
)


for target in package.targets {
    target.plugins = [
        .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
    ]
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
    ]
}
