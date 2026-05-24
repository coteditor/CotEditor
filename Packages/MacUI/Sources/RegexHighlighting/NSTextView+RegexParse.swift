//
//  NSTextView+RegexParse.swift
//  RegexHighlighting
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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

public import AppKit

public extension NSTextView {
    
    /// Invalidates regular-expression syntax highlighting managed by TextKit 2.
    ///
    /// - Parameters:
    ///   - mode: Parse mode of regular expression.
    ///   - theme: The color theme for regex highlighting.
    ///   - enabled: If true, update the rendering attributes validator; otherwise just remove the current highlight.
    /// - Returns: Whether the current content is a valid regular expression pattern, or `true` if validation is skipped.
    @discardableResult final func invalidateRegularExpressionHighlight(mode: RegexParseMode, theme: RegexTheme<NSColor>, enabled: Bool = true) -> Bool {
        
        guard let layoutManager = self.textLayoutManager else {
            assertionFailure("This method supports only TextKit 2.")
            return false
        }
        
        guard enabled, mode.validate(pattern: self.string) else {
            layoutManager.removeRenderingAttribute(.foregroundColor, for: layoutManager.documentRange)
            layoutManager.invalidateRenderingAttributes()
            layoutManager.renderingAttributesValidator = nil
            return !enabled
        }
        
        layoutManager.renderingAttributesValidator = { [weak self] layoutManager, textLayoutFragment in
            let fragmentTextRange = textLayoutFragment.rangeInElement
            layoutManager.removeRenderingAttribute(.foregroundColor, for: fragmentTextRange)
            
            guard
                let string = self?.string,
                mode.validate(pattern: string),
                let fragmentRange = layoutManager.range(for: fragmentTextRange)
            else { return }
            
            for type in RegexSyntaxType.allCases.reversed() {
                let color = theme.color(for: type)
                for range in type.ranges(in: string, mode: mode) {
                    let range = NSIntersectionRange(range, fragmentRange)
                    guard range.length > 0, let textRange = layoutManager.textRange(for: range) else { continue }
                    
                    layoutManager.addRenderingAttribute(.foregroundColor, value: color, for: textRange)
                }
            }
        }
        
        layoutManager.invalidateRenderingAttributes()
        
        return true
    }
    
    
    /// Highlights the content string as a regular expression pattern using TextKit 1.
    ///
    /// - Parameters:
    ///   - mode: Parse mode of regular expression.
    ///   - theme: The color theme for regex highlighting.
    ///   - enabled: If true, parse and highlight; otherwise just remove the current highlight.
    /// - Returns: Whether the current content is a valid regular expression pattern, or `true` if validation is skipped.
    func highlightAsRegularExpressionPattern(mode: RegexParseMode, theme: RegexTheme<NSColor>, enabled: Bool = true) -> Bool {
        
        guard let layoutManager = unsafe self.layoutManager else { assertionFailure(); return false }
        
        // clear the last highlight anyway
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: NSRange(..<self.string.utf16.count))
        
        guard enabled else { return true }
        
        // validate regex pattern
        guard mode.validate(pattern: self.string) else { return false }
        
        // highlight
        for type in RegexSyntaxType.allCases.reversed() {
            let color = theme.color(for: type)
            for range in type.ranges(in: self.string, mode: mode) {
                layoutManager.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: range)
            }
        }
        
        return true
    }
}


private extension NSTextLayoutManager {
    
    /// Invalidates the rendering attributes in the whole document range.
    func invalidateRenderingAttributes() {
        
        guard !self.documentRange.isEmpty else { return }
        
        self.invalidateRenderingAttributes(for: self.documentRange)
        self.textContentManager?.performEditingTransaction {
            self.textContentManager?.recordEditAction(in: self.documentRange, newTextRange: self.documentRange)
        }
    }
}
