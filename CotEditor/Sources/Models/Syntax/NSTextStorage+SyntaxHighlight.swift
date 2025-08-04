//
//  NSTextStorage+SyntaxHighlight.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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
import AppKit.NSTextStorage
import Syntax

extension NSTextStorage {
    
    /// Applies syntax highlights.
    ///
    /// - Note: Sanitize the `highlights` before so that the ranges do not overlap each other.
    ///
    /// - Parameters:
    ///   - highlights: The highlight definitions to apply.
    ///   - theme: The theme to apply, or `nil` to add just `syntaxType` attributes.
    ///   - range: The range to update syntax highlight.
    final func apply(highlights: [Highlight], theme: Theme?, in range: NSRange) {
        
        assert(highlights.sorted(using: KeyPathComparator(\.range.location)) == highlights)
        
        // skip if never colorized yet to avoid heavy `self.invalidateDisplay(forCharacterRange:)`
        guard !highlights.isEmpty || self.hasAttribute(.syntaxType, in: range) else { return }
        
        self.beginEditing()
        self.removeAttribute(.foregroundColor, range: range)
        self.removeAttribute(.syntaxType, range: range)
        
        for highlight in highlights {
            self.addAttribute(.syntaxType, value: highlight.value, range: highlight.range)
            
            if let color = theme?.style(for: highlight.value)?.color {
                self.addAttribute(.foregroundColor, value: color, range: highlight.range)
            }
        }
        self.endEditing()
    }
    
    
    /// Applies the theme based on the current `syntaxType` attributes.
    ///
    /// - Parameters:
    ///   - theme: The theme to apply.
    ///   - range: The character range to invalidate.
    final func invalidateHighlight(theme: Theme, in range: NSRange? = nil) {
        
        let targetRange = range ?? self.range
        
        guard self.hasAttribute(.syntaxType, in: targetRange) else { return }
        
        self.beginEditing()
        self.enumerateAttribute(.syntaxType, type: SyntaxType.self, in: targetRange) { type, range, _ in
            if let color = theme.style(for: type)?.color {
                self.addAttribute(.foregroundColor, value: color, range: range)
            } else {
                self.removeAttribute(.foregroundColor, range: range)
            }
        }
        self.endEditing()
    }
}
