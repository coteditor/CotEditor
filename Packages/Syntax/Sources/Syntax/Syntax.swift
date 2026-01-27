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
//

public import StringUtils
import Foundation

public struct Syntax: Equatable, Sendable {
    
    public enum Kind: String, Sendable, CaseIterable, Codable {
        
        case general
        case code
    }
    
    
    public struct FileMap: Equatable, Sendable, Codable {
        
        public var extensions: [String]?
        public var filenames: [String]?
        public var interpreters: [String]?
        
        
        public init(extensions: [String]? = nil, filenames: [String]? = nil, interpreters: [String]? = nil) {
            
            self.filenames = filenames
            self.extensions = extensions
            self.interpreters = interpreters
        }
    }
    
    
    public struct Highlight: Equatable, Sendable {
        
        public var begin: String
        public var end: String?
        public var isRegularExpression: Bool
        public var ignoreCase: Bool
        public var isMultiline: Bool
        public var description: String?
        
        public var isEmpty: Bool {
            
            self.begin.isEmpty && self.end?.isEmpty != false && self.description?.isEmpty != false
        }
        
        
        public init(begin: String = "", end: String? = nil, isRegularExpression: Bool = false, ignoreCase: Bool = false, isMultiline: Bool = false, description: String? = nil) {
            
            self.begin = begin
            self.end = end
            self.isRegularExpression = isRegularExpression
            self.ignoreCase = ignoreCase
            self.isMultiline = isMultiline
            self.description = description
        }
    }
    
    
    public struct Outline: Equatable, Sendable {
        
        public enum Kind: String, Sendable, CaseIterable, Codable {
            
            case container
            case function
            case value
            case heading
            case mark
            case reference
            case separator
        }
        
        
        public var pattern: String
        public var template: String
        public var ignoreCase: Bool
        public var kind: Kind?
        public var bold: Bool
        public var italic: Bool
        public var underline: Bool
        public var description: String?
        
        public var isEmpty: Bool {
            
            self.pattern.isEmpty && self.pattern.isEmpty && self.description?.isEmpty != false
        }
        
        
        public init(pattern: String = "", template: String = "", ignoreCase: Bool = false, kind: Kind? = nil, bold: Bool = false, italic: Bool = false, underline: Bool = false, description: String? = nil) {
            
            self.pattern = pattern
            self.template = template
            self.ignoreCase = ignoreCase
            self.kind = kind
            self.bold = bold
            self.italic = italic
            self.underline = underline
            self.description = description
        }
    }
    
    
    public struct Comment: Equatable, Sendable, Codable {
        
        public struct Inline: Equatable, Sendable {
            
            public var begin: String
            public var leadingOnly: Bool
            
            
            public init(begin: String = "", leadingOnly: Bool = false) {
                
                self.begin = begin
                self.leadingOnly = leadingOnly
            }
        }
        
        
        public var inlines: [Inline] = []
        public var blocks: [Pair<String>] = []
        
        public var isEmpty: Bool { self.blocks.isEmpty && self.inlines.isEmpty }
        
        
        public init(inlines: [Inline] = [], blocks: [Pair<String>] = []) {
            
            self.inlines = inlines
            self.blocks = blocks
        }
    }
    
    
    public struct CompletionWord: Equatable, Sendable, Codable {
        
        public var text: String
        public var type: SyntaxType?
        
        
        public init(text: String = "", type: SyntaxType? = nil) {
            
            self.text = text
            self.type = type
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
    public var fileMap: FileMap
    
    public var highlights: [SyntaxType: [Highlight]]
    public var outlines: [Outline]
    
    public var commentDelimiters: Comment
    public var completions: [CompletionWord]
    
    public var metadata: Metadata
    
    
    // MARK: Public Methods
    
    public init(
        kind: Kind = .general,
        fileMap: FileMap = .init(),
        highlights: [SyntaxType: [Highlight]] = [:],
        outlines: [Outline] = [],
        commentDelimiters: Comment = .init(),
        completions: [CompletionWord] = [],
        metadata: Metadata = .init()
    ) {
        
        self.kind = kind
        self.fileMap = fileMap
        self.highlights = highlights
        self.outlines = outlines
        self.commentDelimiters = commentDelimiters
        self.completions = completions
        self.metadata = metadata
    }
    
    
    /// Sorted and removed empty items for saving.
    public var sanitized: Self {
        
        var syntax = self
        
        syntax.fileMap.extensions?.removeAll(where: \.isEmpty)
        if syntax.fileMap.extensions?.isEmpty == true {
            syntax.fileMap.extensions = nil
        }
        syntax.fileMap.filenames?.removeAll(where: \.isEmpty)
        if syntax.fileMap.filenames?.isEmpty == true {
            syntax.fileMap.filenames = nil
        }
        syntax.fileMap.interpreters?.removeAll(where: \.isEmpty)
        if syntax.fileMap.interpreters?.isEmpty == true {
            syntax.fileMap.interpreters = nil
        }
        
        for type in SyntaxType.allCases {
            syntax.highlights[type]?.removeAll(where: \.isEmpty)
            syntax.highlights[type]?.caseInsensitiveSort(\.begin)
            if syntax.highlights[type]?.isEmpty == true {
                syntax.highlights[type] = nil
            }
        }
        syntax.outlines.removeAll(where: \.isEmpty)
        syntax.outlines.caseInsensitiveSort(\.pattern)
        
        syntax.commentDelimiters.inlines.removeAll(where: \.begin.isEmpty)
        syntax.commentDelimiters.blocks.removeAll(where: \.begin.isEmpty)
        syntax.commentDelimiters.blocks.removeAll(where: \.end.isEmpty)
        
        syntax.completions.removeAll(where: \.text.isEmpty)
        syntax.completions.caseInsensitiveSort(\.text)
        
        return syntax
    }
    
    
    /// The completion words.
    public var completionWords: [CompletionWord] {
        
        let completions = self.completions.filter { !$0.text.isEmpty }
        
        return if !completions.isEmpty {
            // from completion definition
            completions
        } else {
            // from normal highlighting words
            SyntaxType.allCases
                .flatMap { type -> [CompletionWord] in
                    guard let highlights = self.highlights[type] else { return [] }
                    
                    return highlights
                        .filter { $0.end == nil && !$0.isRegularExpression }
                        .map { $0.begin.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                        .map { CompletionWord(text: $0, type: type) }
                }
                .sorted(using: KeyPathComparator(\.text))
        }
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
