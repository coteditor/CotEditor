//
//  NSTextStorage.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

import AppKit.NSTextStorage

extension NSTextStorage {
    
    /// Replace whole content with the given `string`.
    ///
    /// - Parameters:
    ///   - string: The content string to replace with.
    ///   - keepsSelection: foo.
    final func replaceContent(with string: String, keepsSelection: Bool = false) {
        
        assert(self.layoutManagers.isEmpty || Thread.isMainThread)
        
        guard string != self.string else { return }
        
        let textViews = self.layoutManagers.compactMap(\.textViewForBeginningOfSelection)
        let ranges: [NSRange?] = keepsSelection
            ? textViews.map(\.selectedRange)
            : Array(repeating: nil, count: textViews.count)
        
        self.replaceCharacters(in: self.range, with: string)
        
        // reset insertion point
        for (textView, range) in zip(textViews, ranges) {
            textView.selectedRange = if let range {
                NSRange(min(range.lowerBound, self.length)..<min(range.upperBound, self.length))
            } else {
                NSRange(0..<0)
            }
        }
    }
}
