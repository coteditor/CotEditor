//
//  SwiftOutlineFormatter.swift
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
import SwiftTreeSitter

enum SwiftOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func title(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange)? {
        
        switch capture.kind {
            case .value:
                return Self.propertyName(for: match, source: source)
                    ?? Self.defaultTitle(capture: capture, source: source)
            case .function:
                let title = source.substring(with: capture.range)
                return (title: Self.functionTitle(for: match, title: title, source: source),
                        range: match.range ?? capture.range)
            default:
                return Self.defaultTitle(capture: capture, source: source)
        }
    }
    
    
    /// Formats a Swift outline title with comment marker handling.
    static func formatTitle(_ title: String, kind: Syntax.Outline.Kind) -> String? {

        guard kind == .mark else { return title }

        let comment = Self.commentContent(in: title)
            .replacing(/^MARK:\s*-?\s*/, with: "")

        return comment.isEmpty ? nil : comment
    }
}


private extension SwiftOutlineFormatter {
    
    /// Returns the title text with surrounding comment delimiters removed.
    static func commentContent(in title: String) -> String {
        
        if let match = title.wholeMatch(of: /\/\/\s*(.+)/) {  // inline comment
            String(match.output.1).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let match = title.wholeMatch(of: /\/\*+\s*(.+)\s*\*\//) {  // block comment
            String(match.output.1).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            title
        }
    }
    
    
    /// Returns the property name capture used for Swift outline items.
    static func propertyName(for match: QueryMatch, source: NSString) -> (title: String, range: NSRange)? {
        
        match.captures
            .first { $0.name == "outline.name" }
            .map { (title: source.substring(with: $0.range), range: $0.range) }
    }
    
    
    /// Builds the displayed Swift function title from a query match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - title: The raw title capture text.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed Swift function title.
    static func functionTitle(for match: QueryMatch, title: String, source: NSString) -> String {
        
        if title == "deinit" {
            return "deinit"
        }
        
        let signatureText = match.range.map(source.substring(with:)) ?? title
        let baseName = (title == "init")
            ? Self.initializerBaseName(in: signatureText) ?? title
            : title
        let labels = match.captures(named: "outline.signature.parameter")
            .compactMap { Self.parameterLabel(for: $0.node, source: source) }
        
        return labels.isEmpty
            ? "\(baseName)()"
            : "\(baseName)(\(labels.map { "\($0):" }.joined()))"
    }
    
    
    /// Returns the display base name for a Swift initializer signature.
    ///
    /// - Parameter signatureText: The signature text spanning the initializer name through the closing parenthesis.
    /// - Returns: The initializer display name, if it can be derived.
    private static func initializerBaseName(in signatureText: String) -> String? {
        
        signatureText.firstMatch(of: /^init[!?]?/).map { String($0.output) }
    }
    
    
    /// Returns the call-site label represented by a Swift parameter node.
    ///
    /// - Parameters:
    ///   - parameter: The Swift parameter node.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed call-site label, or `nil` when it cannot be resolved.
    private static func parameterLabel(for parameter: Node, source: NSString) -> String? {
        
        let labelNode = parameter.child(byFieldName: "external_name") ?? parameter.child(byFieldName: "name")
        
        return labelNode.map { source.substring(with: $0.range) }
    }
}
