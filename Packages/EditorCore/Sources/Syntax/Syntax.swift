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
    public var completions: [String]
    
    public var metadata: Metadata
    
    
    // MARK: Public Methods
    
    public init(
        kind: Kind = .general,
        fileMap: FileMap = .init(),
        highlights: [SyntaxType: [Highlight]] = [:],
        outlines: [Outline] = [],
        commentDelimiters: Comment = .init(),
        completions: [String] = [],
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
        for type in SyntaxType.allCases {
            syntax.highlights[type]?.removeAll(where: \.isEmpty)
            syntax.highlights[type]?.caseInsensitiveSort(\.begin)
        }
        syntax.outlines.removeAll(where: \.isEmpty)
        syntax.outlines.caseInsensitiveSort(\.pattern)
        syntax.completions.removeAll(where: \.isEmpty)
        syntax.completions.caseInsensitiveSort(\.self)
        syntax.fileMap.extensions?.removeAll(where: \.isEmpty)
        syntax.fileMap.filenames?.removeAll(where: \.isEmpty)
        syntax.fileMap.interpreters?.removeAll(where: \.isEmpty)
        
        return syntax
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
                .flatMap { self.highlights[$0] ?? [] }
                .filter { $0.end == nil && !$0.isRegularExpression }
                .map { $0.begin.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .sorted()
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
