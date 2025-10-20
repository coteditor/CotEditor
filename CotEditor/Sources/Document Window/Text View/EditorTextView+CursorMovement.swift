//
//  EditorTextView+CursorMovement.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-01-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2025 1024jp
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
import LineEnding
import StringUtils

extension EditorTextView {
    
    // MARK: Text View Methods - Arrow
    
    /// Moves the cursor backward (←).
    ///
    /// - Note:
    ///   Although the method name contains "Left", behavior is adjusted intelligently in vertical or RTL layout.
    ///   This rule appears to be valid for all `move*{Left|Right}(_:)` actions.
    override func moveLeft(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveLeft(sender)
        }
        
        self.moveCursors(affinity: .downstream) { range in
            if range.isEmpty {
                self.layoutManager!.leftCharacterIndex(of: range.location, baseWritingDirection: self.baseWritingDirection)
            } else {
                self.layoutManager!.isRTL(at: range.upperBound) ? range.upperBound : range.lowerBound
            }
        }
    }
    
    
    /// Moves the cursor backward and modifies the selection (⇧←).
    override func moveLeftAndModifySelection(_ sender: Any?) {
        
        // -> The default implementation cannot handle CRLF line endings correctly (2022-02, macOS 12).
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveLeftAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) { cursor, _ in
            self.layoutManager!.leftCharacterIndex(of: cursor, baseWritingDirection: self.baseWritingDirection)
        }
    }
    
    
    /// Moves the cursor forward (→).
    override func moveRight(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveRight(sender)
        }
        
        self.moveCursors(affinity: .upstream) { range in
            if range.isEmpty {
                self.layoutManager!.rightCharacterIndex(of: range.location, baseWritingDirection: self.baseWritingDirection)
            } else {
                self.layoutManager!.isRTL(at: range.lowerBound) ? range.lowerBound : range.upperBound
            }
        }
    }
    
    
    /// Moves the cursor forward and modifies the selection (⇧→).
    override func moveRightAndModifySelection(_ sender: Any?) {
        
        // -> The default implementation cannot handle CRLF line endings correctly (2022-02, macOS 12).
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveRightAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) { cursor, _ in
            self.layoutManager!.rightCharacterIndex(of: cursor, baseWritingDirection: self.baseWritingDirection)
        }
    }
    
    
    /// Moves the cursor up to the upper visual line (↑ / ^P).
    override func moveUp(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveUp(sender)
        }
        
        self.moveCursors(affinity: .downstream) { range in
            self.upperInsertionLocation(of: range.lowerBound)
        }
    }
    
    
    /// Moves the cursor up and modifies the selection (⇧↑ / ^⇧P).
    override func moveUpAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveUpAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) { cursor, origin in
            self.upperInsertionLocation(of: cursor, origin: origin)
        }
    }
    
    
    /// Moves the cursor down to the lower visual line (↓ / ^N).
    override func moveDown(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveDown(sender)
        }
        
        self.moveCursors(affinity: .downstream) { range in
            self.lowerInsertionLocation(of: range.upperBound)
        }
    }
    
    
    /// Moves the cursor down and modifies the selection (⇧↓ / ^⇧N).
    override func moveDownAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveDownAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .downstream) { cursor, origin in
            self.lowerInsertionLocation(of: cursor, origin: origin)
        }
    }
    
    
    // MARK: Text View Methods - Option+Arrow
    
    /// Moves the cursor to the beginning of the word repeatedly (⌥←).
    override func moveWordLeft(_ sender: Any?) {
        
        // find word boundaries manually
        // -> The default implementation uses `textStorage.nextWord(from: $0.lowerBound, forward: isRTL)`
        //    and does not stop at punctuation such as `.` and `:` (2019-06).
        
        self.moveCursors(affinity: .downstream) { range in
            self.nextWord(from: range.lowerBound, forward: self.layoutManager!.isRTL(at: range.upperBound))
        }
    }
    
    
    /// Moves the cursor to the beginning of the word and modifies the selection repeatedly (⇧⌥←).
    override func moveWordLeftAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return self.moveWordAndModifySelection(sender, left: true)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) { cursor, _ in
            self.nextWord(from: cursor, forward: self.layoutManager!.isRTL(at: cursor))
        }
    }
    
    
    /// Moves the cursor to the end of the word repeatedly (⌥→).
    override func moveWordRight(_ sender: Any?) {
        
        // find word boundaries manually (see `moveWordLeft(_:)`)
        
        self.moveCursors(affinity: .upstream) { range in
            self.nextWord(from: range.upperBound, forward: !self.layoutManager!.isRTL(at: range.upperBound))
        }
    }
    
    
    /// Moves the cursor to the end of the word and modifies the selection repeatedly (⇧⌥→).
    override func moveWordRightAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return self.moveWordAndModifySelection(sender, left: false)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) { cursor, _ in
            self.nextWord(from: cursor, forward: !self.layoutManager!.isRTL(at: cursor))
        }
    }
    
    
    /// Moves the cursor to the beginning of the logical line and modifies the selection repeatedly (⇧⌥↑).
    override func moveParagraphBackwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveParagraphBackwardAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) { cursor, _ in
            (self.string as NSString).lineStartIndex(at: self.string.index(before: cursor))
        }
    }
    
    
    /// Moves the cursor to the end of the logical line and modifies the selection repeatedly (⇧⌥↓).
    override func moveParagraphForwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveParagraphForwardAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) { cursor, _ in
            (self.string as NSString).lineContentsEndIndex(at: self.string.index(after: cursor))
        }
    }
    
    
    /// Expands or reduces a single selection to the next word boundary, considering additional word separators.
    ///
    /// - Parameters:
    ///   - sender: The sender of the action.
    ///   - isLeft: Pass `true` when invoked from `moveWordLeftAndModifySelection(_:)`; otherwise, `false`.
    ///
    /// - Note:
    ///   This method modifies the selection using only super's selection-modification methods so that
    ///   the text view retains the correct cursor origin for subsequent single-selection changes.
    private func moveWordAndModifySelection(_ sender: Any?, left isLeft: Bool) {
        
        assert(!self.hasMultipleInsertions)
        
        // let the super change the selection to figure out the direction to expand (or reduce)
        let currentRange = self.selectedRange
        if isLeft {
            super.moveWordLeftAndModifySelection(sender)
        } else {
            super.moveWordRightAndModifySelection(sender)
        }
        let superRange = self.selectedRange
        
        // do nothing if the cursor has already reached the beginning/end
        guard currentRange != superRange else { return }
        
        // give up if both bounds are moved
        guard
            currentRange.lowerBound == superRange.lowerBound ||
            currentRange.upperBound == superRange.upperBound
        else { return }
        
        // find selection direction
        let isLowerOrigin = (currentRange.lowerBound == superRange.lowerBound)
        let cursor = isLowerOrigin ? currentRange.upperBound : currentRange.lowerBound
        let origin = isLowerOrigin ? superRange.lowerBound : superRange.upperBound
        
        // skip modifying the selection in RTL text as it is too complex
        // -> Additional word boundaries may be not so necessary in RTL text.
        guard !self.layoutManager!.isRTL(at: cursor) else { return }
        
        // calculate original selected range by taking additional word separators into consideration
        let newCursor = self.nextWord(from: cursor, forward: !isLeft)
        let newRange: NSRange = if (newCursor < origin && origin < cursor) || (cursor < origin && origin < newCursor) {
            NSRange(origin..<origin)
        } else if origin < newCursor {
            NSRange(origin..<newCursor)
        } else {
            NSRange(newCursor..<origin)
        }
        
        // manipulate only when the difference stemmed from the additional word boundaries
        let superCursor = isLowerOrigin ? superRange.upperBound : superRange.lowerBound
        let diffRange = (superCursor < newCursor) ? NSRange(superCursor..<newCursor) : NSRange(newCursor..<superCursor)
        guard !(self.string as NSString).rangeOfCharacter(from: Self.additionalWordSeparators, range: diffRange).isNotFound else { return }
        
        // adjust selection range character by character
        while self.selectedRange != newRange {
            if (self.selectedRange.upperBound > newRange.upperBound) ||
               (self.selectedRange.lowerBound > newRange.lowerBound)
            {
                super.moveBackwardAndModifySelection(self)
            } else {
                super.moveForwardAndModifySelection(self)
            }
        }
    }
    
    
    // MARK: Text View Methods - Command+Arrow
    
    /// Moves the cursor to the beginning of the current visual line (⌘←).
    override func moveToBeginningOfLine(_ sender: Any?) {
        
        self.moveCursors(affinity: .downstream) { range in
            self.locationOfBeginningOfLine(for: range.location)
        }
    }
    
    
    /// Moves the cursor to the beginning of the current visual line and modifies the selection (⇧⌘←).
    override func moveToBeginningOfLineAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            let location = self.locationOfBeginningOfLine(for: self.selectedRange.location)
            
            // repeat `moveBackwardAndModifySelection(_:)` until reaching the goal location
            // instead of setting `selectedRange` directly.
            // -> This avoids an issue where using ⇧→ immediately after this command
            //    expands the selection in the wrong direction. (2018-11, macOS 10.14, #863)
            while self.selectedRange.location > location {
                self.moveBackwardAndModifySelection(self)
            }
            return
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) { cursor, _ in
            self.locationOfBeginningOfLine(for: cursor)
        }
    }
    
    
    /// Moves the cursor to the end of the current visual line (⌘→).
    override func moveToEndOfLine(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveToEndOfLine(sender)
        }
        
        let length = self.attributedString().length
        self.moveCursors(affinity: .upstream) { range in
            self.layoutManager?.lineFragmentRange(at: range.upperBound).upperBound ?? length
        }
    }
    
    
    /// Moves the cursor to the end of the current visual line and modifies the selection (⇧⌘→).
    override func moveToEndOfLineAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveToEndOfLineAndModifySelection(sender)
        }
        
        let length = self.attributedString().length
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) { cursor, _ in
            self.layoutManager?.lineFragmentRange(at: cursor).upperBound ?? length
        }
    }
    
    
    // MARK: Text View Methods - Emacs
    
    /// Moves the cursor backward (^B).
    ///
    /// - Note: `opt↑` invokes first this method and then `moveToBeginningOfParagraph(_:)`.
    override func moveBackward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveBackward(sender)
        }
        
        self.moveLeft(sender)
    }
    
    
    /// Moves the cursor backward and modifies the selection (^⇧B).
    ///
    /// - Note: `opt⇧↓` invokes first this method and then `moveToEndOfParagraphAndModifySelection(_:)`.
    override func moveBackwardAndModifySelection(_ sender: Any?) {
        
        // -> The default implementation cannot handle CRLF line endings correctly (2022-02, macOS 12).
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveBackwardAndModifySelection(sender)
        }
        
        self.moveLeftAndModifySelection(sender)
    }
    
    
    /// Moves the cursor forward (^F).
    ///
    /// - Note: `opt↓` invokes first this method and then `moveToEndOfParagraph(_:)`.
    override func moveForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveForward(sender)
        }
        
        self.moveRight(sender)
    }
    
    
    /// Moves the cursor forward and modifies the selection (^⇧F).
    ///
    /// - Note: `opt⇧↓` invokes first this method and then `moveToEndOfParagraphAndModifySelection(_:)`.
    override func moveForwardAndModifySelection(_ sender: Any?) {
        
        // -> The default implementation cannot handle CRLF line endings correctly (2022-02, macOS 12).
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveForwardAndModifySelection(sender)
        }
        
        self.moveRightAndModifySelection(sender)
    }
    
    
    /// Moves the cursor to the beginning of the logical line (^A).
    ///
    /// - Note: `opt↑` invokes first `moveBackward(_:)` and then this method.
    override func moveToBeginningOfParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveToBeginningOfParagraph(sender)
        }
        
        self.moveCursors(affinity: .downstream) { range in
            (self.string as NSString).lineStartIndex(at: range.lowerBound)
        }
    }
    
    
    /// Moves the cursor to the beginning of the logical line and modifies the selection (^⇧A).
    override func moveToBeginningOfParagraphAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveToBeginningOfParagraphAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) { cursor, _ in
            (self.string as NSString).lineStartIndex(at: cursor)
        }
    }
    
    
    /// Moves the cursor to the end of the logical line (^E).
    ///
    /// - Note: `opt↓` invokes first `moveForward(_:)` and then this method.
    override func moveToEndOfParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveToEndOfParagraph(sender)
        }
        
        self.moveCursors(affinity: .upstream) { range in
            (self.string as NSString).lineContentsEndIndex(at: range.upperBound)
        }
    }
    
    
    /// Moves the cursor to the end of the logical line and modifies the selection (^⇧E).
    override func moveToEndOfParagraphAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveToEndOfParagraphAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) { cursor, _ in
            (self.string as NSString).lineContentsEndIndex(at: cursor)
        }
    }
    
    
    /// Moves the cursor to the beginning of the word (^⌥B).
    override func moveWordBackward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveWordBackward(sender)
        }
        
        self.moveCursors(affinity: .downstream) { range in
            self.nextWord(from: range.lowerBound, forward: false)
        }
    }
    
    
    /// Moves the cursor to the beginning of the word and modifies the selection (^⌥⇧B).
    override func moveWordBackwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveWordBackwardAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) { cursor, _ in
            self.nextWord(from: cursor, forward: false)
        }
    }
    
    
    /// Moves the cursor to the end of the word (^⌥F).
    override func moveWordForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveWordForward(sender)
        }
        
        self.moveCursors(affinity: .upstream) { range in
            self.nextWord(from: range.upperBound, forward: true)
        }
    }
    
    
    /// Moves the cursor to the end of the word and modifies the selection (^⌥⇧F).
    override func moveWordForwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveWordForwardAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) { cursor, _ in
            self.nextWord(from: cursor, forward: true)
        }
    }
    
    // The following actions are also part of NSStandardKeyBindingResponding but are not implemented
    // because they appear just to bridge to the `moveTo{Beginning|End}OfLine*` series. (2019-01, macOS 10.14)
    
    // moveToLeftEndOfLine(_ sender: Any?)
    // moveToLeftEndOfLineAndModifySelection(_ sender: Any?)
    // moveToRightEndOfLine(_ sender: Any?)
    // moveToRightEndOfLineAndModifySelection(_ sender: Any?)
    
    
    // MARK: Text View Methods - Select
    
    /// Selects the logical line.
    override func selectParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.selectParagraph(sender)
        }
        
        let ranges = self.insertionRanges
            .map { self.selectionRange(forProposedRange: $0, granularity: .selectByParagraph) }
        
        self.selectedRanges = ranges as [NSValue]
        
        self.scrollRangeToVisible(NSRange(ranges.first!.lowerBound..<ranges.last!.upperBound))
    }
    
    
    /// Selects a word or the next instance of the current selection.
    override func selectWord(_ sender: Any?) {
        
        if self.selectedRange.isEmpty {
            // select words where the cursors are located
            self.selectedRanges = self.insertionRanges.map { self.wordRange(at: $0.location) } as [NSValue]
            
        } else {
            let selectedRanges = self.selectedRanges.map(\.rangeValue)
            
            // select the next instance
            guard let lastRange = selectedRanges.last else { return assertionFailure() }
            
            let string = self.string as NSString
            let selectedWord = string.substring(with: lastRange)
            var nextRange = string.range(of: selectedWord, range: NSRange(lastRange.upperBound..<string.length))
            
            // resume from the top of the document
            if nextRange.isNotFound {
                var location = 0
                repeat {
                    nextRange = string.range(of: selectedWord, range: NSRange(location..<lastRange.lowerBound))
                    location = nextRange.upperBound
                    
                    guard !nextRange.isNotFound else { return }
                    
                } while selectedRanges.contains(where: { $0.intersects(nextRange) })
            }
            
            self.selectedRanges.append(NSValue(range: nextRange))
            self.scrollRangeToVisible(nextRange)
        }
    }
    
    
    // MARK: Actions
    
    /// Adds an insertion point just above the first selected range (^⇧↑).
    @IBAction func selectColumnUp(_ sender: Any?) {
        
        self.addSelectedColumn(affinity: .downstream)
    }
    
    
    /// Adds an insertion point just below the last selected range (^⇧↓).
    @IBAction func selectColumnDown(_ sender: Any?) {
        
        self.addSelectedColumn(affinity: .upstream)
    }
    
    
    /// Splits selections by lines.
    @IBAction func splitSelectionByLines(_ sender: Any?) {
        
        guard let ranges = self.rangesForUserTextChange?.map(\.rangeValue) else { return }
        
        self.selectedRanges = ranges
            .flatMap(self.string.lineContentsRanges(for:)) as [NSValue]
    }
}


