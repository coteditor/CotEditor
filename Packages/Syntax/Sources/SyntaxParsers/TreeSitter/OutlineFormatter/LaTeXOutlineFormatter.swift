//
//  LaTeXOutlineFormatter.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-01.
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

enum LaTeXOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func title(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange)? {
        
        guard let range = Self.titleRange(for: match) else {
            return Self.defaultTitle(capture: capture, source: source)
        }
        
        return (title: source.substring(with: range), range: range)
    }
    
    
    static func formatTitle(_ title: String, kind: Syntax.Outline.Kind) -> String? {
        
        let normalized = title
            .replacing(/\s+/, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return normalized.isEmpty ? nil : normalized
    }
}


private extension LaTeXOutlineFormatter {
    
    /// Returns the content range for the node matched by the outline query.
    static func titleRange(for match: QueryMatch) -> NSRange? {
        
        guard
            let node = match.outlineNode,
            let nodeType = node.nodeType
        else { return nil }
        
        let fieldName: String? = switch nodeType {
            case "title_declaration",
                 "part",
                 "chapter",
                 "section",
                 "subsection",
                 "subsubsection",
                 "paragraph",
                 "subparagraph":
                "text"
            case "caption":
                "long"
            case "environment_definition":
                "name"
            default:
                nil
        }
        
        guard
            let fieldName,
            let fieldNode = node.child(byFieldName: fieldName)
        else { return nil }
        
        return Self.innerRange(of: fieldNode)
    }
    
    
    /// Strips the outer braces, `\{` and `}`, from a LaTeX group node range.
    static func innerRange(of node: Node) -> NSRange {
        
        guard node.range.length >= 2 else { return node.range }
        
        return NSRange(location: node.range.location + 1, length: node.range.length - 2)
    }
}
