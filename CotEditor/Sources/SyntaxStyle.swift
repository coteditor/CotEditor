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
    
    
    /// create a regex type definition from simple words by considering non-word characters around words
    init(words: [String], ignoreCase: Bool) {
        
        assert(!words.isEmpty)
        
        let escapedWords = words.sorted().reversed().map(NSRegularExpression.escapedPattern(for:))  // reverse to precede longer word
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

struct SyntaxStyle: Equatable {
    
    // MARK: Public Properties
    
    var name: String
    var extensions: [String] = []
    
    var inlineCommentDelimiter: String?
    var blockCommentDelimiters: Pair<String>?
    var completionWords: [String] = []
    
    
    // MARK: Private Properties
    
    private var highlightDefinitions: [SyntaxType: [HighlightDefinition]] = [:]
    private var outlineDefinitions: [OutlineDefinition] = []
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init() {
        self.name = BundledStyleName.none
    }
    
    
    init(dictionary: [String: Any], name: String) {
        
        self.name = name
        
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
        
        self.highlightDefinitions = SyntaxType.allCases.reduce(into: [:]) { (dict, type) in
            guard let wordDicts = dictionary[type.rawValue] as? [[String: Any]] else { return }
            
            dict[type] = wordDicts.compactMap { try? HighlightDefinition(dictionary: $0) }
        }
        
        // parse outline definitions
        self.outlineDefinitions = (dictionary[SyntaxKey.outlineMenu] as? [[String: Any]])?.lazy
            .compactMap { try? OutlineDefinition(dictionary: $0) } ?? []
        
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
                return self.highlightDefinitions.values.flatMap { $0 }
                    .filter { $0.endString == nil && !$0.isRegularExpression }
                    .map { $0.beginString.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .sorted()
            }
        }()
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
                       let pair = definition.endString.flatMap({ Pair(definition.beginString, $0) }),
                       pair.begin == pair.end,
                       pair.begin.rangeOfCharacter(from: .alphanumerics) == nil,  // symbol
                       Set(pair.begin).count == 1,  // consists of the same characters
                       !nestables.keys.contains(.pair(pair))  // not registered yet
                    {
                        nestables[.pair(pair)] = item.key
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
