//
//  NSTextView+RegexParse.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2023 1024jp
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

extension NSTextView {
    
    /// Invalidates content string as a regular expression pattern and highlight them.
    ///
    /// - Parameters:
    ///   - mode: Parse mode of regular expression.
    ///   - enabled: If true, parse and highlight, otherwise just remove the current highlight.
    /// - Returns: Whether the content is not invalid.
    @discardableResult
    @MainActor final func highlightAsRegularExpressionPattern(mode: RegularExpressionParseMode, enabled: Bool = true) -> Bool {
        
        guard
            let layoutManager = self.textLayoutManager
        else { return self.highlightAsRegularExpressionPatternWithLegacyTextKit(mode: mode, enabled: enabled) }
        
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
        for type in RegularExpressionSyntaxType.allCases.reversed() {
            for range in type.ranges(in: self.string, mode: mode) {
                guard let textRange = layoutManager.textRange(for: range) else { continue }
                layoutManager.addRenderingAttribute(.foregroundColor, value: type.color, for: textRange)
            }
        }
        
        return true
    }
    
    
    /// Legacy implementation that is the same as `highlightAsRegularExpressionPattern(mode:enabled:)` above.
    ///
    /// - Parameters:
    ///   - mode: Parse mode of regular expression.
    ///   - enabled: If true, parse and highlight, otherwise just remove the current highlight.
    /// - Returns: Whether the content is not invalid.
    @MainActor private func highlightAsRegularExpressionPatternWithLegacyTextKit(mode: RegularExpressionParseMode, enabled: Bool = true) -> Bool {
        
        guard let layoutManager = self.layoutManager else { assertionFailure(); return false }
        
        // clear the last highlight anyway
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: self.string.nsRange)
        
        guard enabled else { return true }
        
        // validate regex pattern
        switch mode {
            case .search:
                guard (try? NSRegularExpression(pattern: self.string)) != nil else { return false }
            case .replacement:
                break
        }
        
        // highlight
        for type in RegularExpressionSyntaxType.allCases.reversed() {
            for range in type.ranges(in: self.string, mode: mode) {
                layoutManager.addTemporaryAttribute(.foregroundColor, value: type.color, forCharacterRange: range)
            }
        }
        
        return true
    }
}
