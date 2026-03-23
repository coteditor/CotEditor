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
import SwiftTreeSitter

enum CSharpOutlineFormatter: TreeSitterOutlineFormatting {
    
    /// Builds an outline item from a resolved C# outline match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - source: The source text as `NSString`.
    ///   - policy: The outline policy for the syntax.
    /// - Returns: An outline item for the match, or `nil` if the match should be ignored.
    static func item(for match: QueryMatch, source: NSString, policy: OutlinePolicy) -> OutlineItem? {
        
        guard let capture = match.outlineCapture(policy: policy) else { return nil }
        
        guard capture.kind == .function else {
            return Self.defaultItem(for: match, source: source, policy: policy)
        }
        
        let range = Self.signatureRange(for: match, source: source, nameRange: capture.range)
        let title = Self.normalizedSignature(source.substring(with: range))
        
        guard let displayTitle = Self.formatTitle(title, kind: capture.kind) else { return nil }
        
        return OutlineItem(title: displayTitle,
                           range: range,
                           kind: capture.kind,
                           indent: .level(capture.depth))
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
        
        return [
            Self.explicitInterfaceRange(for: match),
            Self.typeParametersRange(for: match),
            match.captures(named: "outline.signature.parameters").first?.range,
        ]
        .compactMap(\.self)
        .reduce(adjustedNameRange) { $0.union($1) }
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
            Self.declarationNode(for: match)?.nodeType == "destructor_declaration",
            nameRange.location > 0,
            source.substring(with: NSRange(location: nameRange.location - 1, length: 1)) == "~"
        else {
            return nameRange
        }
        
        return NSRange(location: nameRange.location - 1, length: nameRange.length + 1)
    }
    
    
    /// Returns the explicit interface specifier range for a C# method declaration.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The explicit interface specifier range, or `nil` if none exists.
    private static func explicitInterfaceRange(for match: QueryMatch) -> NSRange? {
        
        guard let declaration = Self.declarationNode(for: match) else { return nil }
        
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
        
        Self.declarationNode(for: match)?.child(byFieldName: "type_parameters")?.range
    }
    
    
    /// Returns the parent declaration node for the current outline match.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The declaration node, or `nil` if it cannot be resolved.
    private static func declarationNode(for match: QueryMatch) -> Node? {
        
        match.captures.first { $0.nameComponents.first == "outline" }?.node.parent
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
