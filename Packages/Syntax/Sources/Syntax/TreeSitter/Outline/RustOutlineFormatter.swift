//
//  RustOutlineFormatter.swift
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

enum RustOutlineFormatter: TreeSitterOutlineFormatting {
    
    /// Builds an outline item from a resolved Rust outline match.
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
        
        let title = source.substring(with: capture.range)
        let formattedTitle = Self.functionTitle(for: match, title: title, source: source)
        
        guard let displayTitle = Self.formatTitle(formattedTitle, kind: capture.kind) else { return nil }
        
        return OutlineItem(title: displayTitle,
                           range: Self.signatureRange(for: match, nameRange: capture.range),
                           kind: capture.kind,
                           indent: .level(capture.depth))
    }
}


private extension RustOutlineFormatter {
    
    /// Builds the displayed Rust function title from a query match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - title: The raw title capture text.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed Rust function title.
    static func functionTitle(for match: QueryMatch, title: String, source: NSString) -> String {
        
        let typeParameters = Self.typeParametersRange(for: match)
            .map(source.substring(with:))
            .map(Self.normalizedClause)
            ?? ""
        let parameters = match.captures(named: "outline.signature.parameters")
            .first.map(\.range)
            .map(source.substring(with:))
            .map(Self.normalizedClause)
            ?? "()"
        
        return "\(title)\(typeParameters)\(parameters)"
    }
    
    
    /// Returns the signature range spanning the Rust function name through its parameter list.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - nameRange: The captured function name range.
    /// - Returns: The signature range.
    static func signatureRange(for match: QueryMatch, nameRange: NSRange) -> NSRange {
        
        [Self.typeParametersRange(for: match),
         match.captures(named: "outline.signature.parameters").first?.range]
            .compactMap(\.self)
            .reduce(nameRange) { $0.union($1) }
    }
    
    
    /// Returns the type parameter list range for a Rust function item.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The type parameter list range, or `nil` if none exists.
    private static func typeParametersRange(for match: QueryMatch) -> NSRange? {
        
        guard let nameNode = match.captures.first(where: { $0.nameComponents.first == "outline" })?.node else {
            return nil
        }
        
        return nameNode.parent?.child(byFieldName: "type_parameters")?.range
    }
    
    
    /// Returns a whitespace-normalized Rust signature clause.
    ///
    /// - Parameter clause: The raw clause text.
    /// - Returns: The clause with normalized spacing.
    private static func normalizedClause(_ clause: String) -> String {
        
        clause
            .replacing(/\s+/, with: " ")
            .replacing(/\(\s+/, with: "(")
            .replacing(/\[\s+/, with: "[")
            .replacing(/<\s+/, with: "<")
            .replacing(/\s+\)/, with: ")")
            .replacing(/\s+\]/, with: "]")
            .replacing(/\s+>/, with: ">")
            .replacing(/\s*,\s*/, with: ", ")
    }
}
