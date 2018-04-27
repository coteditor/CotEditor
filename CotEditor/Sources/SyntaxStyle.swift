//
//  SyntaxStyle.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2018 1024jp
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

struct SyntaxStyle {
    
    // MARK: Public Properties
    
    let name: String
    let isNone: Bool
    let extensions: [String]
    
    let inlineCommentDelimiter: String?
    let blockCommentDelimiters: BlockDelimiters?
    let completionWords: [String]?
    
    let pairedQuoteTypes: [String: SyntaxType]
    let highlightDefinitions: [SyntaxType: [HighlightDefinition]]
    let outlineDefinitions: [OutlineDefinition]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init() {
        self.name = BundledStyleName.none
        self.isNone = true
        self.extensions = []
        
        self.inlineCommentDelimiter = nil
        self.blockCommentDelimiters = nil
        self.completionWords = nil
        
        self.pairedQuoteTypes = [:]
        self.highlightDefinitions = [:]
        self.outlineDefinitions = []
    }
    
    
    init(dictionary: [String: Any], name: String) {
        
        self.name = name
        self.isNone = false
        
        self.extensions = (dictionary[SyntaxKey.extensions.rawValue] as? [[String: String]])?
            .compactMap { $0[SyntaxDefinitionKey.keyString.rawValue] } ?? []
        
        // set comment delimiters
        var inlineCommentDelimiter: String?
        var blockCommentDelimiters: BlockDelimiters?
        if let delimiters = dictionary[SyntaxKey.commentDelimiters.rawValue] as? [String: String] {
            if let delimiter = delimiters[DelimiterKey.inlineDelimiter.rawValue], !delimiter.isEmpty {
                inlineCommentDelimiter = delimiter
            }
            if let beginDelimiter = delimiters[DelimiterKey.beginDelimiter.rawValue],
                let endDelimiter = delimiters[DelimiterKey.endDelimiter.rawValue],
                !beginDelimiter.isEmpty, !endDelimiter.isEmpty
            {
                blockCommentDelimiters = BlockDelimiters(begin: beginDelimiter, end: endDelimiter)
            }
        }
        self.inlineCommentDelimiter = inlineCommentDelimiter
        self.blockCommentDelimiters = blockCommentDelimiters
        
        let definitionDictionary: [SyntaxType: [HighlightDefinition]] = SyntaxType.all.reduce(into: [:]) { (dict, type) in
            guard let wordDicts = dictionary[type.rawValue] as? [[String: Any]] else { return }
            
            let definitions = wordDicts.compactMap { HighlightDefinition(definition: $0) }
            
            guard !definitions.isEmpty else { return }
            
            dict[type] = definitions
        }
        
        // pick quote definitions up to parse quoted text separately with comments in `extractCommentsWithQuotes`
        // also combine simple word definitions into single regex definition
        var quoteTypes = [String: SyntaxType]()
        self.highlightDefinitions = definitionDictionary.reduce(into: [:]) { (dict, item) in
            
            var highlightDefinitions = [HighlightDefinition]()
            var words = [String]()
            var caseInsensitiveWords = [String]()
            
            for definition in item.value {
                // extract quotes
                if !definition.isRegularExpression, definition.beginString == definition.endString,
                    definition.beginString.rangeOfCharacter(from: .alphanumerics) == nil,  // symbol
                    Set(definition.beginString).count == 1,  // consists of the same characters
                    !quoteTypes.keys.contains(definition.beginString)  // not registered yet
                {
                    quoteTypes[definition.beginString] = item.key
                    
                    // remove from the normal highlight definition list
                    continue
                }
                
                // extract simple words
                if !definition.isRegularExpression, definition.endString == nil {
                    if definition.ignoreCase {
                        caseInsensitiveWords.append(definition.beginString)
                    } else {
                        words.append(definition.beginString)
                    }
                    continue
                }
                
                highlightDefinitions.append(definition)
            }
            
            // transform simple word highlights to single regex for performance reasons
            if !words.isEmpty {
                highlightDefinitions.append(HighlightDefinition(words: words, ignoreCase: false))
            }
            if !caseInsensitiveWords.isEmpty {
                highlightDefinitions.append(HighlightDefinition(words: caseInsensitiveWords, ignoreCase: true))
            }
            
            guard !highlightDefinitions.isEmpty else { return }
            
            dict[item.key] = highlightDefinitions
        }
        self.pairedQuoteTypes = quoteTypes
        
        // create word-completion data set
        self.completionWords = {
            let words: [String]
            if let completionDicts = dictionary[SyntaxKey.completions.rawValue] as? [[String: Any]], !completionDicts.isEmpty {
                // create from completion definition
                words = completionDicts
                    .compactMap { $0[SyntaxDefinitionKey.keyString.rawValue] as? String }
                    .filter { !$0.isEmpty }
            } else {
                // create from normal highlighting words
                words = definitionDictionary.values.flatMap { $0 }
                    .filter { $0.endString == nil && !$0.isRegularExpression }
                    .map { $0.beginString.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
            
            return words.isEmpty ? nil : words.sorted()
        }()
        
        // parse outline definitions
        self.outlineDefinitions = (dictionary[SyntaxKey.outlineMenu.rawValue] as? [[String: Any]])?
            .compactMap { OutlineDefinition(definition: $0) } ?? []
    }
    
    
    
    // MARK: Public Methods
    
    /// whether receiver has any syntax highlight defintion
    var hasHighlightDefinition: Bool {
        
        return (!self.highlightDefinitions.isEmpty || !self.pairedQuoteTypes.isEmpty || self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil)
    }
    
}



extension SyntaxStyle: Equatable {
    
    static func == (lhs: SyntaxStyle, rhs: SyntaxStyle) -> Bool {
        
        return lhs.name == rhs.name &&
            lhs.extensions == rhs.extensions &&
            lhs.inlineCommentDelimiter == rhs.inlineCommentDelimiter &&
            lhs.blockCommentDelimiters == rhs.blockCommentDelimiters &&
            lhs.pairedQuoteTypes == rhs.pairedQuoteTypes &&
            lhs.outlineDefinitions == rhs.outlineDefinitions &&
            lhs.highlightDefinitions == rhs.highlightDefinitions
    }
    
}


extension SyntaxStyle: CustomDebugStringConvertible {
    
    var debugDescription: String {
        
        return "<SyntaxStyle -\(self.name)>"
    }
    
}
