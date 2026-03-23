//
//  RubyOutlineFormatter.swift
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

enum RubyOutlineFormatter: TreeSitterOutlineFormatting {
    
    /// Builds an outline item from a resolved Ruby outline match.
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
        
        let title = Self.functionTitle(for: match, title: source.substring(with: capture.range), source: source)
        guard let displayTitle = Self.formatTitle(title, kind: capture.kind) else { return nil }
        
        return OutlineItem(title: displayTitle,
                           range: Self.signatureRange(for: match, nameRange: capture.range),
                           kind: capture.kind,
                           indent: .level(capture.depth))
    }
}


private extension RubyOutlineFormatter {
    
    /// Builds the displayed Ruby method title from a query match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - title: The raw title capture text.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed Ruby method title.
    static func functionTitle(for match: QueryMatch, title: String, source: NSString) -> String {
        
        let receiver = Self.receiverPrefix(for: match, source: source) ?? ""
        let parameters = Self.parametersRange(for: match)
            .map(source.substring(with:))
            .map(Self.normalizedParameters)
            ?? "()"
        
        return receiver + title + parameters
    }
    
    
    /// Returns the signature range spanning the Ruby method name and parameter clause.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - nameRange: The captured method name range.
    /// - Returns: The signature range.
    static func signatureRange(for match: QueryMatch, nameRange: NSRange) -> NSRange {
        
        [Self.receiverRange(for: match),
         Self.parametersRange(for: match)]
            .compactMap(\.self)
            .reduce(nameRange) { $0.union($1) }
    }
    
    
    /// Returns the receiver prefix for a Ruby singleton method.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - source: The source text as `NSString`.
    /// - Returns: The receiver prefix ending in `.`, or `nil` for instance methods.
    private static func receiverPrefix(for match: QueryMatch, source: NSString) -> String? {
        
        Self.receiverRange(for: match).map { source.substring(with: $0) + "." }
    }
    
    
    /// Returns the receiver range for a Ruby singleton method.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The receiver range, or `nil` for instance methods.
    private static func receiverRange(for match: QueryMatch) -> NSRange? {
        
        Self.declarationNode(for: match)?.child(byFieldName: "object")?.range
    }
    
    
    /// Returns the parameters range for a Ruby method declaration.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The parameters range, or `nil` if omitted.
    private static func parametersRange(for match: QueryMatch) -> NSRange? {
        
        Self.declarationNode(for: match)?.child(byFieldName: "parameters")?.range
    }
    
    
    /// Returns the parent declaration node for the current outline match.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The declaration node, or `nil` if it cannot be resolved.
    private static func declarationNode(for match: QueryMatch) -> Node? {
        
        match.captures.first { $0.nameComponents.first == "outline" }?.node.parent
    }
    
    
    /// Returns a normalized Ruby parameter clause suitable for outline display.
    ///
    /// - Parameter parameters: The raw parameter clause text.
    /// - Returns: The normalized Ruby parameter clause.
    private static func normalizedParameters(_ parameters: String) -> String {
        
        let normalized = parameters
            .replacing(/\s+/, with: " ")
            .replacing(/\(\s+/, with: "(")
            .replacing(/\s+\)/, with: ")")
            .replacing(/\s*,\s*/, with: ", ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !normalized.isEmpty else { return "()" }
        guard !normalized.hasPrefix("(") else { return normalized }
        
        return "(\(normalized))"
    }
}
