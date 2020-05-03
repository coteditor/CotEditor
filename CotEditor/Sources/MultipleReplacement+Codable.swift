//
//  MultipleReplacement+Codable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2020 1024jp
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

extension MultipleReplacement.Replacement: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case findString
        case replacementString
        case usesRegularExpression
        case ignoresCase
        case isEnabled
        case description
    }
    
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.findString = try container.decode(String.self, forKey: .findString)
        self.replacementString = try container.decode(String.self, forKey: .replacementString)
        self.usesRegularExpression = try container.decodeIfPresent(Bool.self, forKey: .usesRegularExpression) ?? false
        self.ignoresCase = try container.decodeIfPresent(Bool.self, forKey: .ignoresCase) ?? false
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    }
    
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.findString, forKey: .findString)
        try container.encode(self.replacementString, forKey: .replacementString)
        
        if self.usesRegularExpression {
            try container.encode(true, forKey: .usesRegularExpression)
        }
        if self.ignoresCase {
            try container.encode(true, forKey: .ignoresCase)
        }
        if !self.isEnabled {
            try container.encode(false, forKey: .isEnabled)
        }
        if let description = self.description {
            try container.encode(description, forKey: .description)
        }
    }
    
}



extension MultipleReplacement.Settings: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case textualOptions
        case regexOptions
        case matchesFullWord
        case unescapesReplacementString
    }
    
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let textualOptions = try container.decode(UInt.self, forKey: .textualOptions)
        self.textualOptions = String.CompareOptions(rawValue: textualOptions)
        
        let regexOptions = try container.decode(UInt.self, forKey: .regexOptions)
        self.regexOptions = NSRegularExpression.Options(rawValue: regexOptions)
        
        self.matchesFullWord = try container.decodeIfPresent(Bool.self, forKey: .matchesFullWord) ?? false
        
        self.unescapesReplacementString = try container.decodeIfPresent(Bool.self, forKey: .unescapesReplacementString) ?? false
    }
    
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.textualOptions.rawValue, forKey: .textualOptions)
        try container.encode(self.regexOptions.rawValue, forKey: .regexOptions)
        try container.encode(self.matchesFullWord, forKey: .matchesFullWord)
        try container.encode(self.unescapesReplacementString, forKey: .unescapesReplacementString)
    }
    
}
