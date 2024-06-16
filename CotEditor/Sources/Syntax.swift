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

enum SyntaxType: String, CaseIterable {
    
    case keywords
    case commands
    case types
    case attributes
    case variables
    case values
    case numbers
    case strings
    case characters
    case comments
}


struct Syntax: Equatable {
    
    enum Kind: String, CaseIterable, Codable {
        
        case general
        case code
    }
    
    
    struct Highlight: Equatable {
        
        var begin: String = ""
        var end: String?
        var isRegularExpression: Bool = false
        var ignoreCase: Bool = false
        var description: String?
        
        var isEmpty: Bool {
            
            self.begin.isEmpty && self.end?.isEmpty != false && self.description?.isEmpty != false
        }
    }
    
    
    struct Outline: Equatable {
        
        var pattern: String = ""
        var template: String = ""
        var ignoreCase: Bool = false
        var bold: Bool = false
        var italic: Bool = false
        var underline: Bool = false
        var description: String?
        
        var isEmpty: Bool {
            
            self.pattern.isEmpty && self.pattern.isEmpty && self.description?.isEmpty != false
        }
    }
    
    
    struct Comment: Equatable, Codable {
        
        private enum CodingKeys: String, CodingKey {
            
            case inline = "inlineDelimiter"
            case blockBegin = "beginDelimiter"
            case blockEnd = "endDelimiter"
        }
        
        
        var inline: String?
        var blockBegin: String?
        var blockEnd: String?
        
        var block: Pair<String>? {
            
            if let begin = self.blockBegin, let end = self.blockEnd { Pair(begin, end) } else { nil }
        }
        
        var isEmpty: Bool {
            
            self.block == nil && self.inline == nil
        }
    }
    
    
    struct Metadata: Equatable, Codable {
        
        var version: String?
        var lastModified: String?
        var distributionURL: String?
        var author: String?
        var license: String?
        var description: String?
    }
    
    
    static let none = Syntax(kind: .code)
    
    var kind: Kind = .general
    
    var keywords: [Highlight] = []
    var commands: [Highlight] = []
    var types: [Highlight] = []
    var attributes: [Highlight] = []
    var variables: [Highlight] = []
    var values: [Highlight] = []
    var numbers: [Highlight] = []
    var strings: [Highlight] = []
    var characters: [Highlight] = []
    var comments: [Highlight] = []
    
    var commentDelimiters: Comment = Comment()
    var outlines: [Outline] = []
    var completions: [String] = []
    
    var filenames: [String] = []
    var extensions: [String] = []
    var interpreters: [String] = []
    
    var metadata: Metadata = Metadata()
    
    
    static func highlightKeyPath(for type: SyntaxType) -> WritableKeyPath<Syntax, [Highlight]> {
        
        switch type {
            case .keywords: \.keywords
            case .commands: \.commands
            case .types: \.types
            case .attributes: \.attributes
            case .variables: \.variables
            case .values: \.values
            case .numbers: \.numbers
            case .strings: \.strings
            case .characters: \.characters
            case .comments: \.comments
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Sorted and removed empty items for saving.
    var sanitized: Self {
        
        var syntax = self
        for keyPath in SyntaxType.allCases.map(Syntax.highlightKeyPath(for:)) {
            syntax[keyPath: keyPath].removeAll(where: \.isEmpty)
            syntax[keyPath: keyPath].sort(\.begin, options: .caseInsensitive)
        }
        syntax.outlines.removeAll(where: \.isEmpty)
        syntax.outlines.sort(\.pattern, options: .caseInsensitive)
        syntax.completions.removeAll(where: \.isEmpty)
        syntax.completions.sort(options: .caseInsensitive)
        syntax.extensions.removeAll(where: \.isEmpty)
        syntax.filenames.removeAll(where: \.isEmpty)
        syntax.interpreters.removeAll(where: \.isEmpty)
        
        return syntax
    }
    
    
    var outlineExtractors: [OutlineExtractor] {
        
        self.outlines.compactMap { try? OutlineExtractor(definition: $0) }
    }
    
    
    var highlightParser: HighlightParser {
        
        var nestables: [NestableToken: SyntaxType] = [:]
        let extractors = SyntaxType.allCases
            .reduce(into: [:]) { (dict, type) in
                dict[type] = self[keyPath: Syntax.highlightKeyPath(for: type)]
            }
            .reduce(into: [SyntaxType: [Syntax.Highlight]]()) { (dict, item) in
                var highlights: [Syntax.Highlight] = []
                var words: [String] = []
                var caseInsensitiveWords: [String] = []
                
                for highlight in item.value {
                    // extract paired delimiters such as quotes
                    if !highlight.isRegularExpression,
                       let pair = highlight.end.flatMap({ Pair(highlight.begin, $0) }),
                       pair.begin == pair.end,
                       pair.begin.rangeOfCharacter(from: .alphanumerics) == nil,  // symbol
                       Set(pair.begin).count == 1,  // consists of the same characters
                       !nestables.keys.contains(.pair(pair))  // not registered yet
                    {
                        nestables[.pair(pair)] = item.key
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
    
    
    var completionWords: [String] {
        
        let completions = self.completions.filter { !$0.isEmpty }
        
        return if !completions.isEmpty {
            // from completion definition
            completions
        } else {
            // from normal highlighting words
            SyntaxType.allCases.map(Self.highlightKeyPath(for:))
                .flatMap { self[keyPath: $0] }
                .filter { $0.end == nil && !$0.isRegularExpression }
                .map { $0.begin.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .sorted()
        }
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
