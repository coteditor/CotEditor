//
//  TreeSitterOutlineFormatting.swift
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

protocol TreeSitterOutlineFormatting {

    /// Returns the display title and source range for an outline item.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - capture: The primary outline capture for the match.
    ///   - source: The source text as `NSString`.
    /// - Returns: The display title and source range, or `nil` to exclude the match.
    static func title(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange)?
    
    
    /// Formats the display title for an outline item.
    ///
    /// - Parameters:
    ///   - title: The raw title text.
    ///   - kind: The outline item kind.
    /// - Returns: The formatted title, or `nil` to exclude the item.
    static func formatTitle(_ title: String, kind: Syntax.Outline.Kind) -> String?
}


extension TreeSitterOutlineFormatting {
    
    // MARK: Default Implementation
    
    /// Returns the display title and source range for an outline item.
    static func title(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange)? {
        
        Self.defaultTitle(capture: capture, source: source)
    }
    
    
    /// Returns the title as-is.
    static func formatTitle(_ title: String, kind: Syntax.Outline.Kind) -> String? {
        
        title
    }
    
    
    // MARK: Internal Methods
    
    /// Builds an outline item from a resolved tree-sitter query match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - source: The source text as `NSString`.
    ///   - policy: The outline policy for the syntax.
    /// - Returns: An outline item for the match, or `nil` if the match should be ignored.
    static func item(for match: QueryMatch, source: NSString, policy: OutlinePolicy) -> OutlineItem? {
        
        guard
            let capture = match.captures.lazy
                .compactMap({ OutlineCapture(capture: $0, policy: policy) })
                .first
        else { return nil }
        
        if capture.kind == .separator {
            return OutlineItem.separator(range: capture.range, indent: .level(capture.depth))
        }
        
        guard
            let (title, range) = Self.title(for: match, capture: capture, source: source),
            let displayTitle = Self.formatTitle(title, kind: capture.kind),
            !displayTitle.isEmpty
        else { return nil }
        
        return OutlineItem(title: displayTitle, range: range, kind: capture.kind, indent: .level(capture.depth))
    }
    
    
    /// Returns the raw capture text and range.
    static func defaultTitle(capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange) {
        
        (title: source.substring(with: capture.range), range: capture.range)
    }
    
    
    /// Returns the range of the first `outline.signature.parameters` capture in the match.
    ///
    /// - Parameter match: The resolved query match.
    /// - Returns: The parameters range, or `nil` if the match has no parameter capture.
    static func parametersRange(for match: QueryMatch) -> NSRange? {
        
        match.captures(named: "outline.signature.parameters").first?.range
    }
}


/// The default outline formatter with no language-specific customization.
enum DefaultOutlineFormatter: TreeSitterOutlineFormatting { }


struct OutlineCapture {
    
    var kind: Syntax.Outline.Kind
    var range: NSRange
    var depth: Int
    
    
    init?(capture: QueryCapture, policy: OutlinePolicy) {
        
        let components = capture.nameComponents
        
        guard
            components.first == "outline",
            components.count > 1,
            let kind = Syntax.Outline.Kind(rawValue: components[1])
        else { return nil }
        
        self.kind = kind
        self.range = capture.range
        self.depth = policy.depth(captureNameComponents: components, captureNode: capture.node)
    }
}


extension OutlinePolicy {
    
    /// Computes the raw outline depth for a capture.
    ///
    /// - Parameters:
    ///   - components: The capture name components.
    ///   - node: The capture node used to derive the raw depth.
    /// - Returns: The raw depth before normalization.
    func depth(captureNameComponents components: [String], captureNode node: Node?) -> Int {
        
        if components.count > 2, components[1] == "heading" {
            return Self.headingLevel(from: components[2])
        }
        
        guard let node else { return 0 }
        
        return sequence(first: node, next: \.parent).count { node in
            self.ignoredDepthNodeTypes.isEmpty || !self.ignoredDepthNodeTypes.contains(node.nodeType ?? "")
        }
    }
    
    
    /// Returns the semantic heading depth for a heading capture component.
    ///
    /// - Parameters:
    ///   - component: The heading component suffix such as `1`.
    /// - Returns: The 1-based heading depth.
    private static func headingLevel(from component: String) -> Int {
        
        if let level = Int(component), Syntax.Outline.Kind.levelRange.contains(level) {
            level
        } else {
            1
        }
    }
}


extension QueryMatch {
    
    /// The language injection depth for the match.
    var treeDepth: Int {
        
        self.captures.first?.depth ?? 0
    }
    
    
    /// The primary outline node for the match.
    var outlineNode: Node? {
        
        self.captures.first {
            let components = $0.nameComponents
            
            return components.first == "outline"
                && components.count > 1
                && Syntax.Outline.Kind(rawValue: components[1]) != nil
        }?.node
    }
}
