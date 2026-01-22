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
        let fileWrapper = try syntax.fileWrapper
        
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
}


private extension Syntax.Comment {
    
    init(legacyDictionary dictionary: [String: String]) {
        
        if let inline = dictionary["inlineDelimiter"] {
            self.inlines = [.init(begin: inline)]
        }
        if let blockBegin = dictionary["beginDelimiter"],
           let blockEnd = dictionary["endDelimiter"]
        {
            self.blocks = [.init(blockBegin, blockEnd)]
        }
    }
}
