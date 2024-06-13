// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Libraries",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "CharacterInfo", targets: ["CharacterInfo"]),
    ],
    targets: [
        .target(name: "CharacterInfo", resources: [.process("Resources")]),
        .testTarget(name: "CharacterInfoTests", dependencies: ["CharacterInfo"]),
    ],
    swiftLanguageVersions: [.v6]
)
