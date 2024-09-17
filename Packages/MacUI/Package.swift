// swift-tools-version: 6.0

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
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: Version(0, 57, 0)),
    ],
    targets: [
        .target(name: "ControlUI"),
        
        .target(name: "RegexHighlighting", dependencies: ["EditorCore"]),
        .testTarget(name: "RegexHighlightingTests", dependencies: ["RegexHighlighting"]),
        
        .target(name: "Shortcut", resources: [.process("Resources")]),
        .testTarget(name: "ShortcutTests", dependencies: ["Shortcut"]),
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
