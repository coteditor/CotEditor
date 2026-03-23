//
//  CPPOutlineFormatter.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-24.
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

enum CPPOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func functionSignature(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange) {
        
        let node = match.outlineNode
        let title = node.flatMap { Self.functionTitle(for: $0, source: source) } ?? source.substring(with: capture.range)
        let range = node.flatMap(Self.signatureRange(in:)) ?? capture.range
        
        return (title, range)
    }
}


private extension CPPOutlineFormatter {
    
    /// Builds the displayed C++ function title from a declarator node.
    ///
    /// - Parameters:
    ///   - declarator: The captured top-level declarator node.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed C++ function title.
    static func functionTitle(for declarator: Node, source: NSString) -> String? {
        
        guard
            let functionDeclarator = Self.functionDeclarator(in: declarator),
            let name = Self.functionName(in: functionDeclarator, source: source),
            let parameters = functionDeclarator.child(byFieldName: "parameters")
        else { return nil }
        
        let parameterList = Self.normalizedClause(source.substring(with: parameters.range))
        
        return name + parameterList
    }
    
    
    /// Returns the signature range spanning the C++ function name through its parameter list.
    ///
    /// - Parameter declarator: The captured top-level declarator node.
    /// - Returns: The signature range, or `nil` if it cannot be derived.
    static func signatureRange(in declarator: Node) -> NSRange? {
        
        guard
            let functionDeclarator = Self.functionDeclarator(in: declarator),
            let nameNode = Self.functionNameNode(in: functionDeclarator),
            let parameters = functionDeclarator.child(byFieldName: "parameters")
        else { return nil }
        
        return nameNode.range.union(parameters.range)
    }
    
    
    /// Returns the innermost function declarator for a C++ declarator tree.
    ///
    /// - Parameter declarator: The declarator node to inspect.
    /// - Returns: The function declarator, or `nil` if none exists.
    static func functionDeclarator(in declarator: Node) -> Node? {
        
        if declarator.nodeType == "function_declarator" {
            return declarator
        }
        if let child = declarator.child(byFieldName: "declarator") {
            return Self.functionDeclarator(in: child)
        }
        
        return nil
    }
    
    
    /// Returns the display name string for a C++ function.
    ///
    /// Handles plain identifiers, field identifiers, qualified identifiers,
    /// operator overloads, and destructors.
    ///
    /// - Parameters:
    ///   - functionDeclarator: The function declarator to inspect.
    ///   - source: The source text as `NSString`.
    /// - Returns: The function name string, or `nil` if it cannot be resolved.
    static func functionName(in functionDeclarator: Node, source: NSString) -> String? {
        
        guard let nameNode = Self.functionNameNode(in: functionDeclarator) else { return nil }
        
        return source.substring(with: nameNode.range)
    }
    
    
    /// Returns the node representing the C++ function name.
    ///
    /// - Parameter functionDeclarator: The function declarator to inspect.
    /// - Returns: The name node, or `nil` if it cannot be resolved.
    static func functionNameNode(in functionDeclarator: Node) -> Node? {
        
        guard let child = functionDeclarator.child(byFieldName: "declarator") else { return nil }
        
        switch child.nodeType {
            case "identifier",
                 "field_identifier",
                 "qualified_identifier",
                 "operator_name",
                 "destructor_name":
                return child
            default:
                // fall through to recursive search for nested declarators
                return Self.functionNameNode(in: child)
        }
    }
    
    
    /// Returns a whitespace-normalized C++ parameter clause.
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
