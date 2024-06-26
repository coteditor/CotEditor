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
//  © 2023-2024 1024jp
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
        
        case commentDelimiters
        case outlines = "outlineMenu"
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
        self.keywords = try values.decodeIfPresent([Highlight].self, forKey: .keywords) ?? []
        self.commands = try values.decodeIfPresent([Highlight].self, forKey: .commands) ?? []
        self.types = try values.decodeIfPresent([Highlight].self, forKey: .types) ?? []
        self.attributes = try values.decodeIfPresent([Highlight].self, forKey: .attributes) ?? []
        self.variables = try values.decodeIfPresent([Highlight].self, forKey: .variables) ?? []
        self.values = try values.decodeIfPresent([Highlight].self, forKey: .values) ?? []
        self.numbers = try values.decodeIfPresent([Highlight].self, forKey: .numbers) ?? []
        self.strings = try values.decodeIfPresent([Highlight].self, forKey: .strings) ?? []
        self.characters = try values.decodeIfPresent([Highlight].self, forKey: .characters) ?? []
        self.comments = try values.decodeIfPresent([Highlight].self, forKey: .comments) ?? []
        
        self.commentDelimiters = try values.decodeIfPresent(Comment.self, forKey: .commentDelimiters) ?? .init()
        self.outlines = try values.decodeIfPresent([Outline].self, forKey: .outlines) ?? []
        self.completions = try values.decodeIfPresent([KeyString].self, forKey: .completions)?.compactMap(\.keyString) ?? []
        
        self.filenames = try values.decodeIfPresent([KeyString].self, forKey: .filenames)?.compactMap(\.keyString) ?? []
        self.extensions = try values.decodeIfPresent([KeyString].self, forKey: .extensions)?.compactMap(\.keyString) ?? []
        self.interpreters = try values.decodeIfPresent([KeyString].self, forKey: .interpreters)?.compactMap(\.keyString) ?? []
        
        self.metadata = try values.decodeIfPresent(Metadata.self, forKey: .metadata) ?? .init()
    }
    
    
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.kind, forKey: .kind)
        
        try container.encode(self.keywords, forKey: .keywords)
        try container.encode(self.commands, forKey: .commands)
        try container.encode(self.types, forKey: .types)
        try container.encode(self.attributes, forKey: .attributes)
        try container.encode(self.variables, forKey: .variables)
        try container.encode(self.values, forKey: .values)
        try container.encode(self.numbers, forKey: .numbers)
        try container.encode(self.strings, forKey: .strings)
        try container.encode(self.characters, forKey: .characters)
        try container.encode(self.comments, forKey: .comments)
        
        try container.encode(self.commentDelimiters, forKey: .commentDelimiters)
        try container.encode(self.outlines, forKey: .outlines)
        try container.encode(self.completions.map(KeyString.init(keyString:)), forKey: .completions)
        
        try container.encode(self.filenames.map(KeyString.init(keyString:)), forKey: .filenames)
        try container.encode(self.extensions.map(KeyString.init(keyString:)), forKey: .extensions)
        try container.encode(self.interpreters.map(KeyString.init(keyString:)), forKey: .interpreters)
        
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
