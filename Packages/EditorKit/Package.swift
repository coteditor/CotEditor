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
            "FuzzyRange",
            "LineSort",
            "Shortcut",
            "StringBasics",
            "Syntax",
            "TextClipping",
            "TextEditing",
            "UnicodeNormalization",
            "ValueRange",
            "Shortcut",
        ]),
        
        .library(name: "CharacterInfo", targets: ["CharacterInfo"]),
        .library(name: "Defaults", targets: ["Defaults"]),
        .library(name: "FileEncoding", targets: ["FileEncoding"]),
        .library(name: "FilePermissions", targets: ["FilePermissions"]),
        .library(name: "FuzzyRange", targets: ["FuzzyRange"]),
        .library(name: "LineSort", targets: ["LineSort"]),
        .library(name: "StringBasics", targets: ["StringBasics"]),
        .library(name: "Syntax", targets: ["Syntax"]),
        .library(name: "TextClipping", targets: ["TextClipping"]),
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
        
        .target(name: "FuzzyRange"),
        .testTarget(name: "FuzzyRangeTests", dependencies: ["FuzzyRange"]),
        
        .target(name: "LineSort", dependencies: ["StringBasics"]),
        .testTarget(name: "LineSortTests", dependencies: ["LineSort"]),
        
        .target(name: "StringBasics"),
        .testTarget(name: "StringBasicsTests", dependencies: ["StringBasics"]),
        
        .target(name: "Syntax", dependencies: ["StringBasics", "ValueRange"]),
        .testTarget(name: "SyntaxTests", dependencies: ["Syntax"]),
        
        .target(name: "TextClipping"),
        .testTarget(name: "TextClippingTests", dependencies: ["TextClipping"], resources: [.process("Resources")]),
        
        .target(name: "TextEditing", dependencies: ["StringBasics", "Syntax"]),
        .testTarget(name: "TextEditingTests", dependencies: ["TextEditing"]),
        
        .target(name: "UnicodeNormalization"),
        .testTarget(name: "UnicodeNormalizationTests", dependencies: ["UnicodeNormalization"]),
        
        .target(name: "ValueRange"),
        
        .target(name: "Shortcut", resources: [.process("Resources")]),
        .testTarget(name: "ShortcutTests", dependencies: ["Shortcut"]),
    ],
    swiftLanguageVersions: [.v6]
)