// MARK: -

extension EditorTextView {
    
    // MARK: Deletion
    
    /// Deletes forward (fn-Delete / ^D).
    override func deleteForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.deleteForward(sender)
        }
        
        guard self.multipleDelete(forward: true) else { return super.deleteForward(sender) }
    }
    
    
    /// Deletes to the end of the logical line (^K).
    override func deleteToEndOfParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.deleteToEndOfParagraph(sender)
        }
        
        self.moveToEndOfParagraphAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    /// Deletes to the beginning of the visual line (⌘-Delete).
    override func deleteToBeginningOfLine(_ sender: Any?) {
        
        // -> Do not invoke super, even with a single selection, because the behavior of
        //    `moveToBeginningOfLineAndModifySelection` differs from the default implementation.
        
        self.moveToBeginningOfLineAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    /// Deletes to the beginning of the word (⌥-Delete).
    override func deleteWordBackward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.deleteWordBackward(sender)
        }
        
        self.moveWordBackwardAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    /// Deletes to the end of the word (⌥⌦).
    override func deleteWordForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.deleteWordForward(sender)
        }
        
        self.moveWordForwardAndModifySelection(sender)
        self.deleteForward(sender)
    }
    
    
    // MARK: Editing
    
    /// Swaps the characters before and after the insertions (^T).
    override func transpose(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.transpose(sender)
        }
        
        let string = self.string as NSString
        
        var replacementRanges: [NSRange] = []
        var replacementStrings: [String] = []
        var selectedRanges: [NSRange] = []
        for range in self.insertionRanges.reversed() {
            guard range.isEmpty else {
                selectedRanges.append(range)
                continue
            }
            
            let lastIndex = string.index(before: range.location)
            let nextIndex = string.index(after: range.location)
            let lastCharacter = string.substring(with: NSRange(lastIndex..<range.location))
            let nextCharacter = string.substring(with: NSRange(range.location..<nextIndex))
            
            replacementStrings.append(nextCharacter + lastCharacter)
            replacementRanges.append(NSRange(lastIndex..<nextIndex))
            selectedRanges.append(NSRange(nextIndex..<nextIndex))
        }
        
        self.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: selectedRanges)
    }
}


