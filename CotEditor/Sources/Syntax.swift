//
//  Syntax.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2024 1024jp
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

struct Syntax: Equatable {
    
    enum Kind: String, CaseIterable, Codable {
        
        case general
        case code
    }
    
    
    // MARK: Public Properties
    
    static let none = Syntax(name: BundledSyntaxName.none, kind: .code)
    
    var name: String
    var kind: Kind
    var extensions: [String] = []
    
    var inlineCommentDelimiter: String?
    var blockCommentDelimiters: Pair<String>?
    var completionWords: [String] = []
    
    
    // MARK: Private Properties
    
    private var highlightDefinitions: [SyntaxType: [HighlightDefinition]] = [:]
    private var outlineDefinitions: [OutlineDefinition] = []
    
    
    
    // MARK: Lifecycle
    
    private init(name: String, kind: Kind) {
        
        self.name = name
        self.kind = kind
    }
    
    
    init(dictionary: [String: Any], name: String) {
        
        self.name = name
        self.kind = (dictionary[SyntaxKey.kind] as? String).flatMap(Kind.init(rawValue:)) ?? .general
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
        
        // parse highlight definitions
        self.highlightDefinitions = SyntaxType.allCases.reduce(into: [:]) { (dict, type) in
            guard let wordDicts = dictionary[type] as? [[String: Any]] else { return }
            
            dict[type] = wordDicts.compactMap { try? HighlightDefinition(dictionary: $0) }
        }
        
        // parse outline definitions
        self.outlineDefinitions = (dictionary[SyntaxKey.outlineMenu] as? [[String: Any]])?.lazy
            .compactMap { try? OutlineDefinition(dictionary: $0) } ?? []
        
        // create word-completion data set
        self.completionWords = if let completionDicts = dictionary[SyntaxKey.completions] as? [[String: Any]], !completionDicts.isEmpty {
            // from completion definition
            completionDicts
                .compactMap { $0[SyntaxDefinitionKey.keyString] as? String }
                .filter { !$0.isEmpty }
                .sorted()
        } else {
            // from normal highlighting words
            self.highlightDefinitions.values.flatMap { $0 }
                .filter { $0.end == nil && !$0.isRegularExpression }
                .map { $0.begin.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .sorted()
        }
    }
    
    
    
    // MARK: Public Methods
    
    var outlineExtractors: [OutlineExtractor] {
        
        self.outlineDefinitions.compactMap { try? OutlineExtractor(definition: $0) }
    }
    
    
    var highlightParser: HighlightParser {
        
        var nestables: [NestableToken: SyntaxType] = [:]
        let extractors = self.highlightDefinitions
            .reduce(into: [SyntaxType: [HighlightDefinition]]()) { (dict, item) in
                var definitions: [HighlightDefinition] = []
                var words: [String] = []
                var caseInsensitiveWords: [String] = []
                
                for definition in item.value {
                    // extract paired delimiters such as quotes
                    if !definition.isRegularExpression,
                       let pair = definition.end.flatMap({ Pair(definition.begin, $0) }),
                       pair.begin == pair.end,
                       pair.begin.rangeOfCharacter(from: .alphanumerics) == nil,  // symbol
                       Set(pair.begin).count == 1,  // consists of the same characters
                       !nestables.keys.contains(.pair(pair))  // not registered yet
                    {
                        nestables[.pair(pair)] = item.key
                        continue
                    }
                    
                    // extract simple words
                    if !definition.isRegularExpression, definition.end == nil {
                        if definition.ignoreCase {
                            caseInsensitiveWords.append(definition.begin)
                        } else {
                            words.append(definition.begin)
                        }
                        continue
                    }
                    
                    definitions.append(definition)
                }
                
                // transform simple word highlights to single regex for performance reasons
                if !words.isEmpty {
                    definitions.append(HighlightDefinition(words: words, ignoreCase: false))
                }
                if !caseInsensitiveWords.isEmpty {
                    definitions.append(HighlightDefinition(words: caseInsensitiveWords, ignoreCase: true))
                }
                
                dict[item.key] = definitions
            }
            .mapValues { $0.compactMap { try? $0.extractor } }
            .filter { !$0.value.isEmpty }
        
        if let blockCommentDelimiters = self.blockCommentDelimiters {
            nestables[.pair(blockCommentDelimiters)] = .comments
        }
        if let inlineCommentDelimiter = self.inlineCommentDelimiter {
            nestables[.inline(inlineCommentDelimiter)] = .comments
        }
        
        return .init(extractors: extractors, nestables: nestables)
    }
}


extension Syntax.Kind {
    
    var fontType: FontType {
        
        switch self {
            case .general: .standard
            case .code: .monospaced
        }
    }
}
