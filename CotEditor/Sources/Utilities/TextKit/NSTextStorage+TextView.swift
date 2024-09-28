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
    
    typealias EditorSelection = [[NSValue]]
    
    
    /// The current selection in the textViews that use the receiver., or `nil` if no text view exists.
    @MainActor final var editorSelection: EditorSelection {
        
        self.layoutManagers.compactMap(\.firstTextView).map(\.selectedRanges)
    }
    
    
    /// Applies the previous selection to the text views by taking diff into account.
    ///
    /// - Parameter state: The selection state to apply.
    @MainActor final func restoreEditorSelection(_ state: EditorSelection) {
        
        let textViews = self.layoutManagers.compactMap(\.firstTextView)
        
        guard state.count == textViews.count else { return assertionFailure() }
        
        for (textView, selectedRanges) in zip(textViews, state) where !selectedRanges.isEmpty {
            textView.selectedRanges = selectedRanges
                .map(\.rangeValue)
                .map { NSRange(min($0.lowerBound, self.length)..<min($0.upperBound, self.length)) }
                .uniqued as [NSValue]
        }
    }
    
    
    /// Replaces whole contents with the given `string` and move the insertion point to the beginning of the contents.
    ///
    /// - Parameters:
    ///   - string: The content string to replace with.
    @MainActor final func replaceContent(with string: String) {
        
        guard string != self.string else { return }
        
        self.replaceCharacters(in: self.range, with: string)
        
        guard !string.isEmpty else { return }
        
        // otherwise, the insertion point moves to the end of the contents
        for textView in self.layoutManagers.compactMap(\.firstTextView) {
            textView.selectedRange = NSRange(0..<0)
        }
    }
}
