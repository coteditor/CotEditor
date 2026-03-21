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
import StringUtils

extension Syntax {
    
    /// The parser for the outline extraction.
    public var outlineParser: (any OutlineParsing)? {
        
        let extractors = self.outlines.compactMap { try? OutlineExtractor(definition: $0) }
        
        guard !extractors.isEmpty else { return nil }
        
        return RegexOutlineParser(extractors: extractors)
    }
    
    
    /// The parser for the syntax highlighting.
    public var highlightParser: (any HighlightParsing)? {
        
        let extractors = self.highlights
            .mapValues(\.consolidatingSimpleWords)
            .mapValues { $0.compactMap { try? $0.extractor } }
            .filter { !$0.value.isEmpty }
        let nestables = self.nestables
        
        guard !extractors.isEmpty || !nestables.isEmpty else { return nil }
        
        return RegexHighlightParser(extractors: extractors, nestables: nestables)
    }
    
    
    // MARK: Internal Methods
    
    /// `NestableToken`s for the regex-based syntax highlighting.
    var nestables: [NestableToken: SyntaxType] {
        
        var nestables: [NestableToken: SyntaxType] = [:]
        
        for delimiter in self.stringDelimiters {
            // -> sort prefixes by descending length so that longest-match-first is guaranteed
            //    and the Hashable identity of NestableToken stays stable
            let prefixes = (delimiter.prefixes ?? []).sorted { $0.count > $1.count }
            nestables[.pair(.init(delimiter.begin, delimiter.end), prefixes: prefixes, isMultiline: delimiter.isMultiline, isNestable: true, escapeCharacter: delimiter.escapeCharacter)] = .strings
        }
        for delimiter in self.characterDelimiters {
            let prefixes = (delimiter.prefixes ?? []).sorted { $0.count > $1.count }
            nestables[.pair(.init(delimiter.begin, delimiter.end), prefixes: prefixes, isMultiline: false, isNestable: true, escapeCharacter: delimiter.escapeCharacter)] = .characters
        }
        for delimiter in self.commentDelimiters.blocks {
            nestables[.pair(delimiter.pair, isMultiline: true, isNestable: delimiter.isNestable)] = .comments
        }
        for delimiter in self.commentDelimiters.inlines {
            nestables[.inline(delimiter.begin, leadingOnly: delimiter.leadingOnly)] = .comments
        }
        
        return nestables
    }
}


extension Collection where Element == Syntax.Highlight {

    /// Returns highlights by consolidating simple word definitions into single regex patterns for performance.
    var consolidatingSimpleWords: [Syntax.Highlight] {
        
        var highlights: [Syntax.Highlight] = []
        var words: [String] = []
        var caseInsensitiveWords: [String] = []
        
        for highlight in self {
            if !highlight.isRegularExpression, highlight.end == nil {
                // extract simple words
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
        
        return highlights
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
