// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EditorKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "EditorKit", targets: [
            "CharacterInfo",
            "Defaults",
            "FileEncoding",
            "FilePermissions",
            "TextEditing",
            "UnicodeNormalization",
            "Shortcut",
        ]),
        
        .library(name: "CharacterInfo", targets: ["CharacterInfo"]),
        .library(name: "Defaults", targets: ["Defaults"]),
        .library(name: "FileEncoding", targets: ["FileEncoding"]),
        .library(name: "FilePermissions", targets: ["FilePermissions"]),
        .library(name: "TextEditing", targets: ["TextEditing"]),
        .library(name: "UnicodeNormalization", targets: ["UnicodeNormalization"]),
        
        .library(name: "Shortcut", targets: ["Shortcut"]),
    ],
    targets: [
        .target(name: "CharacterInfo", resources: [.process("Resources")]),
        .testTarget(name: "CharacterInfoTests", dependencies: ["CharacterInfo"]),
        
        .target(name: "Defaults"),
        .testTarget(name: "DefaultsTests", dependencies: ["Defaults"]),
        
        .target(name: "FileEncoding", resources: [.process("Resources")]),
        .testTarget(name: "FileEncodingTests", dependencies: ["FileEncoding"], resources: [.process("Resources")]),
        
        .target(name: "FilePermissions"),
        .testTarget(name: "FilePermissionsTests", dependencies: ["FilePermissions"]),
        
        .target(name: "TextEditing"),
        .testTarget(name: "TextEditingTests", dependencies: ["TextEditing"]),
        
        .target(name: "UnicodeNormalization"),
        .testTarget(name: "UnicodeNormalizationTests", dependencies: ["UnicodeNormalization"]),
        
        .target(name: "Shortcut", resources: [.process("Resources")]),
        .testTarget(name: "ShortcutTests", dependencies: ["Shortcut"]),
    ],
    swiftLanguageVersions: [.v6]
)
