// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "SyntaxMapBuilder",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: Version(1, 1, 0)),
        .package(url: "https://github.com/jpsim/Yams", from: Version(5, 0, 0)),
    ],
    targets: [
        .executableTarget(
            name: "SyntaxMapBuilder",
            dependencies: [
                "Yams",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        
        .testTarget(
            name: "SyntaxMapBuilderTests",
            dependencies: ["SyntaxMapBuilder"],
            resources: [.copy("Syntaxes")]),
    ]
)