extension EditorTextView {
    
    private static let additionalWordSeparators = CharacterSet(charactersIn: ".;")
    
    
    /// Returns the word range that includes the given location.
    ///
    /// - Parameter location: The character index to find the word range.
    /// - Returns: The range of the word.
    func wordRange(at location: Int) -> NSRange {
        
        let proposedWordRange = super.selectionRange(forProposedRange: NSRange(location: location, length: 0), granularity: .selectByWord)
        
        guard proposedWordRange.contains(location) else { return proposedWordRange }
        
        // treat `.` and `:` as word delimiters
        return (self.string as NSString).rangeOfCharacter(until: Self.additionalWordSeparators, at: location, range: proposedWordRange)
    }
    
    
    /// Returns the index of the first character of the word after or before the given index by taking custom additional word delimiters into consideration.
    ///
    /// - Parameters:
    ///   - location: The index in the attribute string.
    ///   - isForward: `true` to search forward; otherwise, `false`.
    /// - Returns: The index of the first character of the word after the given index if `isForward` is `true`; otherwise, after the given index.
    private func nextWord(from location: Int, forward isForward: Bool) -> Int {
        
        self.textStorage!.nextWord(from: location, forward: isForward, delimiters: Self.additionalWordSeparators)
    }
}


private extension NSAttributedString {
    
