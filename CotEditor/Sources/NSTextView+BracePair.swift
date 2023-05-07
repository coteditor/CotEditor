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
    
    /// find the matching braces for the character before the cursors and highlight them
    func highlightMatchingBrace(candidates: [BracePair], ignoring pairToIgnore: BracePair? = nil) {
        
        guard
            !self.string.isEmpty,
            let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue)
        else { return }
        
        let cursorIndexes = selectedRanges
            .filter { $0.isEmpty }
            .filter { $0.location > 0 }
            .map { String.Index(utf16Offset: $0.lowerBound, in: self.string) }
        
        guard
            !cursorIndexes.isEmpty,
            let visibleRange = self.visibleRange,
            let range = Range(visibleRange, in: self.string)
        else { return }
        
        cursorIndexes
            .map { self.string.index(before: $0) }
            .compactMap { self.string.indexOfBracePair(at: $0, candidates: candidates, in: range, ignoring: pairToIgnore) }
            .compactMap { pairIndex in
                switch pairIndex {
                    case .begin(let index), .end(let index): return index
                    case .odd: return nil
                }
            }
            .map { NSRange($0...$0, in: self.string) }
            .forEach { self.showFindIndicator(for: $0) }
    }
}
