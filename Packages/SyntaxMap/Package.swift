// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        .package(url: "https://github.com/realm/SwiftLint", from: Version(0, 56, 0)),
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
    ],
    swiftLanguageModes: [.v6]
)


for target in package.targets {
    target.plugins = [
        .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")
    ]
}
