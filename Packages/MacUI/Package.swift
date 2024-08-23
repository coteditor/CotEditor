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
        .package(name: "Invisible", path: "../EditorCore"),
        .package(url: "https://github.com/realm/SwiftLint", from: Version(0, 56, 0)),
    ],
    targets: [
        .target(name: "ControlUI"),
        
        .target(name: "RegexHighlighting", dependencies: ["Invisible"]),
        .testTarget(name: "RegexHighlightingTests", dependencies: ["RegexHighlighting"]),
        
        .target(name: "Shortcut", resources: [.process("Resources")]),
        .testTarget(name: "ShortcutTests", dependencies: ["Shortcut"]),
    ]
)


for target in package.targets {
    target.plugins = [
        .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint"),
    ]
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
    ]
}
