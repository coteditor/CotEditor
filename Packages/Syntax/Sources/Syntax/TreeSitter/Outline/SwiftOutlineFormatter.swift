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
import SwiftTreeSitter

enum SwiftOutlineFormatter: TreeSitterOutlineFormatting {
    
    /// Builds an outline item from a resolved Swift outline match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - source: The source text as `NSString`.
    ///   - policy: The outline policy for the syntax.
    /// - Returns: An outline item for the match, or `nil` if the match should be ignored.
    static func item(for match: QueryMatch, source: NSString, policy: OutlinePolicy) -> OutlineItem? {
        
        guard let capture = match.outlineCapture(policy: policy) else { return nil }
        
        guard capture.kind == .function else {
            return DefaultTreeSitterOutlineFormatter.item(for: match, source: source, policy: policy)
        }
        
        let title = source.substring(with: capture.range)
        let formattedTitle = Self.functionTitle(for: match, title: title, source: source)
        
        guard let displayTitle = policy.titleFormatter(capture.kind, formattedTitle) else { return nil }
        
        return OutlineItem(title: displayTitle, range: match.range ?? capture.range, kind: capture.kind, indent: .level(capture.depth))
    }
}


private extension SwiftOutlineFormatter {
    
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
