// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MacUI",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
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
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: Version(0, 59, 0)),
    ],
    targets: [
        .target(name: "ControlUI", dependencies: ["EditorCore"]),
        
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
        .swiftLanguageMode(.v6),
        
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
