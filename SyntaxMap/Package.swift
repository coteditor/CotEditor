// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "SyntaxMap",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "SyntaxMap", targets: ["SyntaxMap"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: Version(1, 3, 0)),
        .package(url: "https://github.com/jpsim/Yams", from: Version(5, 0, 0)),
    ],
    targets: [
        .executableTarget(
            name: "SyntaxMapBuilder",
            dependencies: [
                "SyntaxMap",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]),
        .target(name: "SyntaxMap", dependencies: ["Yams"],
                swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]),
        
        .testTarget(
            name: "SyntaxMapTests",
            dependencies: ["SyntaxMap"],
            resources: [.copy("Syntaxes")],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]),
    ]
)
