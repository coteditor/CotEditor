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
        .package(url: "https://github.com/tree-sitter/swift-tree-sitter", branch: "main"),
        
        .package(url: "https://github.com/1024jp/tree-sitter-c", branch: "swiftPackage"),
        .package(url: "https://github.com/1024jp/tree-sitter-css", branch: "swiftPackage"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-go", from: Version(0, 25, 0)),
        .package(url: "https://github.com/tree-sitter/tree-sitter-html", from: Version(0, 23, 2)),
        .package(url: "https://github.com/tree-sitter/tree-sitter-java", from: Version(0, 23, 5)),
        .package(url: "https://github.com/1024jp/tree-sitter-javascript", branch: "swiftPackage"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-php", from: Version(0, 24, 2)),
        .package(url: "https://github.com/1024jp/tree-sitter-python", branch: "swiftPackage"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-ruby", from: Version(0, 23, 1)),
        .package(url: "https://github.com/tree-sitter/tree-sitter-rust", from: Version(0, 24, 0)),
        .package(url: "https://github.com/tree-sitter/tree-sitter-scala", from: Version(0, 24, 0)),
        .package(url: "https://github.com/alex-pinkus/tree-sitter-swift", branch: "with-generated-files"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-typescript", from: Version(0, 23, 2)),
    ],
    targets: [
        .target(
            name: "Syntax",
            dependencies: [
                "EditorCore",
                "Yams",
                .product(name: "SwiftTreeSitterLayer", package: "swift-tree-sitter"),
                .product(name: "TreeSitterC", package: "tree-sitter-c"),
                .product(name: "TreeSitterCSS", package: "tree-sitter-css"),
                .product(name: "TreeSitterGo", package: "tree-sitter-go"),
                .product(name: "TreeSitterHTML", package: "tree-sitter-html"),
                .product(name: "TreeSitterJava", package: "tree-sitter-java"),
                .product(name: "TreeSitterJavaScript", package: "tree-sitter-javascript"),
                .product(name: "TreeSitterPHP", package: "tree-sitter-php"),
                .product(name: "TreeSitterPython", package: "tree-sitter-python"),
                .product(name: "TreeSitterRuby", package: "tree-sitter-ruby"),
                .product(name: "TreeSitterRust", package: "tree-sitter-rust"),
                .product(name: "TreeSitterScala", package: "tree-sitter-scala"),
                .product(name: "TreeSitterSwift", package: "tree-sitter-swift"),
                .product(name: "TreeSitterTypeScript", package: "tree-sitter-typescript"),
            ],
            resources: [.process("Resources"), .copy("Syntaxes")]),
        .testTarget(
            name: "SyntaxTests",
            dependencies: ["Syntax", "EditorCore"],
            exclude: ["Samples"],
            resources: [.copy("Syntaxes")]
        ),
        
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
