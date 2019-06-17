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
//  © 2018-2019 1024jp
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

import Cocoa

extension NSTextView {
    
    /// find the matching brace for the character before the cursor and highlight it
    func highligtMatchingBrace(candidates: [BracePair], ignoring pairToIgnore: BracePair? = nil) {
        
        let string = self.string
        let selectedRange = self.selectedRange
        
        guard
            !string.isEmpty,
            selectedRange.isEmpty,
            selectedRange.location != NSNotFound,
            selectedRange.location > 0,
            let cursorIndex = Range(selectedRange, in: string)?.lowerBound,
            let visibleRange = self.visibleRange,
            let range = Range(visibleRange, in: string)
            else { return }
        
        // check the character just before the cursor
        let lastIndex = string.index(before: cursorIndex)
        
        guard let pairIndex = string.indexOfBracePair(at: lastIndex, candidates: candidates, in: range, ignoring: pairToIgnore) else { return }
        
        switch pairIndex {
        case .begin(let index), .end(let index):
            let range = NSRange(index...index, in: string)
            self.showFindIndicator(for: range)
        case .odd: break
        }
    }
    
}
