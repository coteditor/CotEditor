//
//  COutlineFormatter.swift
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

enum COutlineFormatter: TreeSitterOutlineFormatting {
    
    /// Builds an outline item from a resolved C outline match.
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
        
        let node = match.captures.first { $0.range == capture.range }?.node
        let formattedTitle = node.flatMap { Self.functionTitle(for: $0, source: source) }
            ?? source.substring(with: capture.range)
        
        guard let displayTitle = Self.formatTitle(formattedTitle, kind: capture.kind) else { return nil }
        
        let range = node.flatMap(Self.functionSignatureRange(in:)) ?? capture.range
        
        return OutlineItem(title: displayTitle, range: range, kind: capture.kind, indent: .level(capture.depth))
    }
}


private extension COutlineFormatter {
    
    /// Builds the displayed C function title from a declarator node.
    ///
    /// - Parameters:
    ///   - declarator: The captured top-level declarator node.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed C function title.
    static func functionTitle(for declarator: Node, source: NSString) -> String? {
        
        guard
            let functionDeclarator = Self.functionDeclarator(in: declarator),
            let name = Self.functionName(in: functionDeclarator),
            let parameters = functionDeclarator.child(byFieldName: "parameters")
        else { return nil }
        
        let parameterList = source.substring(with: parameters.range)
            .replacing(/\s+/, with: " ")
        
        return source.substring(with: name.range) + parameterList
    }
    
    
    /// Returns the signature range spanning the function name through its parameter list.
    ///
    /// - Parameter declarator: The captured top-level declarator node.
    /// - Returns: The signature range, or `nil` if it cannot be derived.
    private static func functionSignatureRange(in declarator: Node) -> NSRange? {
        
        guard
            let functionDeclarator = Self.functionDeclarator(in: declarator),
            let name = Self.functionName(in: functionDeclarator),
            let parameters = functionDeclarator.child(byFieldName: "parameters")
        else { return nil }
        
        return name.range.union(parameters.range)
    }
    
    
    /// Returns the innermost function declarator for a C declarator tree.
    ///
    /// - Parameter declarator: The declarator node to inspect.
    /// - Returns: The function declarator, or `nil` if none exists.
    private static func functionDeclarator(in declarator: Node) -> Node? {
        
        if declarator.nodeType == "function_declarator" {
            return declarator
        }
        if let child = declarator.child(byFieldName: "declarator") {
            return Self.functionDeclarator(in: child)
        }
        
        return nil
    }
    
    
    /// Returns the identifier node representing the C function name.
    ///
    /// - Parameter declarator: The function declarator to inspect.
    /// - Returns: The function name node, or `nil` if it cannot be resolved.
    private static func functionName(in declarator: Node) -> Node? {
        
        guard let child = declarator.child(byFieldName: "declarator") else { return nil }
        
        return Self.identifier(in: child)
    }
    
    
    /// Returns the identifier node contained in a nested C declarator tree.
    ///
    /// - Parameter declarator: The declarator node to inspect.
    /// - Returns: The identifier node, or `nil` if it cannot be resolved.
    private static func identifier(in declarator: Node) -> Node? {
        
        if declarator.nodeType == "identifier" {
            return declarator
        }
        if let child = declarator.child(byFieldName: "declarator") {
            return Self.identifier(in: child)
        }
        
        for index in 0..<declarator.namedChildCount {
            if let child = declarator.namedChild(at: index), let identifier = Self.identifier(in: child) {
                return identifier
            }
        }
        
        return nil
    }
}
