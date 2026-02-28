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
    
    /// Migrates all legacy YAML-based syntax definitions within a directory to the `.cotSyntax` package format.
    ///
    /// - Parameters:
    ///   - directoryURL: The directory to scan (non-recursively) for legacy YAML syntax definition files.
    ///   - destinationURL: Optional destination directory where converted `.cotsyntax` packages will be written.
    ///   - deletingOriginal: If `true`, remove each original YAML file after its successful migration.
    /// - Throws: An error if reading the directory contents fails.
    static func migrateFormat(in directoryURL: URL, to destinationURL: URL? = nil, deletingOriginal: Bool = true) throws {
        
        let urls = try FileManager.default.contentsOfDirectory(at: directoryURL,
                                                               includingPropertiesForKeys: [.contentTypeKey],
                                                               options: .skipsSubdirectoryDescendants)
            .filter { try $0.resourceValues(forKeys: [.contentTypeKey]).contentType == .yaml }
        
        for url in urls {
            do {
                try self.migrate(fileURL: url, to: destinationURL, deletingOriginal: deletingOriginal)
            } catch {
                continue
            }
        }
    }
    
    
    /// Migrates a legacy YAML-based syntax definition to the new `.cotSyntax` package format.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL of the legacy YAML syntax definition to migrate.
    ///   - directoryURL: Optional destination directory to write the converted `.cotsyntax` package.
    ///   - deletingOriginal: If `true`, delete the original YAML file after a successful migration.
    /// - Throws: An error if reading, decoding, writing the converted syntax, or deleting the original file fails.
    static func migrate(fileURL: URL, to directoryURL: URL? = nil, deletingOriginal: Bool = true) throws {
        
        guard try fileURL.checkResourceIsReachable() else { return }
        
        let newURL = (directoryURL?.appendingPathComponent(fileURL.lastPathComponent) ?? fileURL)
            .deletingPathExtension().appendingPathExtension("cotsyntax")
        
        guard (try? newURL.checkResourceIsReachable()) != true else { return }
        
        let yamlData = try Data(contentsOf: fileURL)
        let decoder = YAMLDecoder()
        let syntax = try decoder.decode(Syntax.self, from: yamlData)
        let fileWrapper = try syntax.sanitized.fileWrapper
        
        if let directoryURL, (try? directoryURL.checkResourceIsReachable()) != true {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        try fileWrapper.write(to: newURL, options: .atomic, originalContentsURL: nil)
        
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


extension Syntax: Decodable {
    
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
    
    
    private struct LegacyHighlight: Decodable {
        
        private enum CodingKeys: String, CodingKey {
            
            case begin = "beginString"
            case end = "endString"
            case isRegularExpression = "regularExpression"
            case ignoreCase
            case isMultiline
            case description
        }
        
        
        var highlight: Highlight
        
        
        init(from decoder: any Decoder) throws {
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.highlight = Highlight(
                begin: try container.decodeIfPresent(String.self, forKey: .begin) ?? "",
                end: try container.decodeIfPresent(String.self, forKey: .end),
                isRegularExpression: try container.decodeIfPresent(Bool.self, forKey: .isRegularExpression) ?? false,
                ignoreCase: try container.decodeIfPresent(Bool.self, forKey: .ignoreCase) ?? false,
                isMultiline: try container.decodeIfPresent(Bool.self, forKey: .isMultiline) ?? false,
                description: try container.decodeIfPresent(String.self, forKey: .description)
            )
        }
    }
    
    
    private struct LegacyOutline: Decodable {
        
        private enum CodingKeys: String, CodingKey {
            
            case pattern = "beginString"
            case template = "keyString"
            case ignoreCase
            case kind
            case description
        }
        
        
        var outline: Outline
        
        
        init(from decoder: any Decoder) throws {
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.outline = Outline(
                pattern: try container.decodeIfPresent(String.self, forKey: .pattern) ?? "",
                template: try container.decodeIfPresent(String.self, forKey: .template) ?? "",
                ignoreCase: try container.decodeIfPresent(Bool.self, forKey: .ignoreCase) ?? false,
                kind: try container.decodeIfPresent(Outline.Kind.self, forKey: .kind),
                description: try container.decodeIfPresent(String.self, forKey: .description)
            )
        }
    }
    
    
    public init(from decoder: any Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.kind = try values.decodeIfPresent(Kind.self, forKey: .kind) ?? .general
        
        var fileMap = FileMap()
        fileMap.extensions = try values.decodeIfPresent([KeyString].self, forKey: .extensions)?.compactMap(\.keyString) ?? []
        fileMap.filenames = try values.decodeIfPresent([KeyString].self, forKey: .filenames)?.compactMap(\.keyString) ?? []
        fileMap.interpreters = try values.decodeIfPresent([KeyString].self, forKey: .interpreters)?.compactMap(\.keyString) ?? []
        self.fileMap = fileMap
        
        var highlights: [SyntaxType: [Highlight]] = [:]
        highlights[.keywords] = try values.decodeIfPresent([LegacyHighlight].self, forKey: .keywords)?.map(\.highlight) ?? []
        highlights[.commands] = try values.decodeIfPresent([LegacyHighlight].self, forKey: .commands)?.map(\.highlight) ?? []
        highlights[.types] = try values.decodeIfPresent([LegacyHighlight].self, forKey: .types)?.map(\.highlight) ?? []
        highlights[.attributes] = try values.decodeIfPresent([LegacyHighlight].self, forKey: .attributes)?.map(\.highlight) ?? []
        highlights[.variables] = try values.decodeIfPresent([LegacyHighlight].self, forKey: .variables)?.map(\.highlight) ?? []
        highlights[.values] = try values.decodeIfPresent([LegacyHighlight].self, forKey: .values)?.map(\.highlight) ?? []
        highlights[.numbers] = try values.decodeIfPresent([LegacyHighlight].self, forKey: .numbers)?.map(\.highlight) ?? []
        highlights[.strings] = try values.decodeIfPresent([LegacyHighlight].self, forKey: .strings)?.map(\.highlight) ?? []
        highlights[.characters] = try values.decodeIfPresent([LegacyHighlight].self, forKey: .characters)?.map(\.highlight) ?? []
        highlights[.comments] = try values.decodeIfPresent([LegacyHighlight].self, forKey: .comments)?.map(\.highlight) ?? []
        self.highlights = highlights
        
        self.outlines = (try values.decodeIfPresent([LegacyOutline].self, forKey: .outlines)?.map(\.outline) ?? [])
            .map { outline in  // migrate separator
                if outline.template == "–" {
                    var outline = outline
                    outline.template = ""
                    outline.kind = .separator
                    return outline
                }
               return outline
            }
        
        self.commentDelimiters = (try values.decodeIfPresent([String: String].self, forKey: .commentDelimiters))
            .flatMap(Comment.init(legacyDictionary:)) ?? .init()
        self.indentation = Indentation()
        self.lexicalRules = .default
        self.completions = try values.decodeIfPresent([KeyString].self, forKey: .completions)?
            .compactMap(\.keyString)
            .compactMap { CompletionWord(text: $0) } ?? []
        
        self.metadata = try values.decodeIfPresent(Metadata.self, forKey: .metadata) ?? .init()
    }
}


private extension Syntax.Comment {
    
    init(legacyDictionary dictionary: [String: String]) {
        
        if let inline = dictionary["inlineDelimiter"] {
            self.inlines = [.init(begin: inline)]
        }
        if let blockBegin = dictionary["beginDelimiter"],
           let blockEnd = dictionary["endDelimiter"]
        {
            self.blocks = [.init(begin: blockBegin, end: blockEnd)]
        }
    }
}


private extension String {
    
    /// Constant string representing a separator.
    static let separator = "-"
}
