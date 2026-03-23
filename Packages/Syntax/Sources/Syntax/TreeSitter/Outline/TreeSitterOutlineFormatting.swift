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
import SwiftTreeSitter

protocol TreeSitterOutlineFormatting {
    
    /// Builds an outline item from a resolved query match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - source: The source text as `NSString`.
    ///   - policy: The outline policy for the syntax.
    /// - Returns: An outline item for the match, or `nil` if the match should be ignored.
    static func item(for match: QueryMatch, source: NSString, policy: OutlinePolicy) -> OutlineItem?
}


enum DefaultTreeSitterOutlineFormatter: TreeSitterOutlineFormatting {
    
    /// Builds an outline item from a resolved query match using the primary outline capture.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - source: The source text as `NSString`.
    ///   - policy: The outline policy for the syntax.
    /// - Returns: An outline item for the match, or `nil` if the match should be ignored.
    static func item(for match: QueryMatch, source: NSString, policy: OutlinePolicy) -> OutlineItem? {
        
        guard let capture = match.outlineCapture(policy: policy) else { return nil }
        
        if capture.kind == .separator {
            return OutlineItem.separator(range: capture.range, indent: .level(capture.depth))
        }
        
        let title = source.substring(with: capture.range)
        
        guard let formattedTitle = policy.titleFormatter(capture.kind, title) else { return nil }
        
        return OutlineItem(title: formattedTitle, range: capture.range, kind: capture.kind, indent: .level(capture.depth))
    }
}


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
        
        let ancestorNodeTypes = sequence(first: capture.node, next: \.parent)
            .map { $0.nodeType ?? "" }
        
        self.kind = kind
        self.range = capture.range
        self.depth = policy.depth(captureNameComponents: components, ancestorNodeTypes: ancestorNodeTypes)
    }
}


extension QueryMatch {
    
    /// The language injection depth for the match.
    var treeDepth: Int {
        
        self.captures.first?.depth ?? 0
    }
    
    
    /// Returns the primary outline capture for the match.
    ///
    /// - Parameter policy: The outline policy for the syntax.
    /// - Returns: The primary outline capture, or `nil` if none exists.
    func outlineCapture(policy: OutlinePolicy) -> OutlineCapture? {
        
        self.captures.lazy
            .compactMap { OutlineCapture(capture: $0, policy: policy) }
            .first
    }
}
