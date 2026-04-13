//
//  CSharpOutlineFormatter.swift
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
import SyntaxFormat
import StringUtils
import SwiftTreeSitter

enum CSharpOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func title(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange)? {
        
        switch capture.kind {
            case .value:
                let range = capture.range.union(with: [Self.explicitInterfaceRange(for: match)])
                let title = Self.normalizedSignature(source.substring(with: range))
                return (title, range)
            case .function:
                let range = Self.signatureRange(for: match, source: source, nameRange: capture.range)
                let title = Self.normalizedSignature(source.substring(with: range))
                return (title, range)
            default:
                return Self.defaultTitle(capture: capture, source: source)
        }
    }
}


private extension CSharpOutlineFormatter {
    
    /// Returns the signature range spanning the C# method name through its parameter list.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - source: The source text as `NSString`.
    ///   - nameRange: The captured function name range.
    /// - Returns: The signature range.
    static func signatureRange(for match: QueryMatch, source: NSString, nameRange: NSRange) -> NSRange {
        
        let adjustedNameRange = Self.adjustedNameRange(for: match, source: source, nameRange: nameRange)
        
        return adjustedNameRange.union(with: [
            Self.explicitInterfaceRange(for: match),
            Self.typeParametersRange(for: match),
            Self.parametersRange(for: match),
        ])
    }
    
    
    /// Returns the name range adjusted for C# destructor syntax.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - source: The source text as `NSString`.
    ///   - nameRange: The captured function name range.
    /// - Returns: The adjusted name range.
    private static func adjustedNameRange(for match: QueryMatch, source: NSString, nameRange: NSRange) -> NSRange {
        
        guard
            match.outlineNode?.parent?.nodeType == "destructor_declaration",
            nameRange.location > 0,
            source.substring(with: NSRange(location: nameRange.location - 1, length: 1)) == "~"
        else {
            return nameRange
        }
        
        return NSRange(location: nameRange.location - 1, length: nameRange.length + 1)
    }
    
    
    /// Returns the explicit interface specifier range for a C# member declaration.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The explicit interface specifier range, or `nil` if none exists.
    private static func explicitInterfaceRange(for match: QueryMatch) -> NSRange? {
        
        guard let declaration = match.outlineNode?.parent else { return nil }
        
        return (0..<declaration.namedChildCount)
            .compactMap(declaration.namedChild(at:))
            .first { $0.nodeType == "explicit_interface_specifier" }?
            .range
    }
    
    
    /// Returns the type parameter list range for a C# function-like declaration.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The type parameter list range, or `nil` if none exists.
    private static func typeParametersRange(for match: QueryMatch) -> NSRange? {
        
        match.outlineNode?.parent?.child(byFieldName: "type_parameters")?.range
    }
    
    
    /// Returns a whitespace-normalized C# signature text.
    ///
    /// - Parameter signature: The raw signature text.
    /// - Returns: The signature with normalized spacing.
    private static func normalizedSignature(_ signature: String) -> String {
        
        signature
            .replacing(/\s+/, with: " ")
            .replacing(/\(\s+/, with: "(")
            .replacing(/\s+\)/, with: ")")
            .replacing(/\s+\(/, with: "(")
            .replacing(/\s+</, with: "<")
            .replacing(/<\s+/, with: "<")
            .replacing(/\s+>/, with: ">")
            .replacing(/\.\s+/, with: ".")
            .replacing(/\s*,\s*/, with: ", ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
