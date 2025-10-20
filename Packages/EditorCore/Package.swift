// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "EditorCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "EditorCore", targets: [
            "CharacterInfo",
            "Defaults",
            "FileEncoding",
            "FilePermissions",
            "URLUtils",
            "Invisible",
            "LineEnding",
            "LineSort",
            "SemanticVersioning",
            "StringUtils",
            "Syntax",
            "TextClipping",
            "TextEditing",
            "TextFind",
            "ValueRange",
        ]),
        
        .library(name: "CharacterInfo", targets: ["CharacterInfo"]),
        .library(name: "Defaults", targets: ["Defaults"]),
        .library(name: "FileEncoding", targets: ["FileEncoding"]),
        .library(name: "FilePermissions", targets: ["FilePermissions"]),
        .library(name: "URLUtils", targets: ["URLUtils"]),
        .library(name: "Invisible", targets: ["Invisible"]),
        .library(name: "LineEnding", targets: ["LineEnding"]),
        .library(name: "LineSort", targets: ["LineSort"]),
        .library(name: "SemanticVersioning", targets: ["SemanticVersioning"]),
        .library(name: "StringUtils", targets: ["StringUtils"]),
        .library(name: "Syntax", targets: ["Syntax"]),
        .library(name: "TextClipping", targets: ["TextClipping"]),
        .library(name: "TextEditing", targets: ["TextEditing"]),
        .library(name: "TextFind", targets: ["TextFind"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: Version(0, 59, 0)),
    ],
    targets: [
        .target(name: "CharacterInfo", resources: [.process("Resources")]),
        .testTarget(name: "CharacterInfoTests", dependencies: ["CharacterInfo"]),
        
        .target(name: "Defaults"),
        .testTarget(name: "DefaultsTests", dependencies: ["Defaults"]),
        
        .target(name: "FileEncoding", dependencies: ["ValueRange"], resources: [.process("Resources")]),
        .testTarget(name: "FileEncodingTests", dependencies: ["FileEncoding"], resources: [.process("Resources")]),
        
        .target(name: "FilePermissions"),
        .testTarget(name: "FilePermissionsTests", dependencies: ["FilePermissions"]),
        
        .target(name: "URLUtils"),
        .testTarget(name: "URLUtilsTests", dependencies: ["URLUtils"]),
        
        .target(name: "Invisible"),
        
        .target(name: "LineEnding", dependencies: ["ValueRange"], resources: [.process("Resources")]),
        .testTarget(name: "LineEndingTests", dependencies: ["LineEnding", "StringUtils"]),
        
        .target(name: "LineSort", dependencies: ["StringUtils"]),
        .testTarget(name: "LineSortTests", dependencies: ["LineSort"]),
        
        .target(name: "SemanticVersioning"),
        .testTarget(name: "SemanticVersioningTests", dependencies: ["SemanticVersioning"]),
        
        .target(name: "StringUtils", resources: [.process("Resources")]),
        .testTarget(name: "StringUtilsTests", dependencies: ["StringUtils"]),
        
        .target(name: "Syntax", dependencies: ["StringUtils", "ValueRange"], resources: [.process("Resources")]),
        .testTarget(name: "SyntaxTests", dependencies: ["Syntax"]),
        
        .target(name: "TextClipping"),
        .testTarget(name: "TextClippingTests", dependencies: ["TextClipping"], resources: [.process("Resources")]),
        
        .target(name: "TextEditing", dependencies: ["StringUtils", "Syntax"]),
        .testTarget(name: "TextEditingTests", dependencies: ["TextEditing"]),
        
        .target(name: "TextFind", dependencies: ["StringUtils", "ValueRange"]),
        .testTarget(name: "TextFindTests", dependencies: ["TextFind"]),
        
        .target(name: "ValueRange"),
    ],
    swiftLanguageModes: [.v6]
)


for target in package.targets {
    target.plugins = [
        .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
    ]
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
