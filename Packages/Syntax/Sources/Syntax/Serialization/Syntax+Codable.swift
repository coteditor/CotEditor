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

extension Syntax.Highlight: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case begin = "beginString"
        case end = "endString"
        case isRegularExpression = "regularExpression"
        case ignoreCase
        case isMultiline
        case description
    }
    
    
    public init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.begin = try container.decodeIfPresent(String.self, forKey: .begin) ?? ""
        self.end = try container.decodeIfPresent(String.self, forKey: .end)
        self.isRegularExpression = try container.decodeIfPresent(Bool.self, forKey: .isRegularExpression) ?? false
        self.ignoreCase = try container.decodeIfPresent(Bool.self, forKey: .ignoreCase) ?? false
        self.isMultiline = try container.decodeIfPresent(Bool.self, forKey: .isMultiline) ?? false
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
        if self.isMultiline {
            try container.encode(true, forKey: .isMultiline)
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
        case kind
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
        self.kind = try container.decodeIfPresent(Kind.self, forKey: .kind)
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
        if let kind = self.kind {
            try container.encode(kind, forKey: .kind)
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


extension Syntax.Comment.Inline: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case begin
        case leadingOnly
    }
    
    
    public init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.begin = try container.decode(String.self, forKey: .begin)
        self.leadingOnly = try container.decodeIfPresent(Bool.self, forKey: .leadingOnly) ?? false
    }
    
    
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.begin, forKey: .begin)
        
        if self.leadingOnly {
            try container.encode(true, forKey: .leadingOnly)
        }
    }
}
