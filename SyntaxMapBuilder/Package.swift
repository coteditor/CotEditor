// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "SyntaxMapBuilder",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .executable(name: "SyntaxMapBuilder", targets: ["SyntaxMapBuilder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams", from: Version(3, 0, 0)),
    ],
    targets: [
        .target(name: "SyntaxMapBuilder", dependencies: ["Yams"]),
        .testTarget(name: "SyntaxMapBuilderTests", dependencies: ["SyntaxMapBuilder"]),
    ],
    swiftLanguageVersions: [
        .v5,
    ]
)
