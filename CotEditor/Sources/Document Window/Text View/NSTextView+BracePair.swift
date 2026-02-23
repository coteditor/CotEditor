//
//  NSTextView+BracePair.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-03-29.
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

import AppKit
import StringUtils

extension NSTextView {
    
    /// Finds the matching braces for the character before the cursors in the visible area and highlights them.
    ///
    /// - Parameters:
    ///   - candidates: Brace pairs to find.
    ///   - pairToIgnore: The brace pair in which brace characters should be ignored.
    ///   - escapeRule: The delimiter escape rule.
    final func highlightMatchingBrace(candidates: [BracePair], ignoring pairToIgnore: BracePair? = nil, escapeRule: DelimiterEscapeRule = .backslash) {
        
        guard
            !self.string.isEmpty,
            let selectedRanges = self.rangesForUserTextChange
        else { return }
        
        let lastIndexes = selectedRanges
            .map(\.rangeValue)
            .filter(\.isEmpty)
            .map { String.Index(utf16Offset: $0.lowerBound, in: self.string) }
            .filter { $0 > self.string.startIndex }
            .map(self.string.index(before:))
        
        guard !lastIndexes.isEmpty, let visibleRange else { return }
        
        let range = Range(visibleRange, in: self.string)
        
        lastIndexes
            .compactMap { self.string.indexOfBracePair(at: $0, candidates: candidates, in: range, ignoring: pairToIgnore, escapeRule: escapeRule) }
            .compactMap(\.index)
            .map { NSRange($0...$0, in: self.string) }
            .forEach { self.showFindIndicator(for: $0) }
    }
}
