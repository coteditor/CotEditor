//
//  MultiCursorEditingTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-29.
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

@MainActor struct MultiCursorEditingTests {
    
    @Test func multipleDeletePreservesBoundaryInsertions() {
        
        do {
            let textView = makeEditorTextView(string: "ab", selectedRange: NSRange(0..<0), insertionLocations: [2])
            
            #expect(textView.multipleDelete(forward: true))
            #expect(textView.string == "b")
            #expect(textView.insertionRanges == [NSRange(0..<0), NSRange(1..<1)])
        }
        
        do {
            let textView = makeEditorTextView(string: "ab", selectedRange: NSRange(0..<0), insertionLocations: [2])
            
            #expect(textView.multipleDelete())
            #expect(textView.string == "a")
            #expect(textView.insertionRanges == [NSRange(0..<0), NSRange(1..<1)])
        }
    }
}


/// Creates an editor text view configured with multiple insertion points.
///
/// - Parameters:
///   - string: The text view content.
///   - selectedRange: The primary selection range.
///   - insertionLocations: Additional insertion point locations.
/// - Returns: An editor text view.
@MainActor private func makeEditorTextView(string: String, selectedRange: NSRange, insertionLocations: [Int]) -> EditorTextView {
    
    let textStorage = NSTextStorage(string: string)
    let lineEndingScanner = LineEndingScanner(textStorage: textStorage, lineEnding: .lf)
    let textView = EditorTextView(textStorage: textStorage, lineEndingScanner: lineEndingScanner)
    textView.isEditable = true
    textView.isSelectable = true
    textView.selectedRange = selectedRange
    textView.insertionLocations = insertionLocations
    
    return textView
}
