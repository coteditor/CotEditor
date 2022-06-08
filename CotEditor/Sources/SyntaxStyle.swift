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
//  © 2014-2022 1024jp
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

struct HighlightDefinition: Equatable {
    
    enum `Error`: Swift.Error {
        
        case invalidFormat
    }
    
    
    var beginString: String = ""
    var endString: String?
    var isRegularExpression: Bool = false
    var ignoreCase: Bool = false
    
    var description: String?
    
    
    
    init(dictionary: [String: Any]) throws {
        
        guard let beginString = dictionary[SyntaxDefinitionKey.beginString] as? String else { throw Error.invalidFormat }
        
        self.beginString = beginString
        if let endString = dictionary[SyntaxDefinitionKey.endString] as? String, !endString.isEmpty {
            self.endString = endString
        }
        self.isRegularExpression = (dictionary[SyntaxDefinitionKey.regularExpression] as? Bool) ?? false
        self.ignoreCase = (dictionary[SyntaxDefinitionKey.ignoreCase] as? Bool) ?? false
    }
    
}


extension HighlightDefinition {
    
    /// create a regex type definition from simple words by considering non-word characters around words
    init(words: [String], ignoreCase: Bool) {
        
        assert(!words.isEmpty)
        
        let escapedWords = words.sorted().reversed().map { NSRegularExpression.escapedPattern(for: $0) }  // reverse to precede longer word
        let rawBoundary = String(Set(words.joined() + "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_").sorted())
            .replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        let boundary = NSRegularExpression.escapedPattern(for: rawBoundary)
        let pattern = "(?<![" + boundary + "])" + "(?:" + escapedWords.joined(separator: "|") + ")" + "(?![" + boundary + "])"
        
        self.beginString = pattern
        self.endString = nil
        self.isRegularExpression = true
        self.ignoreCase = ignoreCase
    }
    
}



struct OutlineDefinition: Equatable {
    
    enum `Error`: Swift.Error {
        
        case invalidFormat
    }
    
    
    var pattern: String = ""
    var template: String = ""
    var ignoreCase: Bool = false
    var bold: Bool = false
    var italic: Bool = false
    var underline: Bool = false
    
    var description: String?
    
    
    private enum CodingKeys: String, CodingKey {
        
        case pattern = "beginString"
        case template = "keyString"
        case ignoreCase
        case bold
        case italic
        case underline
        case description
    }
    
    
    
    init(dictionary: [String: Any]) throws {
        
        guard let pattern = dictionary[CodingKeys.pattern] as? String else { throw Error.invalidFormat }
        
        self.pattern = pattern
        self.template = dictionary[CodingKeys.template] as? String ?? ""
        self.ignoreCase = dictionary[CodingKeys.ignoreCase] as? Bool ?? false
        self.bold = dictionary[CodingKeys.bold] as? Bool ?? false
        self.italic = dictionary[CodingKeys.italic] as? Bool ?? false
        self.underline = dictionary[CodingKeys.underline] as? Bool ?? false
    }
    
}



// MARK: -

struct SyntaxStyle {
    
    // MARK: Public Properties
    
    let name: String
    let isNone: Bool
    let extensions: [String]
    
    let inlineCommentDelimiter: String?
    let blockCommentDelimiters: Pair<String>?
    let completionWords: [String]
    
    let nestablePaires: [String: SyntaxType]
    let highlightDefinitions: [SyntaxType: [HighlightDefinition]]
    let outlineDefinitions: [OutlineDefinition]
    
