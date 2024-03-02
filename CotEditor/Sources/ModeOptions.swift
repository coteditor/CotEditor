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
