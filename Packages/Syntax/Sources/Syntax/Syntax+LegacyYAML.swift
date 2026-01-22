//
//  Syntax+LegacyYAML.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2026 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

public import Foundation
import UniformTypeIdentifiers
import Yams
import StringUtils

public extension Syntax {
    
    /// Migrates all legacy YAML-based syntax definitions in the given directory to the `.cotSyntax` package format.
    ///
    /// - Parameters:
    ///   - directoryURL: The directory to scan for legacy YAML syntax definition files.
    ///   - deletingOriginal: Whether to remove each original YAML file after its successful migration.
    /// - Throws: An error if reading the directory contents fails or if any individual file migration throws.
    static func migrateFormat(in directoryURL: URL, deletingOriginal: Bool = true) throws {
        
        try FileManager.default.contentsOfDirectory(at: directoryURL,
                                                    includingPropertiesForKeys: [.contentTypeKey],
                                                    options: .skipsSubdirectoryDescendants)
        .filter { try $0.resourceValues(forKeys: [.contentTypeKey]).contentType == .yaml }
        .forEach { url in
            try self.migrate(fileURL: url, deletingOriginal: deletingOriginal)
        }
    }
    
    
    /// Migrates a legacy YAML-based syntax definition to the new `.cotSyntax` package format.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL of the legacy YAML syntax definition to migrate.
    ///   - deletingOriginal: Whether to remove the original YAML file after a successful migration.
    /// - Throws: An error if reading, decoding, writing the converted syntax, or deleting the original file fails.
    static func migrate(fileURL: URL, deletingOriginal: Bool = true) throws {
        
        guard try fileURL.checkResourceIsReachable() else { return }
        
        let newURL = fileURL.deletingPathExtension().appendingPathExtension("cotsyntax")
        
        guard (try? newURL.checkResourceIsReachable()) != true else { return }
        
        let yamlData = try Data(contentsOf: fileURL)
        let decoder = YAMLDecoder()
        let syntax = try decoder.decode(Syntax.self, from: yamlData)
        let fileWrapper = try syntax.fileWrapper
        
        try fileWrapper.write(to: newURL, options: .withNameUpdating, originalContentsURL: nil)
        
        if deletingOriginal {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    
    /// Initializes with legacy YAML format, used before CotEditor 7.0 (2026).
    ///
    /// - Parameters:
    ///   - yamlData: YAML data.
    init(yamlData: Data) throws {
        
        self = try YAMLDecoder().decode(Syntax.self, from: yamlData)
    }
}


extension Syntax: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case kind
        
        case keywords
        case commands
        case types
        case attributes
        case variables
        case values
        case numbers
        case strings
        case characters
        case comments
        
        case outlines = "outlineMenu"
        case commentDelimiters
        case completions
        
        case filenames
        case extensions
        case interpreters
        
        case metadata
    }
    
    
    private struct KeyString: Codable {
        
        var keyString: String?
    }
    
    
    public init(from decoder: any Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.kind = try values.decodeIfPresent(Kind.self, forKey: .kind) ?? .general
        
        var highlights: [SyntaxType: [Highlight]] = [:]
        highlights[.keywords] = try values.decodeIfPresent([Highlight].self, forKey: .keywords) ?? []
        highlights[.commands] = try values.decodeIfPresent([Highlight].self, forKey: .commands) ?? []
        highlights[.types] = try values.decodeIfPresent([Highlight].self, forKey: .types) ?? []
        highlights[.attributes] = try values.decodeIfPresent([Highlight].self, forKey: .attributes) ?? []
        highlights[.variables] = try values.decodeIfPresent([Highlight].self, forKey: .variables) ?? []
        highlights[.values] = try values.decodeIfPresent([Highlight].self, forKey: .values) ?? []
        highlights[.numbers] = try values.decodeIfPresent([Highlight].self, forKey: .numbers) ?? []
        highlights[.strings] = try values.decodeIfPresent([Highlight].self, forKey: .strings) ?? []
        highlights[.characters] = try values.decodeIfPresent([Highlight].self, forKey: .characters) ?? []
        highlights[.comments] = try values.decodeIfPresent([Highlight].self, forKey: .comments) ?? []
        self.highlights = highlights
        
        self.outlines = try values.decodeIfPresent([Outline].self, forKey: .outlines) ?? []
        self.commentDelimiters = (try values.decodeIfPresent([String: String].self, forKey: .commentDelimiters))
            .flatMap(Comment.init(legacyDictionary:)) ?? .init()
        self.completions = try values.decodeIfPresent([KeyString].self, forKey: .completions)?.compactMap(\.keyString) ?? []
        
        var fileMap = FileMap()
        fileMap.extensions = try values.decodeIfPresent([KeyString].self, forKey: .extensions)?.compactMap(\.keyString) ?? []
        fileMap.filenames = try values.decodeIfPresent([KeyString].self, forKey: .filenames)?.compactMap(\.keyString) ?? []
        fileMap.interpreters = try values.decodeIfPresent([KeyString].self, forKey: .interpreters)?.compactMap(\.keyString) ?? []
        self.fileMap = fileMap
        
        self.metadata = try values.decodeIfPresent(Metadata.self, forKey: .metadata) ?? .init()
    }
    
    
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.kind, forKey: .kind)
        
        try container.encode(self.highlights[.keywords], forKey: .keywords)
        try container.encode(self.highlights[.commands], forKey: .commands)
        try container.encode(self.highlights[.types], forKey: .types)
        try container.encode(self.highlights[.attributes], forKey: .attributes)
        try container.encode(self.highlights[.variables], forKey: .variables)
        try container.encode(self.highlights[.values], forKey: .values)
        try container.encode(self.highlights[.numbers], forKey: .numbers)
        try container.encode(self.highlights[.strings], forKey: .strings)
        try container.encode(self.highlights[.characters], forKey: .characters)
        try container.encode(self.highlights[.comments], forKey: .comments)
        
        try container.encode(self.outlines, forKey: .outlines)
        try container.encode(self.commentDelimiters.legacyDictionary, forKey: .commentDelimiters)
        try container.encode(self.completions.map(KeyString.init(keyString:)), forKey: .completions)
        
        try container.encode(self.fileMap.extensions?.map(KeyString.init(keyString:)), forKey: .extensions)
        try container.encode(self.fileMap.filenames?.map(KeyString.init(keyString:)), forKey: .filenames)
        try container.encode(self.fileMap.interpreters?.map(KeyString.init(keyString:)), forKey: .interpreters)
        
        try container.encode(self.metadata, forKey: .metadata)
    }
}


private extension Syntax.Comment {
    
    private enum LegacyKey {
        
        static let inline = "inlineDelimiter"
        static let blockBegin = "beginDelimiter"
        static let blockEnd = "endDelimiter"
    }
    
    
    var legacyDictionary: [String: String] {
        
        var dict: [String: String] = [:]
        dict[LegacyKey.inline] = self.inlines.first?.begin
        dict[LegacyKey.blockBegin] = self.blocks.first?.begin
        dict[LegacyKey.blockEnd] = self.blocks.first?.end
        
        return dict
    }
    
    init(legacyDictionary dictionary: [String: String]) {
        
        if let inline = dictionary[LegacyKey.inline] {
            self.inlines = [.init(begin: inline)]
        }
        if let blockBegin = dictionary[LegacyKey.blockBegin],
           let blockEnd = dictionary[LegacyKey.blockEnd]
        {
            self.blocks = [.init(blockBegin, blockEnd)]
        }
    }
}