    private(set) lazy var outlineExtractors: [OutlineExtractor] = self.outlineDefinitions.compactMap { try? OutlineExtractor(definition: $0) }
    private(set) lazy var highlightExtractors: [SyntaxType: [any HighlightExtractable]] = self.highlightDefinitions.mapValues { $0.compactMap { try? $0.extractor } }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init() {
        self.name = BundledStyleName.none
        self.isNone = true
        self.extensions = []
        
        self.inlineCommentDelimiter = nil
        self.blockCommentDelimiters = nil
        self.completionWords = []
        
        self.nestablePaires = [:]
        self.highlightDefinitions = [:]
        self.outlineDefinitions = []
    }
    
    
    init(dictionary: [String: Any], name: String) {
        
        self.name = name
        self.isNone = false
        
        self.extensions = (dictionary[SyntaxKey.extensions] as? [[String: String]])?
            .compactMap { $0[SyntaxDefinitionKey.keyString] } ?? []
        
        // set comment delimiters
        var inlineCommentDelimiter: String?
        var blockCommentDelimiters: Pair<String>?
        if let delimiters = dictionary[SyntaxKey.commentDelimiters] as? [String: String] {
            if let delimiter = delimiters[DelimiterKey.inlineDelimiter], !delimiter.isEmpty {
                inlineCommentDelimiter = delimiter
            }
            if let beginDelimiter = delimiters[DelimiterKey.beginDelimiter],
               let endDelimiter = delimiters[DelimiterKey.endDelimiter],
               !beginDelimiter.isEmpty, !endDelimiter.isEmpty
            {
                blockCommentDelimiters = Pair<String>(beginDelimiter, endDelimiter)
            }
        }
        self.inlineCommentDelimiter = inlineCommentDelimiter
        self.blockCommentDelimiters = blockCommentDelimiters
        
        let definitionDictionary: [SyntaxType: [HighlightDefinition]] = SyntaxType.allCases.reduce(into: [:]) { (dict, type) in
            guard let wordDicts = dictionary[type.rawValue] as? [[String: Any]] else { return }
            
            let definitions = wordDicts.compactMap { try? HighlightDefinition(dictionary: $0) }
            
            guard !definitions.isEmpty else { return }
            
            dict[type] = definitions
        }
        
        // pick quote definitions up to parse quoted text separately with comments in `extractCommentsWithNestablePaires`
        // also combine simple word definitions into single regex definition
        var nestablePaires: [String: SyntaxType] = [:]
        self.highlightDefinitions = definitionDictionary.reduce(into: [:]) { (dict, item) in
            
            var highlightDefinitions: [HighlightDefinition] = []
            var words: [String] = []
            var caseInsensitiveWords: [String] = []
            
            for definition in item.value {
                // extract paired delimiters such as quotes
                if !definition.isRegularExpression,
                    definition.beginString == definition.endString,
                    definition.beginString.rangeOfCharacter(from: .alphanumerics) == nil,  // symbol
                    Set(definition.beginString).count == 1,  // consists of the same characters
                    !nestablePaires.keys.contains(definition.beginString)  // not registered yet
                {
                    nestablePaires[definition.beginString] = item.key
                    
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
        self.nestablePaires = nestablePaires
        
        // create word-completion data set
        self.completionWords = {
            if let completionDicts = dictionary[SyntaxKey.completions] as? [[String: Any]], !completionDicts.isEmpty {
                // create from completion definition
                return completionDicts
                    .compactMap { $0[SyntaxDefinitionKey.keyString] as? String }
                    .filter { !$0.isEmpty }
                    .sorted()
            } else {
                // create from normal highlighting words
                return definitionDictionary.values.flatMap { $0 }
                    .filter { $0.endString == nil && !$0.isRegularExpression }
                    .map { $0.beginString.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .sorted()
            }
        }()
        
        // parse outline definitions
        self.outlineDefinitions = (dictionary[SyntaxKey.outlineMenu] as? [[String: Any]])?.lazy
            .compactMap { try? OutlineDefinition(dictionary: $0) } ?? []
    }
    
    
    
    // MARK: Public Methods
    
    /// whether receiver has any syntax highlight defintion
    var hasHighlightDefinition: Bool {
        
        return (!self.highlightDefinitions.isEmpty || !self.nestablePaires.isEmpty || self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil)
    }
    
}



extension SyntaxStyle: Equatable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        
        return lhs.name == rhs.name &&
            lhs.extensions == rhs.extensions &&
            lhs.inlineCommentDelimiter == rhs.inlineCommentDelimiter &&
            lhs.blockCommentDelimiters == rhs.blockCommentDelimiters &&
            lhs.nestablePaires == rhs.nestablePaires &&
            lhs.outlineDefinitions == rhs.outlineDefinitions &&
            lhs.highlightDefinitions == rhs.highlightDefinitions
    }
    
}


extension SyntaxStyle: CustomDebugStringConvertible {
    
    var debugDescription: String {
        
        return "<SyntaxStyle -\(self.name)>"
    }
    
}
