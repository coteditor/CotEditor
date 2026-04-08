//
//  HTMLOutlineFormatter.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-08.
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

enum HTMLOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func title(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange)? {
        
        guard let node = match.outlineNode else {
            return Self.defaultTitle(capture: capture, source: source)
        }
        
        let ranges = Self.textRanges(in: node)
        
        guard
            let first = ranges.first,
            let last = ranges.last
        else { return nil }
        
        let range = NSRange(first.lowerBound..<last.upperBound)
        let title = Self.titleText(from: ranges, source: source)
        
        return (title: title, range: range)
    }
    
    
    static func formatTitle(_ title: String, kind: Syntax.Outline.Kind) -> String? {
        
        let normalized = title
            .replacing(/\s+/, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return normalized.isEmpty ? nil : normalized
    }
}


private extension HTMLOutlineFormatter {
    
    /// Returns the UTF-16 ranges of descendant nodes that contribute visible text to the outline title.
    ///
    /// - Parameter node: The HTML node to inspect.
    /// - Returns: Text-like descendant ranges in document order.
    static func textRanges(in node: Node) -> [NSRange] {
        
        if let nodeType = node.nodeType, ["text", "entity", "raw_text"].contains(nodeType) {
            return [node.range]
        }
        
        return (0..<node.childCount)
            .compactMap(node.child(at:))
            .flatMap(Self.textRanges(in:))
    }
    
    
    /// Builds the display title from text-like descendant ranges while preserving inter-node whitespace.
    ///
    /// - Parameters:
    ///   - ranges: The descendant text ranges in document order.
    ///   - source: The full source text as `NSString`.
    /// - Returns: The concatenated outline title text.
    static func titleText(from ranges: [NSRange], source: NSString) -> String {
        
        var result = ""
        result.reserveCapacity(ranges.map(\.length).reduce(0, +))
        
        var previousUpperBound: Int?
        for range in ranges {
            if let previousUpperBound {
                let gap = NSRange(previousUpperBound..<range.lowerBound)
                if gap.length > 0,
                   result.last?.isWhitespace != true,
                   Self.containsVisibleWhitespace(in: source.substring(with: gap))
                {
                    result += " "
                }
            }
            
            result += source.substring(with: range)
            previousUpperBound = range.upperBound
        }
        
        return result
    }
    
    
    /// Returns whether the gap between text nodes contains visible whitespace outside tags and quoted attributes.
    ///
    /// - Parameter string: The source gap to inspect.
    /// - Returns: `true` when the gap contributes visible whitespace to rendered text.
    static func containsVisibleWhitespace(in string: String) -> Bool {
        
        var isInsideTag = false
        var quote: Character?
        
        for character in string {
            if let quotedCharacter = quote {
                if character == quotedCharacter {
                    quote = nil
                }
            } else if isInsideTag {
                switch character {
                    case "\"", "'":
                        quote = character
                    case ">":
                        isInsideTag = false
                    default:
                        break
                }
            } else {
                if character == "<" {
                    isInsideTag = true
                } else if character.isWhitespace {
                    return true
                }
            }
        }
        
        return false
    }
}
