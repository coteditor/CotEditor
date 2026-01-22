//
//  Syntax+Codable.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-06.
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

import Foundation
import StringUtils

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
        
        self.commentDelimiters = (try values.decodeIfPresent([String: String].self, forKey: .commentDelimiters))
            .flatMap(Comment.init(legacyDictionary:)) ?? .init()
        
        self.outlines = try values.decodeIfPresent([Outline].self, forKey: .outlines) ?? []
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
        
        try container.encode(self.commentDelimiters.legacyDictionary, forKey: .commentDelimiters)
        
        try container.encode(self.outlines, forKey: .outlines)
        try container.encode(self.completions.map(KeyString.init(keyString:)), forKey: .completions)
        
        try container.encode(self.fileMap.extensions?.map(KeyString.init(keyString:)), forKey: .extensions)
        try container.encode(self.fileMap.filenames?.map(KeyString.init(keyString:)), forKey: .filenames)
        try container.encode(self.fileMap.interpreters?.map(KeyString.init(keyString:)), forKey: .interpreters)
        
        try container.encode(self.metadata, forKey: .metadata)
    }
}


extension Syntax.Highlight: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case begin = "beginString"
        case end = "endString"
        case isRegularExpression = "regularExpression"
        case ignoreCase
        case description
    }
    
    
    public init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.begin = try container.decodeIfPresent(String.self, forKey: .begin) ?? ""
        self.end = try container.decodeIfPresent(String.self, forKey: .end)
        self.isRegularExpression = try container.decodeIfPresent(Bool.self, forKey: .isRegularExpression) ?? false
        self.ignoreCase = try container.decodeIfPresent(Bool.self, forKey: .ignoreCase) ?? false
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.begin, forKey: .begin)
        if self.end?.isEmpty == false {
            try container.encode(self.end, forKey: .end)
        }
        if self.isRegularExpression {
            try container.encode(true, forKey: .isRegularExpression)
        }
        if self.ignoreCase {
            try container.encode(true, forKey: .ignoreCase)
        }
        if let description = self.description {
            try container.encode(description, forKey: .description)
        }
    }
}


extension Syntax.Outline: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case pattern = "beginString"
        case template = "keyString"
        case ignoreCase
        case bold
        case italic
        case underline
        case description
    }
    
    
    public init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.pattern = try container.decodeIfPresent(String.self, forKey: .pattern) ?? ""
        self.template = try container.decodeIfPresent(String.self, forKey: .template) ?? ""
        self.ignoreCase = try container.decodeIfPresent(Bool.self, forKey: .ignoreCase) ?? false
        self.bold = try container.decodeIfPresent(Bool.self, forKey: .bold) ?? false
        self.italic = try container.decodeIfPresent(Bool.self, forKey: .italic) ?? false
        self.underline = try container.decodeIfPresent(Bool.self, forKey: .underline) ?? false
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.pattern, forKey: .pattern)
        try container.encode(self.template, forKey: .template)
        if self.ignoreCase {
            try container.encode(true, forKey: .ignoreCase)
        }
        if self.bold {
            try container.encode(true, forKey: .bold)
        }
        if self.italic {
            try container.encode(true, forKey: .italic)
        }
        if self.underline {
            try container.encode(true, forKey: .underline)
        }
        if let description = self.description {
            try container.encode(description, forKey: .description)
        }
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


extension Syntax.Comment.Inline: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case begin
        case leadingOnly
    }
    
    
    public init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.begin = try container.decode(String.self, forKey: .begin)
        self.leadingOnly = try container.decodeIfPresent(Bool.self, forKey: .leadingOnly) ?? true
    }
    
    
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.begin, forKey: .begin)
        
        if self.leadingOnly {
            try container.encode(true, forKey: .leadingOnly)
        }
    }
}
