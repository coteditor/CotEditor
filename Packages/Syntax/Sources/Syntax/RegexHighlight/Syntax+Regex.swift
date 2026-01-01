//
//  Syntax+Regex.swift
//  EditorCore
//
//  Created by imanishi on 1/1/26.
//

import Foundation

extension Syntax {
    
    /// The valid outline extractors.
    public var outlineExtractors: [OutlineExtractor] {
        
        self.outlines.compactMap { try? OutlineExtractor(definition: $0) }
    }
    
    
    /// The highlight parser.
    public var highlightParser: HighlightParser {
        
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
                    // extract paired delimiters such as quotes
                    if let token = NestableToken(highlight: highlight),
                       !nestables.keys.contains(token)  // not registered yet
                    {
                        nestables[token] = item.key
                        continue
                    }
                    
                    // extract simple words
                    if !highlight.isRegularExpression, highlight.end == nil {
                        if highlight.ignoreCase {
                            caseInsensitiveWords.append(highlight.begin)
                        } else {
                            words.append(highlight.begin)
                        }
                        continue
                    }
                    
                    highlights.append(highlight)
                }
                
                // transform simple word highlights to single regex for performance reasons
                if !words.isEmpty {
                    highlights.append(Syntax.Highlight(words: words, ignoreCase: false))
                }
                if !caseInsensitiveWords.isEmpty {
                    highlights.append(Syntax.Highlight(words: caseInsensitiveWords, ignoreCase: true))
                }
                
                dict[item.key] = highlights
            }
            .mapValues { $0.compactMap { try? $0.extractor } }
            .filter { !$0.value.isEmpty }
        
        if let blockCommentDelimiters = self.commentDelimiters.block {
            nestables[.pair(blockCommentDelimiters)] = .comments
        }
        if let inlineCommentDelimiter = self.commentDelimiters.inline {
            nestables[.inline(inlineCommentDelimiter)] = .comments
        }
        
        return .init(extractors: extractors, nestables: nestables)
    }
}


private extension Syntax.Highlight {
    
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
    }
}
