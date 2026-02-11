//
//  RegexHighlightParser.swift
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

actor RegexHighlightParser: HighlightParsing {
    
    // MARK: Internal Properties
    
    nonisolated let needsHighlightBuffer: Bool = true
    
    
    // MARK: Private Properties
    
    private let extractors: [SyntaxType: [any HighlightExtractable]]
    private let nestables: [NestableToken: SyntaxType]
    
    
    // MARK: Lifecycle
    
    init(extractors: [SyntaxType: [any HighlightExtractable]], nestables: [NestableToken: SyntaxType]) {
        
        self.extractors = extractors
        self.nestables = nestables
    }
    
    
    // MARK: HighlightParsing Methods
    
    /// Updates the entire content and resets the parser state.
    func update(content: String) {
        
        // do nothing
    }
    
    
    /// Notifies the parser about a text edit so it can update its incremental parse state.
    func noteEdit(editedRange: NSRange, delta: Int, insertedText: String) throws {
        
        // do nothing
    }
    
    
    /// Parses and returns syntax highlighting for a substring of the given source string.
    ///
    /// - Parameters:
    ///   - string: The full source text to analyze.
    ///   - range: The requested range to update.
    /// - Returns: The highlights and the range that should be updated, or `nil` if nothing needs updating.
    /// - Throws: `CancellationError`.
    func parseHighlights(in string: String, range: NSRange) async throws -> (highlights: [Highlight], updateRange: NSRange)? {
        
        try await withThrowingTaskGroup { [extractors, nestables] group in
            group.addTask { try nestables.parseHighlights(in: string, range: range) }
            
            for (type, extractors) in extractors {
                for extractor in extractors {
                    group.addTask { [type: try extractor.ranges(in: string, range: range)] }
                }
            }
            
            let dictionary = try await group.reduce(into: [SyntaxType: [NSRange]]()) {
                $0.merge($1, uniquingKeysWith: +)
            }
            
            let highlights = try Highlight.highlights(dictionary: dictionary)
            
            return (highlights, range)
        }
    }
}