    /// Returns the index of the first character of the word after or before the given index by taking custom additional word delimiters into consideration.
    ///
    /// - Parameters:
    ///   - location: The index in the attributed string.
    ///   - isForward: `true` to search forward; otherwise, `false`.
    ///   - delimiters: Additional characters to treat as word delimiters.
    /// - Returns: The index of the first character of the word after the given index if `isForward` is `true`; otherwise, after the given index.
    final func nextWord(from location: Int, forward isForward: Bool, delimiters: CharacterSet) -> Int {
        
        assert(location >= 0)
        assert(location <= self.length)
        
        guard (isForward && location < self.length) || (!isForward && location > 0) else { return location }
        
        let rawNextIndex = self.nextWord(from: location, forward: isForward)
        
        guard !delimiters.isEmpty else { return rawNextIndex }
        
        let lastCharacterIndex = isForward ? max(rawNextIndex - 1, 0) : rawNextIndex
        let characterRange = (self.string as NSString).rangeOfComposedCharacterSequence(at: lastCharacterIndex)
        let nextIndex = isForward ? characterRange.upperBound : characterRange.lowerBound
        
        let options: NSString.CompareOptions = isForward ? [.literal] : [.literal, .backwards]
        let range = isForward ? (location + 1)..<nextIndex : nextIndex..<(location - 1)
        let trimmedRange = (self.string as NSString).rangeOfCharacter(from: delimiters, options: options, range: NSRange(range))
        
        guard !trimmedRange.isNotFound else { return nextIndex }
        
        return isForward ? trimmedRange.lowerBound : trimmedRange.upperBound
    }
}
