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
import SyntaxFormat
import SwiftTreeSitter

enum CPPOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func title(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange)? {
        
        switch capture.kind {
            case .function:
                guard
                    let node = match.outlineNode,
                    let resolved = Self.resolvedSignature(for: node, source: source)
                else { return Self.defaultTitle(capture: capture, source: source) }
                
                return resolved
            default:
                return Self.defaultTitle(capture: capture, source: source)
        }
    }
}


private extension CPPOutlineFormatter {
    
    /// Resolves the display title and signature range for a C++ function declarator in a single tree traversal.
    ///
    /// - Parameters:
    ///   - declarator: The captured top-level declarator node.
    ///   - source: The source text as `NSString`.
    /// - Returns: The display title and signature range, or `nil` if the node is not a function declarator.
    static func resolvedSignature(for declarator: Node, source: NSString) -> (title: String, range: NSRange)? {
        
        guard
            let functionDeclarator = Self.functionDeclarator(in: declarator),
            let nameNode = Self.functionNameNode(in: functionDeclarator),
            let parameters = functionDeclarator.child(byFieldName: "parameters")
        else { return nil }
        
        let parameterList = Self.normalizedClause(source.substring(with: parameters.range))
        let title = source.substring(with: nameNode.range) + parameterList
        let range = nameNode.range.union(parameters.range)
        
        return (title, range)
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
