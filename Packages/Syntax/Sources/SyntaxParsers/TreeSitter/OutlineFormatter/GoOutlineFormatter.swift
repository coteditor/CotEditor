//
//  GoOutlineFormatter.swift
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

enum GoOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func title(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange) {
        
        switch capture.kind {
            case .function:
                return (title: Self.functionTitle(for: match, title: source.substring(with: capture.range), source: source),
                        range: Self.signatureRange(for: match, nameRange: capture.range))
            default:
                return Self.defaultTitle(capture: capture, source: source)
        }
    }
}


private extension GoOutlineFormatter {
    
    /// Builds the displayed Go function or method title from a query match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - title: The raw title capture text.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed Go function or method title.
    static func functionTitle(for match: QueryMatch, title: String, source: NSString) -> String {
        
        let typeParameters = Self.typeParametersRange(for: match)
            .map(source.substring(with:))
            .map(Self.normalizedClause)
            ?? ""
        let parameters = Self.parametersRange(for: match)
            .map(source.substring(with:))
            .map(Self.normalizedClause)
            ?? "()"
        
        if let receiver = Self.receiverNode(for: match),
           let receiverType = Self.receiverType(in: receiver, source: source)
        {
            return "\(Self.receiverPrefix(for: receiverType))\(title)\(typeParameters)\(parameters)"
        }
        
        return "\(title)\(typeParameters)\(parameters)"
    }
    
    
    /// Returns the signature range spanning the Go function name through its parameter list.
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
    
    
    /// Returns the type parameter list range for a Go function declaration.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The type parameter list range, or `nil` if none exists.
    private static func typeParametersRange(for match: QueryMatch) -> NSRange? {
        
        match.outlineNode?.parent?.child(byFieldName: "type_parameters")?.range
    }
    
    
    /// Returns the receiver parameter list node for a Go method declaration.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The receiver node, or `nil` if the match is not a method declaration.
    private static func receiverNode(for match: QueryMatch) -> Node? {
        
        guard let declaration = match.outlineNode?.parent,
              declaration.nodeType == "method_declaration"
        else {
            return nil
        }
        
        return declaration.child(byFieldName: "receiver")
    }
    
    
    /// Returns the displayed receiver type for a Go method receiver list.
    ///
    /// - Parameters:
    ///   - receiver: The receiver parameter list node.
    ///   - source: The source text as `NSString`.
    /// - Returns: The normalized receiver type, or `nil` when it cannot be resolved.
    private static func receiverType(in receiver: Node, source: NSString) -> String? {
        
        guard
            let declaration = receiver.namedChild(at: 0),
            let type = declaration.child(byFieldName: "type")
        else { return nil }
        
        return Self.normalizedType(source.substring(with: type.range))
    }
    
    
    /// Returns the title prefix used for a Go method receiver type.
    ///
    /// - Parameter receiverType: The normalized receiver type.
    /// - Returns: The receiver prefix for the displayed title.
    private static func receiverPrefix(for receiverType: String) -> String {
        
        receiverType.hasPrefix("*")
            ? "(\(receiverType))."
            : "\(receiverType)."
    }
    
    
    /// Returns a whitespace-normalized Go signature clause.
    ///
    /// - Parameter clause: The raw clause text.
    /// - Returns: The clause with normalized spacing.
    private static func normalizedClause(_ clause: String) -> String {
        
        clause
            .replacing(/\s+/, with: " ")
            .replacing(/\(\s+/, with: "(")
            .replacing(/\[\s+/, with: "[")
            .replacing(/\s+\)/, with: ")")
            .replacing(/\s+\]/, with: "]")
            .replacing(/\s*,\s*/, with: ", ")
    }
    
    
    /// Returns whitespace-normalized Go type text.
    ///
    /// - Parameter type: The raw type text.
    /// - Returns: The type with normalized spacing.
    private static func normalizedType(_ type: String) -> String {
        
        type
            .replacing(/\s+/, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
