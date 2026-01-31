//
//  SyntaxParsing.swift
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

public import Foundation
public import ValueRange

public typealias Highlight = ValueRange<SyntaxType>


public protocol HighlightParsing: Actor {
    
    nonisolated var needsHighlightBuffer: Bool { get }
    
    
    /// Parses and returns syntax highlighting for a substring of the given source string.
    ///
    /// - Parameters:
    ///   - string: The full source text to analyze.
    ///   - range: The range where to parse.
    /// - Returns: A dictionary of ranges to highlight per syntax types.
    /// - Throws: `CancellationError`.
    func parseHighlights(in string: String, range: NSRange) async throws -> [Highlight]
}


public protocol OutlineParsing: Actor {
    
    /// Parses and returns outline items from the given source string using all configured outline extractors.
    ///
    /// - Parameters:
    ///   - string: The full source text to analyze.
    /// - Returns: An array of `OutlineItem`.
    /// - Throws: `CancellationError`.
    func parseOutline(in string: String) async throws -> [OutlineItem]
}
