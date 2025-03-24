//
//  Syntax.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2025 1024jp
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
import StringUtils

public enum SyntaxType: String, Sendable, CaseIterable {
    
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


public struct Syntax: Equatable, Sendable {
    
    public enum Kind: String, Sendable, CaseIterable, Codable {
        
        case general
        case code
    }
    
    
    public struct Highlight: Equatable, Sendable {
        
        public var begin: String
        public var end: String?
        public var isRegularExpression: Bool
        public var ignoreCase: Bool
        public var description: String?
        
        public var isEmpty: Bool {
            
            self.begin.isEmpty && self.end?.isEmpty != false && self.description?.isEmpty != false
        }
        
        
        public init(begin: String = "", end: String? = nil, isRegularExpression: Bool = false, ignoreCase: Bool = false, description: String? = nil) {
            
            self.begin = begin
            self.end = end
            self.isRegularExpression = isRegularExpression
            self.ignoreCase = ignoreCase
            self.description = description
        }
    }
    
    
    public struct Outline: Equatable, Sendable {
        
        public var pattern: String
        public var template: String
        public var ignoreCase: Bool
        public var bold: Bool
        public var italic: Bool
        public var underline: Bool
        public var description: String?
        
        public var isEmpty: Bool {
            
            self.pattern.isEmpty && self.pattern.isEmpty && self.description?.isEmpty != false
        }
        
        
        public init(pattern: String = "", template: String = "", ignoreCase: Bool = false, bold: Bool = false, italic: Bool = false, underline: Bool = false, description: String? = nil) {
            
            self.pattern = pattern
            self.template = template
            self.ignoreCase = ignoreCase
            self.bold = bold
            self.italic = italic
            self.underline = underline
            self.description = description
        }
    }
    
    
    public struct Comment: Equatable, Sendable, Codable {
        
        private enum CodingKeys: String, CodingKey {
            
            case inline = "inlineDelimiter"
            case blockBegin = "beginDelimiter"
            case blockEnd = "endDelimiter"
        }
        
        
        public var inline: String?
        public var blockBegin: String?
        public var blockEnd: String?
        
        public var block: Pair<String>? {
            
            if let begin = self.blockBegin, let end = self.blockEnd { Pair(begin, end) } else { nil }
        }
        
        public var isEmpty: Bool {
            
            self.block == nil && self.inline == nil
        }
        
        
        public init(inline: String? = nil, blockBegin: String? = nil, blockEnd: String? = nil) {
            
            self.inline = inline
            self.blockBegin = blockBegin
            self.blockEnd = blockEnd
        }
    }
    
    
    public struct Metadata: Equatable, Sendable, Codable {
        
        public var version: String?
        public var lastModified: String?
        public var distributionURL: String?
        public var author: String?
        public var license: String?
        public var description: String?
        
        
        public init(version: String? = nil, lastModified: String? = nil, distributionURL: String? = nil, author: String? = nil, license: String? = nil, description: String? = nil) {
            
            self.version = version
            self.lastModified = lastModified
            self.distributionURL = distributionURL
            self.author = author
            self.license = license
            self.description = description
        }
    }
    
    
    public static let none = Syntax(kind: .code)
    
    public var kind: Kind
    
    public var keywords: [Highlight]
    public var commands: [Highlight]
    public var types: [Highlight]
    public var attributes: [Highlight]
    public var variables: [Highlight]
    public var values: [Highlight]
    public var numbers: [Highlight]
    public var strings: [Highlight]
    public var characters: [Highlight]
    public var comments: [Highlight]
    
    public var commentDelimiters: Comment
    public var outlines: [Outline]
    public var completions: [String]
    
    public var filenames: [String]
    public var extensions: [String]
    public var interpreters: [String]
    
    public var metadata: Metadata
    
    
    public static func highlightKeyPath(for type: SyntaxType) -> WritableKeyPath<Syntax, [Highlight]> {
        
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
    
    public init(
        kind: Kind = .general,
        keywords: [Highlight] = [],
        commands: [Highlight] = [],
        types: [Highlight] = [],
        attributes: [Highlight] = [],
        variables: [Highlight] = [],
        values: [Highlight] = [],
        numbers: [Highlight] = [],
        strings: [Highlight] = [],
        characters: [Highlight] = [],
        comments: [Highlight] = [],
        commentDelimiters: Comment = .init(),
        outlines: [Outline] = [],
        completions: [String] = [],
        filenames: [String] = [],
        extensions: [String] = [],
        interpreters: [String] = [],
        metadata: Metadata = .init()
    ) {
        
        self.kind = kind
        self.keywords = keywords
        self.commands = commands
        self.types = types
        self.attributes = attributes
        self.variables = variables
        self.values = values
        self.numbers = numbers
        self.strings = strings
        self.characters = characters
        self.comments = comments
        self.commentDelimiters = commentDelimiters
        self.outlines = outlines
        self.completions = completions
        self.filenames = filenames
        self.extensions = extensions
        self.interpreters = interpreters
        self.metadata = metadata
    }
    
    
    /// Sorted and removed empty items for saving.
    public var sanitized: Self {
        
        var syntax = self
        for keyPath in SyntaxType.allCases.map(Syntax.highlightKeyPath(for:)) {
            syntax[keyPath: keyPath].removeAll(where: \.isEmpty)
            syntax[keyPath: keyPath].caseInsensitiveSort(\.begin)
        }
        syntax.outlines.removeAll(where: \.isEmpty)
        syntax.outlines.caseInsensitiveSort(\.pattern)
        syntax.completions.removeAll(where: \.isEmpty)
        syntax.completions.caseInsensitiveSort(\.self)
        syntax.extensions.removeAll(where: \.isEmpty)
        syntax.filenames.removeAll(where: \.isEmpty)
        syntax.interpreters.removeAll(where: \.isEmpty)
        
        return syntax
    }
    
    
    /// The valid outline extractors.
    public var outlineExtractors: [OutlineExtractor] {
        
        self.outlines.compactMap { try? OutlineExtractor(definition: $0) }
    }
    
    
    /// The highlight parser.
    public var highlightParser: HighlightParser {
        
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
                       let pair = highlight.end.map({ Pair(highlight.begin, $0) }),
                       Set(pair.begin) == Set(pair.end),
                       pair.begin.rangeOfCharacter(from: .alphanumerics) == nil,  // symbol
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
    
    
    /// The completion words.
    public var completionWords: [String] {
        
        let completions = self.completions.filter { !$0.isEmpty }
        
        return if !completions.isEmpty {
            // from completion definition
            completions
        } else {
            // from normal highlighting words
            SyntaxType.allCases
                .map(Self.highlightKeyPath(for:))
                .flatMap { self[keyPath: $0] }
                .filter { $0.end == nil && !$0.isRegularExpression }
                .map { $0.begin.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .sorted()
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


private extension MutableCollection where Self: RandomAccessCollection {
    
    /// Sorts the collection in place, using the string value that the given key path refers as the comparison between elements.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the string to compare.
    mutating func caseInsensitiveSort(_ keyPath: KeyPath<Element, String>) {
        
        self.sort { $0[keyPath: keyPath].caseInsensitiveCompare($1[keyPath: keyPath]) == .orderedAscending }
    }
}
