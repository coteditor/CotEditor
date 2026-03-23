//
//  PythonOutlineFormatter.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-23.
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
import SwiftTreeSitter

enum PythonOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func functionSignature(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange) {
        
        (title: Self.functionTitle(for: match, title: source.substring(with: capture.range), source: source),
         range: Self.signatureRange(for: match, nameRange: capture.range))
    }
}


private extension PythonOutlineFormatter {
    
    /// Builds the displayed Python function title from a query match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - title: The raw title capture text.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed Python function title.
    static func functionTitle(for match: QueryMatch, title: String, source: NSString) -> String {
        
        let parametersRange = match.captures(named: "outline.signature.parameters").first?.range
        let parameters = parametersRange
            .map(source.substring(with:))
            .map(Self.normalizedClause)
            ?? "()"
        
        return title + parameters
    }
    
    
    /// Returns the signature range spanning the Python function name through its parameter list.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - nameRange: The captured function name range.
    /// - Returns: The signature range.
    static func signatureRange(for match: QueryMatch, nameRange: NSRange) -> NSRange {
        
        nameRange.union(with: [match.captures(named: "outline.signature.parameters").first?.range])
    }
    
    
    /// Returns a whitespace-normalized Python parameter clause.
    ///
    /// - Parameter clause: The raw parameter clause text.
    /// - Returns: The clause with normalized spacing.
    private static func normalizedClause(_ clause: String) -> String {
        
        clause
            .replacing(/\s+/, with: " ")
            .replacing(/\(\s+/, with: "(")
            .replacing(/\s+\)/, with: ")")
            .replacing(/\s*,\s*/, with: ", ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
