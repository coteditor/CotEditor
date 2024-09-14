//
//  NSLayoutManager+SyntaxHighlight.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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
import AppKit.NSLayoutManager
import Syntax

extension NSLayoutManager {
    
    /// Extracts all syntax highlights in the given range.
    ///
    /// - Returns: An array of Highlights in order.
    @MainActor final func syntaxHighlights() -> [Highlight] {
        
        let targetRange = self.attributedString().range
        
        var highlights: [Highlight] = []
        self.enumerateTemporaryAttribute(.syntaxType, type: SyntaxType.self, in: targetRange) { (type, range, _) in
            highlights.append(Highlight(value: type, range: range))
        }
        
        return highlights
    }
    
    
    /// Applies highlights as temporary attributes.
    ///
    /// - Note: Sanitize the `highlights` before so that the ranges do not overlap each other.
    ///
    /// - Parameters:
    ///   - highlights: The highlight definitions to apply.
    ///   - theme: The theme to apply, or `nil` to add just `syntaxType` attributes.
    ///   - range: The range to update syntax highlight.
    @MainActor final func apply(highlights: [Highlight], theme: Theme?, in range: NSRange) {
        
        assert(highlights.sorted(using: SortDescriptor(\.range.location)) == highlights)
        
        // skip if never colorized yet to avoid heavy `self.invalidateDisplay(forCharacterRange:)`
        guard !highlights.isEmpty || self.hasTemporaryAttribute(.syntaxType, in: range) else { return }
        
        self.groupTemporaryAttributesUpdate(in: range) {
            self.removeTemporaryAttribute(.foregroundColor, forCharacterRange: range)
            self.removeTemporaryAttribute(.syntaxType, forCharacterRange: range)
            
            for highlight in highlights {
                self.addTemporaryAttribute(.syntaxType, value: highlight.value, forCharacterRange: highlight.range)
                
                if let color = theme?.style(for: highlight.value)?.color {
                    self.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: highlight.range)
                }
            }
        }
    }
    
    
    /// Applies the theme based on the current `syntaxType` attributes.
    ///
    /// - Parameters:
    ///   - theme: The theme to apply.
    ///   - range: The character range to invalidate.
    @MainActor final func invalidateHighlight(theme: Theme, in range: NSRange? = nil) {
        
        let targetRange = range ?? self.attributedString().range
        
        guard self.hasTemporaryAttribute(.syntaxType, in: targetRange) else { return }
        
        self.groupTemporaryAttributesUpdate(in: targetRange) {
            self.enumerateTemporaryAttribute(.syntaxType, type: SyntaxType.self, in: targetRange) { (type, range, _) in
                if let color = theme.style(for: type)?.color {
                    self.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: range)
                } else {
                    self.removeTemporaryAttribute(.foregroundColor, forCharacterRange: range)
                }
            }
        }
    }
}
