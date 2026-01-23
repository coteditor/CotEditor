//
//  RegexParser.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

final class RegexParser: SyntaxParsing, Sendable {
    
    struct HighlightRuleSet {
        
        var extractors: [SyntaxType: [any HighlightExtractable]]
        var nestables: [NestableToken: SyntaxType]
        
        var isEmpty: Bool { self.extractors.isEmpty && self.nestables.isEmpty }
    }
    
    
    // MARK: Private Properties
    
    private let outlineExtractors: [OutlineExtractor]
    private let highlightRuleSet: HighlightRuleSet
    
    
    // MARK: Lifecycle
    
    init(outlineExtractors: [OutlineExtractor], highlightRuleSet: HighlightRuleSet) {
        
        self.outlineExtractors = outlineExtractors
        self.highlightRuleSet = highlightRuleSet
    }
    
    
    // MARK: Public Methods
    
    /// Indicates whether any outline extraction rules are available.
    var hasOutlineRules: Bool {
        
        !self.outlineExtractors.isEmpty
    }
    
    
    /// Indicates whether any syntax highlighting rules are available.
    var hasHighlightRules: Bool {
        
        !self.highlightRuleSet.isEmpty
    }
    
    
    /// Parses and returns outline items from the given source string using all configured outline extractors.
    ///
    /// - Parameters:
    ///   - string: The full source text to analyze.
    /// - Returns: An array of `OutlineItem`.
    /// - Throws: `CancellationError`.
    @concurrent func parseOutline(in string: String) async throws -> [OutlineItem] {
        
        try await withThrowingTaskGroup { [extractors = self.outlineExtractors] group in
            for extractor in extractors {
                group.addTask { try extractor.items(in: string, range: string.range) }
            }
            
            return try await group.reduce(into: []) { $0 += $1 }
                .sorted(using: KeyPathComparator(\.range.location))
        }
    }
    
    
    /// Parses and returns syntax highlighting for a substring of the given source string.
    ///
    /// - Parameters:
    ///   - string: The full source text to analyze.
    ///   - range: The range where to parse.
    /// - Returns: A dictionary of ranges to highlight per syntax types.
    /// - Throws: `CancellationError`.
    @concurrent func parseHighlights(in string: String, range: NSRange) async throws -> [Highlight] {
        
        try await withThrowingTaskGroup { [ruleSet = self.highlightRuleSet] group in
            group.addTask { try ruleSet.nestables.parseHighlights(in: string, range: range) }
            
            for (type, extractors) in ruleSet.extractors {
                for extractor in extractors {
                    group.addTask { [type: try extractor.ranges(in: string, range: range)] }
                }
            }
            
            let dictionary = try await group.reduce(into: [SyntaxType: [NSRange]]()) {
                $0.merge($1, uniquingKeysWith: +)
            }
            
            return try Highlight.highlights(dictionary: dictionary)
        }
    }
}
