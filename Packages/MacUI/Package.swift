// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacUI",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "MacUI", targets: [
            "ControlUI",
            "RegexHighlighting",
            "Shortcut",
        ]),
        
        .library(name: "RegexHighlighting", targets: ["RegexHighlighting"]),
        .library(name: "Shortcut", targets: ["Shortcut"]),
    ],
    dependencies: [
        .package(name: "EditorCore", path: "../EditorCore"),
        .package(url: "https://github.com/realm/SwiftLint", from: Version(0, 55, 0)),
    ],
    targets: [
        .target(name: "ControlUI"),
        
        .target(name: "RegexHighlighting", dependencies: ["EditorCore"]),
        .testTarget(name: "RegexHighlightingTests", dependencies: ["RegexHighlighting"]),
        
        .target(name: "Shortcut", resources: [.process("Resources")]),
        .testTarget(name: "ShortcutTests", dependencies: ["Shortcut"]),
    ],
    swiftLanguageVersions: [.v6]
)


for target in package.targets {
    target.plugins = [
        .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")
    ]
}
