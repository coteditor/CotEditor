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
//  © 2018-2024 1024jp
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

import AppKit

public extension NSTextView {
    
    /// Invalidates the content string as a regular expression pattern and highlight them.
    ///
    /// - Parameters:
    ///   - mode: Parse mode of regular expression.
    ///   - theme: The color theme for regex highlighting.
    ///   - enabled: If true, parse and highlight, otherwise just remove the current highlight.
    /// - Returns: Whether the contents are not invalid.
    @discardableResult
    final func highlightAsRegularExpressionPattern(mode: RegexParseMode, theme: RegexTheme<NSColor>, enabled: Bool = true) -> Bool {
        
        guard
            let layoutManager = self.textLayoutManager
        else { return self.highlightAsRegularExpressionPatternWithLegacyTextKit(mode: mode, theme: theme, enabled: enabled) }
        
        // clear the last highlight anyway
        layoutManager.removeRenderingAttribute(.foregroundColor, for: layoutManager.documentRange)
        
        guard enabled else { return true }
        
        // validate regex pattern
        switch mode {
            case .search:
                guard (try? NSRegularExpression(pattern: self.string)) != nil else { return false }
            case .replacement:
                break
        }
        
        // highlight
        for type in RegexSyntaxType.allCases.reversed() {
            let color = theme.color(for: type)
            for range in type.ranges(in: self.string, mode: mode) {
                guard let textRange = layoutManager.textRange(for: range) else { continue }
                layoutManager.addRenderingAttribute(.foregroundColor, value: color, for: textRange)
            }
        }
        
        return true
    }
    
    
    /// Legacy implementation that is the same as `highlightAsRegularExpressionPattern(mode:enabled:)` above.
    ///
    /// - Parameters:
    ///   - mode: Parse mode of regular expression.
    ///   - theme: The color theme for regex highlighting.
    ///   - enabled: If true, parse and highlight, otherwise just remove the current highlight.
    /// - Returns: Whether the contents are not invalid.
    private func highlightAsRegularExpressionPatternWithLegacyTextKit(mode: RegexParseMode, theme: RegexTheme<NSColor>, enabled: Bool = true) -> Bool {
        
        guard let layoutManager = self.layoutManager else { assertionFailure(); return false }
        
        // clear the last highlight anyway
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: NSRange(..<self.string.utf16.count))
        
        guard enabled else { return true }
        
        // validate regex pattern
        switch mode {
            case .search:
                guard (try? NSRegularExpression(pattern: self.string)) != nil else { return false }
            case .replacement:
                break
        }
        
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
