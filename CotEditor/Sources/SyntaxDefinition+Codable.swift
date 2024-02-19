//
//  SyntaxDefinition+Codable.swift
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

extension SyntaxDefinition: Codable {
    
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
        case outlines
        case completions
        
        case filenames
        case extensions
        case interpreters
        
        case metadata
    }
    
    
    convenience init(from decoder: any Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.init()
        
        self.kind = try values.decodeIfPresent(Syntax.Kind.self, forKey: .kind) ?? .general
        self.keywords = try values.decodeIfPresent([Term].self, forKey: .keywords) ?? []
        self.commands = try values.decodeIfPresent([Term].self, forKey: .commands) ?? []
        self.types = try values.decodeIfPresent([Term].self, forKey: .types) ?? []
        self.attributes = try values.decodeIfPresent([Term].self, forKey: .attributes) ?? []
        self.variables = try values.decodeIfPresent([Term].self, forKey: .variables) ?? []
        self.values = try values.decodeIfPresent([Term].self, forKey: .values) ?? []
        self.numbers = try values.decodeIfPresent([Term].self, forKey: .numbers) ?? []
        self.strings = try values.decodeIfPresent([Term].self, forKey: .strings) ?? []
        self.characters = try values.decodeIfPresent([Term].self, forKey: .characters) ?? []
        self.comments = try values.decodeIfPresent([Term].self, forKey: .comments) ?? []
        
        self.commentDelimiters = try values.decodeIfPresent(SyntaxDefinition.Comment.self, forKey: .commentDelimiters) ?? .init()
        self.outlines = try values.decodeIfPresent([Outline].self, forKey: .outlines) ?? []
        self.completions = try values.decodeIfPresent([IdentifiedString].self, forKey: .completions) ?? []
        
        self.filenames = try values.decodeIfPresent([IdentifiedString].self, forKey: .filenames) ?? []
        self.extensions = try values.decodeIfPresent([IdentifiedString].self, forKey: .extensions) ?? []
        self.interpreters = try values.decodeIfPresent([IdentifiedString].self, forKey: .interpreters) ?? []
        
        self.metadata = try values.decodeIfPresent(SyntaxDefinition.Metadata.self, forKey: .metadata) ?? .init()
    }
    
    
    func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.keywords.sorted(\.begin, options: .localized), forKey: .keywords)
        try container.encode(self.commands.sorted(\.begin, options: .localized), forKey: .commands)
        try container.encode(self.types.sorted(\.begin, options: .localized), forKey: .types)
        try container.encode(self.attributes.sorted(\.begin, options: .localized), forKey: .attributes)
        try container.encode(self.variables.sorted(\.begin, options: .localized), forKey: .variables)
        try container.encode(self.values.sorted(\.begin, options: .localized), forKey: .values)
        try container.encode(self.numbers.sorted(\.begin, options: .localized), forKey: .numbers)
        try container.encode(self.strings.sorted(\.begin, options: .localized), forKey: .strings)
        try container.encode(self.characters.sorted(\.begin, options: .localized), forKey: .characters)
        try container.encode(self.comments.sorted(\.begin, options: .localized), forKey: .comments)
        
        try container.encode(self.commentDelimiters, forKey: .commentDelimiters)
        try container.encode(self.outlines.sorted(\.pattern, options: .localized), forKey: .outlines)
        try container.encode(self.completions.sorted(\.value, options: .localized), forKey: .completions)
        
        try container.encode(self.filenames, forKey: .filenames)
        try container.encode(self.extensions, forKey: .extensions)
        try container.encode(self.interpreters, forKey: .interpreters)
        
        try container.encode(self.metadata, forKey: .metadata)
    }
}


extension SyntaxDefinition.Term: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case begin = "beginString"
        case end = "endString"
        case isRegularExpression = "regularExpression"
        case ignoreCase
        case description
    }
    
    
    init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.begin = try container.decode(String.self, forKey: .begin)
        self.end = try container.decodeIfPresent(String.self, forKey: .end)
        self.isRegularExpression = try container.decodeIfPresent(Bool.self, forKey: .isRegularExpression) ?? false
        self.ignoreCase = try container.decodeIfPresent(Bool.self, forKey: .ignoreCase) ?? false
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    
    func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.begin, forKey: .begin)
        try container.encode(self.end, forKey: .end)
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


extension SyntaxDefinition.Outline: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case pattern = "beginString"
        case template = "keyString"
        case ignoreCase
        case bold
        case italic
        case underline
        case description
    }
    
    
    init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.pattern = try container.decode(String.self, forKey: .pattern)
        self.template = try container.decode(String.self, forKey: .template)
        self.ignoreCase = try container.decodeIfPresent(Bool.self, forKey: .ignoreCase) ?? false
        self.bold = try container.decodeIfPresent(Bool.self, forKey: .bold) ?? false
        self.italic = try container.decodeIfPresent(Bool.self, forKey: .italic) ?? false
        self.underline = try container.decodeIfPresent(Bool.self, forKey: .underline) ?? false
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    
    func encode(to encoder: any Encoder) throws {
        
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


extension SyntaxDefinition.IdentifiedString: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case value = "keyString"
    }
    
    
    init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.value = try container.decode(String.self, forKey: .value)
    }
    
    
    func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.value, forKey: .value)
    }
}
