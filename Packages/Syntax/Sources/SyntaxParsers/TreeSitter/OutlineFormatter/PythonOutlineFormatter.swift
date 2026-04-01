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
import SyntaxFormat
import StringUtils
import SwiftTreeSitter

enum PythonOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func title(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange)? {
        
        switch capture.kind {
            case .value:
                guard Self.isClassVariable(match: match) else { return nil }
                
                return Self.defaultTitle(capture: capture, source: source)
            case .function:
                return (title: Self.functionTitle(for: match, title: source.substring(with: capture.range), source: source),
                        range: Self.signatureRange(for: match, nameRange: capture.range))
            default:
                return Self.defaultTitle(capture: capture, source: source)
        }
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
        
        let parameters = Self.parametersRange(for: match)
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
        
        nameRange.union(with: [Self.parametersRange(for: match)])
    }
    
    
    /// Returns whether the capture belongs to a direct class-body variable assignment.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: `true` when the assignment lives directly in a class body.
    private static func isClassVariable(match: QueryMatch) -> Bool {
        
        guard
            let assignment = Self.ancestor(ofType: "assignment", from: match.outlineNode),
            let block = Self.ancestor(ofType: "block", from: assignment),
            block.parent?.nodeType == "class_definition"
        else { return false }
        
        return true
    }
    
    
    /// Returns the nearest ancestor with the given node type.
    ///
    /// - Parameters:
    ///   - nodeType: The desired ancestor node type.
    ///   - node: The starting node.
    /// - Returns: The first matching ancestor, or `nil`.
    private static func ancestor(ofType nodeType: String, from node: Node?) -> Node? {
        
        guard let node else { return nil }
        
        return sequence(first: node, next: \.parent).first { $0.nodeType == nodeType }
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
