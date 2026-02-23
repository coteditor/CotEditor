//
//  Syntax+RegexParsers.swift
//  Syntax

//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2026 1024jp
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

import Foundation

extension Syntax {
    
    /// The parser for the outline extraction.
    public var outlineParser: (any OutlineParsing)? {
        
        let extractors = self.outlines.compactMap { try? OutlineExtractor(definition: $0) }
        
        guard !extractors.isEmpty else { return nil }
        
        return RegexOutlineParser(extractors: extractors)
    }
    
    
    /// The parser for the syntax highlighting.
    public var highlightParser: (any HighlightParsing)? {
        
        var nestables: [NestableToken: SyntaxType] = [:]
        let extractors = SyntaxType.allCases
            .reduce(into: [:]) { dict, type in
                dict[type] = self.highlights[type]
            }
            .reduce(into: [SyntaxType: [Syntax.Highlight]]()) { dict, item in
                var highlights: [Syntax.Highlight] = []
                var words: [String] = []
                var caseInsensitiveWords: [String] = []
                
                for highlight in item.value {
                    if // extract paired delimiters such as quotes
                        let token = NestableToken(highlight: highlight),
                        !nestables.keys.contains(token)  // not registered yet
                    {
                        nestables[token] = item.key
                        
                    } else if // extract simple words
                        !highlight.isRegularExpression, highlight.end == nil
                    {
                        if highlight.ignoreCase {
                            caseInsensitiveWords.append(highlight.begin)
                        } else {
                            words.append(highlight.begin)
                        }
                    } else {
                        highlights.append(highlight)
                    }
                }
                
                // transform simple word highlights to single regex for performance reasons
                if !words.isEmpty {
                    highlights.append(Syntax.Highlight(words: words, ignoreCase: false))
                }
                if !caseInsensitiveWords.isEmpty {
                    highlights.append(Syntax.Highlight(words: caseInsensitiveWords, ignoreCase: true))
                }
                if !highlights.isEmpty {
                    dict[item.key] = highlights
                }
            }
            .mapValues { $0.compactMap { try? $0.extractor } }
            .filter { !$0.value.isEmpty }
        
        for delimiter in self.commentDelimiters.blocks {
            nestables[.pair(delimiter, isMultiline: true)] = .comments
        }
        for delimiter in self.commentDelimiters.inlines {
            nestables[.inline(delimiter.begin, leadingOnly: delimiter.leadingOnly)] = .comments
        }
        
        guard !extractors.isEmpty || !nestables.isEmpty else { return nil }
        
        return RegexHighlightParser(extractors: extractors, nestables: nestables, lexicalRules: self.lexicalRules
        )
    }
}


extension Syntax.Highlight {
    
    /// Creates a regex type definition from simple words by considering non-word characters around words.
    init(words: [String], ignoreCase: Bool) {
        
        assert(!words.isEmpty)
        
        let rawBoundary = String(Set("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz" + words.joined()).sorted())
            .replacing(/\s/, with: "")
        let boundary = NSRegularExpression.escapedPattern(for: rawBoundary)
            .replacing("]", with: "\\]")
            .replacing("-", with: "\\-")
        
        let escapedWords = words.sorted()
            .reversed()  // reverse to precede longer words
            .map(NSRegularExpression.escapedPattern(for:))
        
        self.begin = "(?<![\(boundary)])(?:\(escapedWords.joined(separator: "|")))(?![\(boundary)])"
        self.end = nil
        self.isRegularExpression = true
        self.ignoreCase = ignoreCase
        self.isMultiline = false
    }
}
