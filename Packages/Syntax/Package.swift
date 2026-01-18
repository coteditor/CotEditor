// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Syntax",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "Syntax", targets: ["Syntax"]),
    ],
    dependencies: [
        .package(name: "EditorCore", path: "../EditorCore"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: Version(1, 7, 0)),
        .package(url: "https://github.com/jpsim/Yams", from: Version(6, 2, 0)),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: Version(0, 62, 0)),
    ],
    targets: [
        .target(
            name: "Syntax",
            dependencies: ["EditorCore", "Yams"],
            resources: [.process("Resources")]),
        .testTarget(name: "SyntaxTests", dependencies: ["Syntax"], resources: [.copy("Syntaxes")]),
        
        .executableTarget(
            name: "SyntaxMapBuilder",
            dependencies: [
                "Syntax",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
    
        .executableTarget(
            name: "SyntaxMigrator",
            dependencies: [
                "Syntax",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
    ],
    swiftLanguageModes: [.v6]
)


for target in package.targets {
    target.plugins = [
        .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
    ]
    target.swiftSettings = [
        .strictMemorySafety(),
        
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
