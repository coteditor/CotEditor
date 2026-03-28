//
//  TypeScriptOutlineFormatter.swift
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

enum TypeScriptOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func functionSignature(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange) {
        
        let range = Self.signatureRange(for: match, nameRange: capture.range)
        let title = Self.normalizedClause(source.substring(with: range))
        
        return (title, range)
    }
}


private extension TypeScriptOutlineFormatter {
    
    /// Returns the signature range spanning the TypeScript function name through its parameter list.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - nameRange: The captured function or method name range.
    /// - Returns: The signature range.
    static func signatureRange(for match: QueryMatch, nameRange: NSRange) -> NSRange {
        
        nameRange.union(with: [
            Self.typeParametersRange(for: match),
            Self.parametersRange(for: match),
        ])
    }
    
    
    /// Returns the type parameter list range for a TypeScript function-like declaration.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The type parameter list range, or `nil` if none exists.
    private static func typeParametersRange(for match: QueryMatch) -> NSRange? {
        
        match.outlineNode?.parent?.child(byFieldName: "type_parameters")?.range
    }
    
    
    /// Returns a whitespace-normalized TypeScript signature clause.
    ///
    /// - Parameter clause: The raw signature text.
    /// - Returns: The clause with normalized spacing.
    private static func normalizedClause(_ clause: String) -> String {
        
        clause
            .replacing(/\s+/, with: " ")
            .replacing(/\(\s+/, with: "(")
            .replacing(/\s+\)/, with: ")")
            .replacing(/\s+\(/, with: "(")
            .replacing(/\s+</, with: "<")
            .replacing(/<\s+/, with: "<")
            .replacing(/\s+>/, with: ">")
            .replacing(/\s*,\s*/, with: ", ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
