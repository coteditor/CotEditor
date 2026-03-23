//
//  ScalaOutlineFormatter.swift
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

enum ScalaOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func functionSignature(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange) {
        
        (title: Self.functionTitle(for: match, title: source.substring(with: capture.range), source: source),
         range: match.range ?? capture.range)
    }
}


private extension ScalaOutlineFormatter {
    
    /// Builds the displayed Scala function title from a query match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - title: The raw title capture text.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed Scala function title.
    static func functionTitle(for match: QueryMatch, title: String, source: NSString) -> String {
        
        let clauses = match.captures(named: "outline.signature.parameters")
            .map { Self.parametersClause(for: $0.node, source: source) }
        
        return title + clauses.joined()
    }
    
    
    /// Builds the displayed parameter-clause suffix for a Scala parameters node.
    ///
    /// - Parameters:
    ///   - parameters: The Scala parameters node.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed parameter-clause suffix.
    private static func parametersClause(for parameters: Node, source: NSString) -> String {
        
        let clause = Self.normalizedClause(source.substring(with: parameters.range))
        let names = Self.parameterNames(in: parameters, source: source)
        
        guard !names.isEmpty else { return clause }
        
        if clause.hasPrefix("(using ") {
            return "(using \(names.joined(separator: ", ")))"
        }
        if clause.hasPrefix("(implicit ") {
            return "(implicit \(names.joined(separator: ", ")))"
        }
        
        return "(\(names.joined(separator: ", ")))"
    }
    
    
    /// Returns the displayed parameter names for a Scala parameter clause.
    ///
    /// - Parameters:
    ///   - parameters: The Scala parameters node.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed parameter names in source order.
    private static func parameterNames(in parameters: Node, source: NSString) -> [String] {
        
        (0..<parameters.namedChildCount)
            .compactMap(parameters.namedChild(at:))
            .filter { $0.nodeType == "parameter" }
            .compactMap { parameter in
                parameter.child(byFieldName: "name").map { source.substring(with: $0.range) }
            }
    }
    
    
    /// Returns a whitespace-normalized Scala parameter clause.
    ///
    /// - Parameter clause: The raw parameter clause text.
    /// - Returns: The clause with normalized spacing.
    private static func normalizedClause(_ clause: String) -> String {
        
        clause
            .replacing(/\s+/, with: " ")
            .replacing(/\(\s+/, with: "(")
            .replacing(/\s+\)/, with: ")")
            .replacing(/\s*,\s*/, with: ", ")
    }
}
