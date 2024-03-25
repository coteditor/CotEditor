//
//  NSTextStorage+TextView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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
    
    struct EditorSelection {
        
        fileprivate var string: String
        fileprivate var ranges: [[NSValue]]
    }
    
    
    /// The current selection in the textViews that use the receiver., or `nil` if no text view exists.
    final var editorSelection: EditorSelection? {
        
        assert(self.layoutManagers.isEmpty || Thread.isMainThread)
        
        let textViews = self.layoutManagers.compactMap(\.firstTextView)
        
        // avoid creating immutable string if not necessary
        guard !textViews.isEmpty else { return nil }
        
        return EditorSelection(string: self.string.immutable, ranges: textViews.map(\.selectedRanges))
    }
    
    
    /// Applies the previous selection to the text views by taking diff into account.
    ///
    /// - Parameter state: The selection state to apply.
    final func restoreEditorSelection(_ state: EditorSelection) {
        
        assert(Thread.isMainThread)
        
        let textViews = self.layoutManagers.compactMap(\.firstTextView)
        
        guard state.ranges.count == textViews.count else { return assertionFailure() }
        
        // -> Taking performance issues into consideration,
        //    the selection ranges are adjusted only when the content is small enough;
        //    otherwise, just cut extra ranges off.
        let maxLength = 1_000_000  // takes ca. 0.05 sec. with MacBook M1 13-inch late 2020 (3.3 GHz)
        let considersDiff = state.string.length < maxLength && self.length < maxLength
        
        for (textView, selectedRange) in zip(textViews, state.ranges) {
            let ranges = selectedRange.map(\.rangeValue)
            let selectedRanges = considersDiff
                ? self.string.equivalentRanges(to: ranges, in: state.string)
                : ranges.map { NSRange(min($0.lowerBound, self.length)..<min($0.upperBound, self.length)) }
            
            guard !selectedRanges.isEmpty else { continue }
            
            textView.selectedRanges = selectedRanges.uniqued as [NSValue]
        }
    }
    
    
    /// Replaces whole content with the given `string`.
    ///
    /// - Parameters:
    ///   - string: The content string to replace with.
    ///   - keepsSelection: Whether try to keep the selected ranges in views.
    final func replaceContent(with string: String, keepsSelection: Bool = false) {
        
        assert(self.layoutManagers.isEmpty || Thread.isMainThread)
        
        guard string != self.string else { return }
        
        let selection = keepsSelection ? self.editorSelection : nil
        
        self.replaceCharacters(in: self.range, with: string)
        
        if let selection {
            self.restoreEditorSelection(selection)
        } else {
            for textView in self.layoutManagers.compactMap(\.firstTextView) {
                textView.selectedRange = NSRange(0..<0)
            }
        }
    }
}
