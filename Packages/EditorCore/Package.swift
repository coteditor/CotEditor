// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "EditorCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(name: "EditorCore", targets: [
            "CharacterInfo",
            "Defaults",
            "DocumentFile",
            "FileEncoding",
            "FolderFind",
            "Invisible",
            "LineEnding",
            "LineSort",
            "SemanticVersioning",
            "StringUtils",
            "TextClipping",
            "TextEditing",
            "TextFind",
            "URLUtils",
            "ValueRange",
        ]),
    ],
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: Version(0, 62, 0)),
    ],
    targets: [
        .target(name: "CharacterInfo"),
        .testTarget(name: "CharacterInfoTests", dependencies: ["CharacterInfo"]),
        
        .target(name: "Defaults"),
        .testTarget(name: "DefaultsTests", dependencies: ["Defaults"]),
        
        .target(name: "DocumentFile", dependencies: ["FileEncoding", "URLUtils"]),
        .testTarget(name: "DocumentFileTests", dependencies: ["DocumentFile"]),
        
        .target(name: "FileEncoding", dependencies: ["ValueRange"]),
        .testTarget(name: "FileEncodingTests", dependencies: ["FileEncoding"], resources: [.process("Resources")]),
        
        .target(name: "FolderFind", dependencies: ["DocumentFile", "FileEncoding", "LineEnding", "StringUtils", "TextFind"]),
        .testTarget(name: "FolderFindTests", dependencies: ["FolderFind"]),
        
        .target(name: "Invisible"),
        
        .target(name: "LineEnding", dependencies: ["StringUtils", "ValueRange"]),
        .testTarget(name: "LineEndingTests", dependencies: ["LineEnding", "StringUtils"]),
        
        .target(name: "LineSort", dependencies: ["StringUtils"]),
        .testTarget(name: "LineSortTests", dependencies: ["LineSort"]),
        
        .target(name: "SemanticVersioning"),
        .testTarget(name: "SemanticVersioningTests", dependencies: ["SemanticVersioning"]),
        
        .target(name: "StringUtils"),
        .testTarget(name: "StringUtilsTests", dependencies: ["StringUtils"]),
        
        .target(name: "TextClipping"),
        .testTarget(name: "TextClippingTests", dependencies: ["TextClipping"], resources: [.process("Resources")]),
        
        .target(name: "TextEditing", dependencies: ["StringUtils"]),
        .testTarget(name: "TextEditingTests", dependencies: ["TextEditing"]),
        
        .target(name: "TextFind", dependencies: ["StringUtils", "ValueRange"]),
        .testTarget(name: "TextFindTests", dependencies: ["TextFind"]),
        
        .target(name: "URLUtils"),
        .testTarget(name: "URLUtilsTests", dependencies: ["URLUtils"]),
        
        .target(name: "ValueRange"),
        .testTarget(name: "ValueRangeTests", dependencies: ["ValueRange"]),
    ],
    swiftLanguageModes: [.v6]
)


for target in package.targets {
    target.plugins = (target.plugins ?? []) + [
        .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
