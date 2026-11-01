//
//  BidiSelectionTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-31.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import Testing
import LineEnding
@testable import CotEditor

@MainActor struct BidiSelectionTests {
    
    /// Tests that modifying the selection word by word keeps the selection of the default implementation in bidirectional text.
    @Test func modifySelectionByWord() {
        
        do {
            let textView = makeEditorTextView(string: "abc שלום.עולם def", selectedRange: NSRange(13..<13))
            
            textView.moveWordLeftAndModifySelection(nil)
            #expect(textView.selectedRanges == [NSValue(range: NSRange(4..<13))])
        }
        
        do {
            let textView = makeEditorTextView(string: "abc שלום.עולם def", selectedRange: NSRange(5..<5))
            
            textView.moveWordLeftAndModifySelection(nil)
            #expect(textView.selectedRanges == [NSValue(range: NSRange(5..<13))])
            
            textView.moveWordRightAndModifySelection(nil)
            #expect(textView.selectedRanges == [NSValue(range: NSRange(5..<5))])
        }
    }
    
    
    /// Tests that deleting a word in bidirectional text deletes only the contiguous range.
    @Test func deleteWordForward() {
        
        let textView = makeEditorTextView(string: "abc שלום.עולם def", selectedRange: NSRange(3..<3))
        
        textView.deleteWordForward(nil)
        #expect(textView.string == "abc def")
        #expect(textView.insertionRanges == [NSRange(3..<3)])
    }
    
    
    /// Tests that expanding the selection to the beginning of the line reaches the line start in bidirectional text.
    @Test func moveToBeginningOfLineAndModifySelection() {
        
        do {
            let textView = makeEditorTextView(string: "abc שלום.עולם def", selectedRange: NSRange(13..<13))
            
            textView.moveToBeginningOfLineAndModifySelection(nil)
            #expect(textView.selectedRanges == [NSValue(range: NSRange(0..<13))])
            
            textView.moveToBeginningOfLineAndModifySelection(nil)
            #expect(textView.selectedRanges == [NSValue(range: NSRange(0..<13))])
        }
        
        // from a selection made inside right-to-left text
        do {
            let textView = makeEditorTextView(string: "abc שלום.עולם def", selectedRange: NSRange(5..<5))
            
            textView.moveWordRightAndModifySelection(nil)
            textView.moveToBeginningOfLineAndModifySelection(nil)
            #expect(textView.selectedRanges == [NSValue(range: NSRange(0..<5))])
        }
    }
    
    
    /// Tests that the additional word boundaries and the indentation stop still work in left-to-right text.
    @Test func modifySelectionInLeftToRightText() {
        
        let textView = makeEditorTextView(string: "    abc.def ghi", selectedRange: NSRange(11..<11))
        
        textView.moveWordLeftAndModifySelection(nil)
        #expect(textView.selectedRange == NSRange(8..<11))
        
        textView.moveToBeginningOfLineAndModifySelection(nil)
        #expect(textView.selectedRange == NSRange(4..<11))
    }
    
    
    /// Tests that modifying the selection keeps a single range in left-to-right text in a right-to-left document.
    @Test func modifySelectionInRightToLeftDocument() {
        
        let textView = makeEditorTextView(string: "abc.def ghi:jkl\n  mno,pqr", selectedRange: NSRange(19..<19))
        textView.baseWritingDirection = .rightToLeft
        textView.layoutManager!.ensureLayout(for: textView.textContainer!)
        
        textView.moveWordRightAndModifySelection(nil)
        #expect(textView.selectedRanges.count == 1)
    }
}


/// Creates an editor text view with a single selection.
///
/// - Parameters:
///   - string: The text view content.
///   - selectedRange: The selection range.
/// - Returns: An editor text view.
@MainActor private func makeEditorTextView(string: String, selectedRange: NSRange) -> EditorTextView {
    
    let textStorage = NSTextStorage(string: string)
    let lineEndingScanner = LineEndingScanner(textStorage: textStorage, lineEnding: .lf)
    let textView = EditorTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 200), textStorage: textStorage, lineEndingScanner: lineEndingScanner)
    textView.isEditable = true
    textView.isSelectable = true
    textView.layoutManager!.ensureLayout(for: textView.textContainer!)
    textView.selectedRange = selectedRange
    
    return textView
}
