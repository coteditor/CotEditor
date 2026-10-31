//
//  CursorMovementTests.swift
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

@MainActor struct CursorMovementTests {
    
    /// Tests that moving forward word by word with a single cursor stops at additional word separators.
    @Test func moveWordForwardWithSingleCursor() {
        
        let textView = makeEditorTextView(string: "abc.def ghi:jkl")
        
        textView.moveWordForward(nil)
        #expect(textView.selectedRange == NSRange(3..<3))
        
        textView.moveWordForward(nil)
        #expect(textView.selectedRange == NSRange(7..<7))
        
        textView.moveWordForward(nil)
        #expect(textView.selectedRange == NSRange(11..<11))
        
        textView.moveWordForward(nil)
        #expect(textView.selectedRange == NSRange(15..<15))
    }
    
    
    /// Tests that moving backward word by word with a single cursor stops at additional word separators.
    @Test func moveWordBackwardWithSingleCursor() {
        
        let textView = makeEditorTextView(string: "abc.def ghi:jkl", selectedRange: NSRange(15..<15))
        
        textView.moveWordBackward(nil)
        #expect(textView.selectedRange == NSRange(12..<12))
        
        textView.moveWordBackward(nil)
        #expect(textView.selectedRange == NSRange(8..<8))
        
        textView.moveWordBackward(nil)
        #expect(textView.selectedRange == NSRange(4..<4))
        
        textView.moveWordBackward(nil)
        #expect(textView.selectedRange == NSRange(0..<0))
    }
    
    
    /// Tests that the word boundaries of the forward/backward movements match the ones of the right/left movements in left-to-right text.
    @Test func moveWordForwardAndBackwardMatchLeftAndRight() {
        
        let string = "abc.def ghi:jkl, mno\n  foo(bar) 1.5"
        
        for location in 0...(string as NSString).length {
            for range in [NSRange(location: location, length: 0), NSRange(location: max(location - 2, 0), length: min(location, 2))] {
                let forward = makeEditorTextView(string: string, selectedRange: range)
                let right = makeEditorTextView(string: string, selectedRange: range)
                forward.moveWordForward(nil)
                right.moveWordRight(nil)
                #expect(forward.selectedRange == right.selectedRange, "range: \(range)")
                
                let backward = makeEditorTextView(string: string, selectedRange: range)
                let left = makeEditorTextView(string: string, selectedRange: range)
                backward.moveWordBackward(nil)
                left.moveWordLeft(nil)
                #expect(backward.selectedRange == left.selectedRange, "range: \(range)")
            }
        }
    }
    
    
    /// Tests that moving word by word with a single cursor stops at additional word separators also in right-to-left text.
    @Test func moveWordForwardAndBackwardInRTL() {
        
        do {
            let textView = makeEditorTextView(string: "שלום עולם.טוב מאוד", selectedRange: NSRange(4..<4))
            
            textView.moveWordForward(nil)
            #expect(textView.selectedRange == NSRange(9..<9))
        }
        
        do {
            let textView = makeEditorTextView(string: "שלום עולם.טוב מאוד", selectedRange: NSRange(13..<13))
            
            textView.moveWordBackward(nil)
            #expect(textView.selectedRange == NSRange(10..<10))
        }
    }
    
    
    /// Tests that the backward/forward movements follow the logical order in right-to-left text regardless of the number of cursors.
    @Test func moveBackwardAndForwardInLogicalOrder() {
        
        do {
            let textView = makeEditorTextView(string: "שלום\nעולם", selectedRange: NSRange(2..<2))
            
            textView.moveBackward(nil)
            #expect(textView.insertionRanges == [NSRange(1..<1)])
            
            textView.moveForward(nil)
            textView.moveForward(nil)
            #expect(textView.insertionRanges == [NSRange(3..<3)])
        }
        
        do {
            let textView = makeEditorTextView(string: "שלום\nעולם", selectedRange: NSRange(2..<2), insertionLocations: [7])
            
            textView.moveBackward(nil)
            #expect(textView.insertionRanges == [NSRange(1..<1), NSRange(6..<6)])
            
            textView.moveForward(nil)
            textView.moveForward(nil)
            #expect(textView.insertionRanges == [NSRange(3..<3), NSRange(8..<8)])
        }
    }
    
    
    /// Tests that the backward/forward movements collapse selections to the logical bounds regardless of the number of selections.
    @Test func moveBackwardAndForwardCollapseSelectionsInLogicalOrder() {
        
        do {
            let textView = makeEditorTextView(string: "שלום עולם", selectedRange: NSRange(1..<3))
            
            textView.moveBackward(nil)
            #expect(textView.insertionRanges == [NSRange(1..<1)])
        }
        
        do {
            let textView = makeEditorTextView(string: "שלום עולם", selectedRange: NSRange(1..<3))
            
            textView.moveForward(nil)
            #expect(textView.insertionRanges == [NSRange(3..<3)])
        }
        
        do {
            let textView = makeEditorTextView(string: "שלום עולם")
            textView.selectedRanges = [NSRange(1..<3), NSRange(5..<7)] as [NSValue]
            
            textView.moveBackward(nil)
            #expect(textView.insertionRanges == [NSRange(1..<1), NSRange(5..<5)])
        }
        
        do {
            let textView = makeEditorTextView(string: "שלום עולם")
            textView.selectedRanges = [NSRange(1..<3), NSRange(5..<7)] as [NSValue]
            
            textView.moveForward(nil)
            #expect(textView.insertionRanges == [NSRange(3..<3), NSRange(7..<7)])
        }
    }
    
    
    /// Tests that the backward/forward selection modifications follow the logical order in right-to-left text regardless of the number of cursors.
    @Test func moveBackwardAndForwardModifySelectionInLogicalOrder() {
        
        do {
            let textView = makeEditorTextView(string: "שלום\nעולם", selectedRange: NSRange(2..<2))
            
            textView.moveBackwardAndModifySelection(nil)
            #expect(textView.insertionRanges == [NSRange(1..<2)])
        }
        
        do {
            let textView = makeEditorTextView(string: "שלום\nעולם", selectedRange: NSRange(2..<2))
            
            textView.moveForwardAndModifySelection(nil)
            #expect(textView.insertionRanges == [NSRange(2..<3)])
        }
        
        do {
            let textView = makeEditorTextView(string: "שלום\nעולם", selectedRange: NSRange(2..<2), insertionLocations: [7])
            
            textView.moveBackwardAndModifySelection(nil)
            #expect(textView.insertionRanges == [NSRange(1..<2), NSRange(6..<7)])
        }
        
        do {
            let textView = makeEditorTextView(string: "שלום\nעולם", selectedRange: NSRange(2..<2), insertionLocations: [7])
            
            textView.moveForwardAndModifySelection(nil)
            #expect(textView.insertionRanges == [NSRange(2..<3), NSRange(7..<8)])
        }
    }
    
    
    /// Tests that Option-↑ moves to the beginning of the previous paragraph in right-to-left text regardless of the number of cursors.
    @Test func moveToBeginningOfPreviousParagraphInRTL() {
        
        // emulate Option-↑ that invokes `moveBackward(_:)` and then `moveToBeginningOfParagraph(_:)`
        
        do {
            let textView = makeEditorTextView(string: "שלום\nעולם\nטוב", selectedRange: NSRange(10..<10))
            
            textView.moveBackward(nil)
            textView.moveToBeginningOfParagraph(nil)
            #expect(textView.insertionRanges == [NSRange(5..<5)])
        }
        
        do {
            let textView = makeEditorTextView(string: "שלום\nעולם\nטוב", selectedRange: NSRange(5..<5), insertionLocations: [10])
            
            textView.moveBackward(nil)
            textView.moveToBeginningOfParagraph(nil)
            #expect(textView.insertionRanges == [NSRange(0..<0), NSRange(5..<5)])
        }
    }
    
    
    /// Tests that the backward/forward movements step over composed character sequences and CRLF.
    @Test func moveBackwardAndForwardOverCompositeCharacters() {
        
        do {
            let textView = makeEditorTextView(string: "e\u{301}x\r\ny", lineEnding: .crlf, selectedRange: NSRange(2..<2), insertionLocations: [5])
            
            textView.moveBackward(nil)
            #expect(textView.insertionRanges == [NSRange(0..<0), NSRange(3..<3)])
            
            textView.moveForward(nil)
            #expect(textView.insertionRanges == [NSRange(2..<2), NSRange(5..<5)])
        }
        
        do {
            let textView = makeEditorTextView(string: "a\r\nb", lineEnding: .crlf, selectedRange: NSRange(3..<3))
            
            textView.moveBackwardAndModifySelection(nil)
            #expect(textView.insertionRanges == [NSRange(1..<3)])
        }
    }
    
    
    /// Tests that expanding the selection paragraph by paragraph with a single cursor stops at the end of each line contents.
    @Test func moveParagraphForwardAndModifySelectionWithSingleCursor() {
        
        let textView = makeEditorTextView(string: "abc def\nghi jkl\n\nmno", selectedRange: NSRange(2..<2))
        
        textView.moveParagraphForwardAndModifySelection(nil)
        #expect(textView.selectedRange == NSRange(2..<7))
        
        textView.moveParagraphForwardAndModifySelection(nil)
        #expect(textView.selectedRange == NSRange(2..<15))
        
        textView.moveParagraphForwardAndModifySelection(nil)
        #expect(textView.selectedRange == NSRange(2..<16))
        
        textView.moveParagraphForwardAndModifySelection(nil)
        #expect(textView.selectedRange == NSRange(2..<20))
        
        textView.moveParagraphForwardAndModifySelection(nil)
        #expect(textView.selectedRange == NSRange(2..<20))
    }
    
    
    /// Tests that expanding the selection paragraph by paragraph with a single cursor keeps the selection origin.
    @Test func moveParagraphForwardAndModifySelectionKeepsOrigin() {
        
        do {
            let textView = makeEditorTextView(string: "abc def\nghi jkl", selectedRange: NSRange(2..<2))
            
            textView.moveParagraphForwardAndModifySelection(nil)
            textView.moveLeftAndModifySelection(nil)
            #expect(textView.selectedRange == NSRange(2..<6))
        }
        
        do {
            let textView = makeEditorTextView(string: "abc def\nghi jkl", selectedRange: NSRange(10..<10))
            for _ in 0..<5 {
                textView.moveLeftAndModifySelection(nil)
            }
            
            textView.moveParagraphForwardAndModifySelection(nil)
            #expect(textView.selectedRange == NSRange(7..<10))
            
            textView.moveLeftAndModifySelection(nil)
            #expect(textView.selectedRange == NSRange(6..<10))
        }
        
        do {
            let textView = makeEditorTextView(string: "abc def\nghi jkl", selectedRange: NSRange(10..<10))
            
            textView.moveParagraphBackwardAndModifySelection(nil)
            textView.moveParagraphForwardAndModifySelection(nil)
            #expect(textView.selectedRange == NSRange(10..<10))
        }
    }
    
    
    /// Tests that the paragraph-wise selection modifications with a single cursor match the ones with multiple cursors.
    @Test func moveParagraphAndModifySelectionMatchesMultipleCursors() {
        
        let text = "abc def\nghi jkl\n\nmno"
        let length = (text as NSString).length
        let string = text + "\n\n" + text
        let offset = length + 2
        let forward = #selector(NSResponder.moveParagraphForwardAndModifySelection(_:))
        let backward = #selector(NSResponder.moveParagraphBackwardAndModifySelection(_:))
        
        for sequence in [[forward], [forward, forward], [backward, forward], [forward, backward]] {
            for location in 0...length {
                let single = makeEditorTextView(string: string, selectedRange: NSRange(location..<location))
                let multiple = makeEditorTextView(string: string, selectedRange: NSRange(location..<location), insertionLocations: [location + offset])
                
                for selector in sequence {
                    single.perform(selector, with: nil)
                    multiple.perform(selector, with: nil)
                }
                
                #expect(single.insertionRanges.first == multiple.insertionRanges.first, "location: \(location), sequence: \(sequence)")
            }
        }
    }
    
    
    /// Tests that moving to the end of the line repeatedly stays at the end of the soft-wrapped visual line.
    ///
    /// - Parameter isMultiple: Whether to add another insertion point in the second line.
    /// - Throws: If the first line is not soft-wrapped.
    @Test(arguments: [false, true])
    func moveToEndOfSoftWrappedLine(isMultiple: Bool) throws {
        
        let line = String(repeating: "abcd.efg ", count: 14) + "end"
        let offset = (line as NSString).length + 1
        let textView = makeEditorTextView(string: line + "\n" + line, selectedRange: NSRange(3..<3), insertionLocations: isMultiple ? [offset + 3] : [])
        let lineEnd = textView.layoutManager!.lineFragmentRange(at: 3).upperBound
        
        try #require(lineEnd < offset - 1)
        
        textView.moveToEndOfLine(nil)
        #expect(textView.insertionRanges.first == NSRange(location: lineEnd, length: 0))
        
        textView.moveToEndOfLine(nil)
        #expect(textView.insertionRanges.first == NSRange(location: lineEnd, length: 0))
    }
    
    
    /// Tests that expanding the selection to the end of the line repeatedly stays at the end of the soft-wrapped visual line.
    ///
    /// - Parameter isMultiple: Whether to add another insertion point in the second line.
    /// - Throws: If the first line is not soft-wrapped.
    @Test(arguments: [false, true])
    func moveToEndOfSoftWrappedLineAndModifySelection(isMultiple: Bool) throws {
        
        let line = String(repeating: "abcd.efg ", count: 14) + "end"
        let offset = (line as NSString).length + 1
        let textView = makeEditorTextView(string: line + "\n" + line, selectedRange: NSRange(3..<3), insertionLocations: isMultiple ? [offset + 3] : [])
        let lineEnd = textView.layoutManager!.lineFragmentRange(at: 3).upperBound
        
        try #require(lineEnd < offset - 1)
        
        textView.moveToEndOfLineAndModifySelection(nil)
        #expect(textView.insertionRanges.first == NSRange(3..<lineEnd))
        
        textView.moveToEndOfLineAndModifySelection(nil)
        #expect(textView.insertionRanges.first == NSRange(3..<lineEnd))
    }
    
    
    /// Tests that deleting to the end of the line removes the rest of the soft-wrapped visual line.
    ///
    /// - Parameter isMultiple: Whether to add another insertion point in the second line.
    /// - Throws: If the first line is not soft-wrapped.
    @Test(arguments: [false, true])
    func deleteToEndOfSoftWrappedLine(isMultiple: Bool) throws {
        
        let line = String(repeating: "abcd.efg ", count: 14) + "end"
        let offset = (line as NSString).length + 1
        let textView = makeEditorTextView(string: line + "\n" + line, selectedRange: NSRange(3..<3), insertionLocations: isMultiple ? [offset + 3] : [])
        let lineEnd = textView.layoutManager!.lineFragmentRange(at: 3).upperBound
        
        try #require(lineEnd < offset - 1)
        
        let deletedLine = (line as NSString).replacingCharacters(in: NSRange(3..<lineEnd), with: "")
        
        textView.deleteToEndOfLine(nil)
        #expect(textView.string == deletedLine + "\n" + (isMultiple ? deletedLine : line))
        #expect(textView.insertionRanges.first == NSRange(3..<3))
    }
    
    
    /// Tests that deleting to the end of the paragraph at the line end joins the next line, including CRLF.
    ///
    /// - Parameter isMultiple: Whether to add another insertion point at the end of the second line.
    @Test(arguments: [false, true])
    func deleteToEndOfParagraphJoinsLines(isMultiple: Bool) {
        
        let textView = makeEditorTextView(string: "abc\r\ndef\r\nghi", lineEnding: .crlf, selectedRange: NSRange(3..<3), insertionLocations: isMultiple ? [8] : [])
        
        textView.deleteToEndOfParagraph(nil)
        
        #expect(textView.string == (isMultiple ? "abcdefghi" : "abcdef\r\nghi"))
        #expect(textView.insertionRanges == (isMultiple ? [NSRange(3..<3), NSRange(6..<6)] : [NSRange(3..<3)]))
    }
    
    
    /// Tests that the text deleted to the end of the paragraph in the middle of a CRLF line can be yanked back.
    @Test func deleteToEndOfParagraphKeepsKillBufferWithCRLF() {
        
        let textView = makeEditorTextView(string: "abc def\r\nghi", lineEnding: .crlf, selectedRange: NSRange(3..<3))
        
        textView.deleteToEndOfParagraph(nil)
        #expect(textView.string == "abc\r\nghi")
        
        textView.yank(nil)
        #expect(textView.string == "abc def\r\nghi")
    }
    
    
    /// Tests that deleting to the end of the line at the line end joins the next line, including CRLF.
    ///
    /// - Parameter isMultiple: Whether to add another insertion point at the end of the second line.
    @Test(arguments: [false, true])
    func deleteToEndOfLineJoinsLines(isMultiple: Bool) {
        
        let textView = makeEditorTextView(string: "abc\r\ndef\r\nghi", lineEnding: .crlf, selectedRange: NSRange(3..<3), insertionLocations: isMultiple ? [8] : [])
        
        textView.deleteToEndOfLine(nil)
        
        #expect(textView.string == (isMultiple ? "abcdefghi" : "abcdef\r\nghi"))
        #expect(textView.insertionRanges == (isMultiple ? [NSRange(3..<3), NSRange(6..<6)] : [NSRange(3..<3)]))
    }
    
    
    /// Tests that deleting to the end of the line with selections deletes only the selected text.
    ///
    /// - Parameter isMultiple: Whether to add another selection in the second line.
    @Test(arguments: [false, true])
    func deleteToEndOfLineWithSelection(isMultiple: Bool) {
        
        let textView = makeEditorTextView(string: "alpha beta\ngamma delta\nepsilon")
        textView.selectedRanges = (isMultiple ? [NSRange(6..<10), NSRange(17..<22)] : [NSRange(6..<10)]) as [NSValue]
        
        textView.deleteToEndOfLine(nil)
        
        #expect(textView.string == (isMultiple ? "alpha \ngamma \nepsilon" : "alpha \ngamma delta\nepsilon"))
    }
    
    
    /// Tests that deleting to the beginning of the paragraph removes the text before each cursor in the logical line.
    ///
    /// - Parameter isMultiple: Whether to add another insertion point in the third line.
    @Test(arguments: [false, true])
    func deleteToBeginningOfParagraph(isMultiple: Bool) {
        
        let textView = makeEditorTextView(string: "alpha beta\ngamma delta\nepsilon zeta", selectedRange: NSRange(17..<17), insertionLocations: isMultiple ? [31] : [])
        
        textView.deleteToBeginningOfParagraph(nil)
        
        #expect(textView.string == (isMultiple ? "alpha beta\ndelta\nzeta" : "alpha beta\ndelta\nepsilon zeta"))
        #expect(textView.insertionRanges == (isMultiple ? [NSRange(11..<11), NSRange(17..<17)] : [NSRange(11..<11)]))
    }
    
    
    /// Tests that deleting to the beginning of the paragraph or line at the line start joins the previous line, including CRLF.
    ///
    /// - Parameter isMultiple: Whether to add another insertion point at the beginning of the third line.
    @Test(arguments: [false, true])
    func deleteToBeginningJoinsLines(isMultiple: Bool) {
        
        for selector in [#selector(NSTextView.deleteToBeginningOfParagraph), #selector(NSTextView.deleteToBeginningOfLine)] {
            let textView = makeEditorTextView(string: "abc\r\ndef\r\nghi", lineEnding: .crlf, selectedRange: NSRange(5..<5), insertionLocations: isMultiple ? [10] : [])
            
            textView.doCommand(by: selector)
            
            #expect(textView.string == (isMultiple ? "abcdefghi" : "abcdef\r\nghi"))
            #expect(textView.insertionRanges == (isMultiple ? [NSRange(3..<3), NSRange(6..<6)] : [NSRange(3..<3)]))
        }
    }
}


/// Creates an editor text view configured with the given cursors.
///
/// - Parameters:
///   - string: The text view content.
///   - lineEnding: The line ending of the document.
///   - selectedRange: The primary selection range.
///   - insertionLocations: Additional insertion point locations.
/// - Returns: An editor text view.
@MainActor private func makeEditorTextView(string: String, lineEnding: LineEnding = .lf, selectedRange: NSRange = NSRange(0..<0), insertionLocations: [Int] = []) -> EditorTextView {
    
    let textStorage = NSTextStorage(string: string)
    let lineEndingScanner = LineEndingScanner(textStorage: textStorage, lineEnding: lineEnding)
    let textView = EditorTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 200), textStorage: textStorage, lineEndingScanner: lineEndingScanner)
    textView.lineEnding = lineEnding
    textView.isEditable = true
    textView.isSelectable = true
    textView.layoutManager!.ensureLayout(for: textView.textContainer!)
    textView.selectedRange = selectedRange
    textView.insertionLocations = insertionLocations
    
    return textView
}
