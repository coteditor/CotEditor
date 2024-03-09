//
//  ModeOptions.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

struct ModeOptions: Equatable, Codable {
    
    var fontType: FontType = .standard
    
    var smartInsertDelete: Bool = false
    var automaticQuoteSubstitution: Bool = false
    var automaticDashSubstitution: Bool = false
    var automaticSymbolBalancing: Bool = false
    
    var continuousSpellChecking: Bool = false
    var grammarChecking: Bool = false
    var automaticSpellingCorrection: Bool = false
    
    var completionWordTypes: CompletionWordTypes = []
    var automaticCompletion: Bool = false
}


struct CompletionWordTypes: OptionSet, Codable {
    
    let rawValue: Int
    
    static let standard = Self(rawValue: 1 << 0)
    static let document = Self(rawValue: 1 << 1)
    static let syntax = Self(rawValue: 1 << 2)
}


extension Syntax.Kind {
    
    var defaultOptions: ModeOptions {
        
        switch self {
            case .general:
                ModeOptions(
                    fontType: .standard,
                    smartInsertDelete: true,
                    automaticQuoteSubstitution: true,
                    automaticDashSubstitution: true,
                    automaticSymbolBalancing: false,
                    continuousSpellChecking: true,
                    grammarChecking: false,
                    automaticSpellingCorrection: false,
                    completionWordTypes: [.standard, .document],
                    automaticCompletion: false
                )
                
            case .code:
                ModeOptions(
                    fontType: .monospaced,
                    smartInsertDelete: false,
                    automaticQuoteSubstitution: false,
                    automaticDashSubstitution: false,
                    automaticSymbolBalancing: true,
                    continuousSpellChecking: false,
                    grammarChecking: false,
                    automaticSpellingCorrection: false,
                    completionWordTypes: [.document, .syntax],
                    automaticCompletion: false
                )
        }
    }
}


// MARK: - Serialization

extension ModeOptions {
    
    /// Instantiates from the serialization form.
    ///
    /// - Parameter dictionary: The dictionary.
    init?(dictionary: [String: AnyHashable]) {
        
        let dictionary = dictionary.compactMapKeys(CodingKeys.init(stringValue:))
        
        guard
            let fontRawValue = dictionary[.fontType] as? String,
            let fontType = FontType(rawValue: fontRawValue) else
        { return nil }
        
        self.fontType = fontType
        
        self.smartInsertDelete = dictionary[.smartInsertDelete] as? Bool ?? false
        self.automaticQuoteSubstitution = dictionary[.automaticQuoteSubstitution] as? Bool ?? false
        self.automaticDashSubstitution = dictionary[.automaticDashSubstitution] as? Bool ?? false
        self.automaticSymbolBalancing = dictionary[.automaticSymbolBalancing] as? Bool ?? false
        
        self.continuousSpellChecking = dictionary[.continuousSpellChecking] as? Bool ?? false
        self.grammarChecking = dictionary[.grammarChecking] as? Bool ?? false
        self.automaticSpellingCorrection = dictionary[.automaticSpellingCorrection] as? Bool ?? false
        
        self.completionWordTypes = CompletionWordTypes(rawValue: dictionary[.completionWordTypes] as? Int ?? 0)
        self.automaticCompletion = dictionary[.automaticCompletion] as? Bool ?? false
    }
    
    
    /// Dictionary representation to serialize
    var dictionary: [String: AnyHashable] {
        
        [CodingKeys
         .fontType: self.fontType.rawValue,
         
         .smartInsertDelete: self.smartInsertDelete,
         .automaticQuoteSubstitution: self.automaticQuoteSubstitution,
         .automaticDashSubstitution: self.automaticDashSubstitution,
         .automaticSymbolBalancing: self.automaticSymbolBalancing,
         
         .continuousSpellChecking: self.continuousSpellChecking,
         .grammarChecking: self.grammarChecking,
         .automaticSpellingCorrection: self.automaticSpellingCorrection,
         
         .completionWordTypes: self.completionWordTypes.rawValue,
         .automaticCompletion: self.automaticCompletion,
        ]
        .filter { ($0.value as? Int) != 0 }
        .filter { ($0.value as? Bool) != false }
        .mapKeys(\.stringValue)
    }
}
