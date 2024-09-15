// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EditorCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "EditorCore", targets: [
            "CharacterInfo",
            "Defaults",
            "EditedRangeSet",
            "FileEncoding",
            "FilePermissions",
            "URLUtils",
            "FuzzyRange",
            "Invisible",
            "LineEnding",
            "LineSort",
            "StringUtils",
            "Syntax",
            "TextClipping",
            "TextEditing",
            "TextFind",
            "UnicodeNormalization",
            "ValueRange",
        ]),
        
        .library(name: "CharacterInfo", targets: ["CharacterInfo"]),
        .library(name: "Defaults", targets: ["Defaults"]),
        .library(name: "EditedRangeSet", targets: ["EditedRangeSet"]),
        .library(name: "FileEncoding", targets: ["FileEncoding"]),
        .library(name: "FilePermissions", targets: ["FilePermissions"]),
        .library(name: "URLUtils", targets: ["URLUtils"]),
        .library(name: "FuzzyRange", targets: ["FuzzyRange"]),
        .library(name: "Invisible", targets: ["Invisible"]),
        .library(name: "LineEnding", targets: ["LineEnding"]),
        .library(name: "LineSort", targets: ["LineSort"]),
        .library(name: "StringUtils", targets: ["StringUtils"]),
        .library(name: "Syntax", targets: ["Syntax"]),
        .library(name: "TextClipping", targets: ["TextClipping"]),
        .library(name: "TextEditing", targets: ["TextEditing"]),
        .library(name: "TextFind", targets: ["TextFind"]),
        .library(name: "UnicodeNormalization", targets: ["UnicodeNormalization"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: Version(0, 57, 0)),
    ],
    targets: [
        .target(name: "CharacterInfo", resources: [.process("Resources")]),
        .testTarget(name: "CharacterInfoTests", dependencies: ["CharacterInfo"]),
        
        .target(name: "Defaults"),
        .testTarget(name: "DefaultsTests", dependencies: ["Defaults"]),
        
        .target(name: "EditedRangeSet", dependencies: ["StringUtils"]),
        .testTarget(name: "EditedRangeSetTests", dependencies: ["EditedRangeSet"]),
        
        .target(name: "FileEncoding", dependencies: ["ValueRange"], resources: [.process("Resources")]),
        .testTarget(name: "FileEncodingTests", dependencies: ["FileEncoding"], resources: [.process("Resources")]),
        
        .target(name: "FilePermissions"),
        .testTarget(name: "FilePermissionsTests", dependencies: ["FilePermissions"]),
        
        .target(name: "URLUtils"),
        .testTarget(name: "URLUtilsTests", dependencies: ["URLUtils"]),
        
        .target(name: "FuzzyRange"),
        .testTarget(name: "FuzzyRangeTests", dependencies: ["FuzzyRange"]),
        
        .target(name: "Invisible"),
        
        .target(name: "LineEnding", dependencies: ["ValueRange"]),
        .testTarget(name: "LineEndingTests", dependencies: ["LineEnding", "StringUtils"]),
        
        .target(name: "LineSort", dependencies: ["StringUtils"]),
        .testTarget(name: "LineSortTests", dependencies: ["LineSort"]),
        
        .target(name: "StringUtils"),
        .testTarget(name: "StringUtilsTests", dependencies: ["StringUtils"]),
        
        .target(name: "Syntax", dependencies: ["StringUtils", "ValueRange"]),
        .testTarget(name: "SyntaxTests", dependencies: ["Syntax"]),
        
        .target(name: "TextClipping"),
        .testTarget(name: "TextClippingTests", dependencies: ["TextClipping"], resources: [.process("Resources")]),
        
        .target(name: "TextEditing", dependencies: ["StringUtils", "Syntax"]),
        .testTarget(name: "TextEditingTests", dependencies: ["TextEditing"]),
        
        .target(name: "TextFind", dependencies: ["StringUtils", "ValueRange"]),
        .testTarget(name: "TextFindTests", dependencies: ["TextFind"]),
        
        .target(name: "UnicodeNormalization"),
        .testTarget(name: "UnicodeNormalizationTests", dependencies: ["UnicodeNormalization"]),
        
        .target(name: "ValueRange"),
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
