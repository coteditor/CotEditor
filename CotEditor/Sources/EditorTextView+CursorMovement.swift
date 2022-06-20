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
//  © 2019-2022 1024jp
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

extension EditorTextView {
    
    // MARK: Text View Methods - Arrow
    
    /// Move cursor backward (←).
    ///
    /// - Note:
    ///   Although the method name contains "Left", it will be adjusted intelligently in vertical/RTL layout mode.
    ///   This rule seems to be valid for all `move*{Left|Right}(_:)` actions.
    override func moveLeft(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveLeft(sender)
        }
        
        self.moveCursors(affinity: .downstream) {
            if $0.isEmpty {
                return self.layoutManager!.leftCharacterIndex(of: $0.location, baseWritingDirection: self.baseWritingDirection)
            } else {
                return self.layoutManager!.isRTL(at: $0.upperBound) ? $0.upperBound : $0.lowerBound
            }
        }
    }
    
    
    /// move cursor backward and modify selection (⇧←).
    override func moveLeftAndModifySelection(_ sender: Any?) {
        
        // -> The default implementation cannot handle CRLF line endings correctly (2022-02 macOS 12).
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveLeftAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) {
            self.layoutManager!.leftCharacterIndex(of: $0, baseWritingDirection: self.baseWritingDirection)
        }
    }
    
    
    /// move cursor forward (→)
    override func moveRight(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveRight(sender)
        }
        
        self.moveCursors(affinity: .upstream) {
            if $0.isEmpty {
                return self.layoutManager!.rightCharacterIndex(of: $0.location, baseWritingDirection: self.baseWritingDirection)
            } else {
                return self.layoutManager!.isRTL(at: $0.lowerBound) ? $0.lowerBound : $0.upperBound
            }
        }
    }
    
    
    /// move cursor forward and modify selection (⇧→).
    override func moveRightAndModifySelection(_ sender: Any?) {
        
        // -> The default implementation cannot handle CRLF line endings correctly (2022-02 macOS 12).
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveRightAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) {
            self.layoutManager!.rightCharacterIndex(of: $0, baseWritingDirection: self.baseWritingDirection)
        }
    }
    
    
    /// move cursor up to the upper visual line (↑ / ^P)
    override func moveUp(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveUp(sender)
        }
        
        self.moveCursors(affinity: .downstream) {
            self.upperInsertionLocation(of: $0.lowerBound)
        }
    }
    
    
    /// move cursor up and modify selection (⇧↑ / ^⇧P).
    override func moveUpAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveUpAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) {
            self.upperInsertionLocation(of: $0)
        }
    }
    
    
    /// move cursor down to the lower visual line (↓ / ^N)
    override func moveDown(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveDown(sender)
        }
        
        self.moveCursors(affinity: .downstream) {
            self.lowerInsertionLocation(of: $0.upperBound)
        }
    }
    
    
    /// move cursor down and modify selection (⇧↓ / ^⇧N).
    override func moveDownAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveDownAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .downstream) {
            self.lowerInsertionLocation(of: $0)
        }
    }
    
    
    
    // MARK: Text View Methods - Option+Arrow
    
    /// move cursor to the beginning of the word continuasly (opt←)
    override func moveWordLeft(_ sender: Any?) {
        
        // find word boundary myself
        // -> The super.moveWordLef(_:) uses `textStorage.nextWord(from: $0.lowerBound, forward: isRTL)`
        //    and it doesn't stop at punctuation marks, such as `.` and `:` (2019-06).
        
        self.moveCursors(affinity: .downstream) {
            self.textStorage!.nextWord(from: $0.lowerBound, forward: self.layoutManager!.isRTL(at: $0.upperBound), delimiters: .additionalWordSeparators)
        }
    }
    
    
    /// move cursor to the beginning of the word and modify selection continuasly (⇧opt←).
    override func moveWordLeftAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return self.moveWordAndModifySelection(sender, left: true)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) {
            self.textStorage!.nextWord(from: $0, forward: self.layoutManager!.isRTL(at: $0), delimiters: .additionalWordSeparators)
        }
    }
    
    
    /// move cursor to the end of the word continuasly (opt→)
    override func moveWordRight(_ sender: Any?) {
        
        // find word boundary myself (cf. moveWordLeft(_:))
        
        self.moveCursors(affinity: .upstream) {
            self.textStorage!.nextWord(from: $0.upperBound, forward: !self.layoutManager!.isRTL(at: $0.upperBound), delimiters: .additionalWordSeparators)
        }
    }
    
    
    /// move cursor to the end of the word and modify selection continuasly (⇧opt→).
    override func moveWordRightAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return self.moveWordAndModifySelection(sender, left: false)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) {
            self.textStorage!.nextWord(from: $0, forward: !self.layoutManager!.isRTL(at: $0), delimiters: .additionalWordSeparators)
        }
    }
    
    
    /// move cursor to the beginning of the logical line and modify selection continuasly (⇧opt↑).
    override func moveParagraphBackwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveParagraphBackwardAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) {
            (self.string as NSString).lineStartIndex(at: self.string.index(before: $0))
        }
    }
    
    
    /// move cursor to the end of the logical line and modify selection continuasly (⇧opt↓).
    override func moveParagraphForwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveParagraphForwardAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) {
            (self.string as NSString).lineContentsEndIndex(at: self.string.index(after: $0))
        }
    }
    
    
    /// Expand/reduce single selection to next word boundary by taking additional word separators into consideration.
    ///
    /// - Parameter sender: The sender of the action.
    /// - Parameter isLeft: `true` if this method is invoked from `moveWordLeftAndModifySelection(_:)`, otherwise `false`.
    ///
    /// - Note:
    /// Because the other selection modification keybindings for single cursor use the textView's methods,
    /// this method changes the selection by using only super's slection modification methods
    /// to let the textView remember the correct cursor origin for following single selection modification.
    private func moveWordAndModifySelection(_ sender: Any?, left isLeft: Bool) {
        
        assert(!self.hasMultipleInsertions)
        
        // let super change the selection to figure out the direction to expand (or reduce)
        let currentRange = self.selectedRange
        if isLeft {
            super.moveWordLeftAndModifySelection(sender)
        } else {
            super.moveWordRightAndModifySelection(sender)
        }
        let superRange = self.selectedRange
        
        // do nothing if the cursor has already reached the beginning/end
        guard currentRange != superRange else { return }
        
        // find selection direction
        // -> use superRange for the origin to take the case into consideration
        //    when the character next to the cursor is an invisible character
        let isLowerOrigin = (currentRange.lowerBound == superRange.lowerBound)
        let cursor = isLowerOrigin ? currentRange.upperBound : currentRange.lowerBound
        let origin = isLowerOrigin ? superRange.lowerBound : superRange.upperBound
        
        // skip modifying the selection in RTL text as it is too complex
        // -> Additional word boundaries may be not so nessessory in RTL text.
        guard !self.layoutManager!.isRTL(at: cursor) else { return }
        
        // calculate original selected range by taking additional word separators into consideration
        let newCursor = self.textStorage!.nextWord(from: cursor, forward: !isLeft, delimiters: .additionalWordSeparators)
        let newRange = (origin < newCursor) ? NSRange(origin..<newCursor) : NSRange(newCursor..<origin)
        
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
    
    /// move cursor to the beginning of the current visual line (⌘←)
    override func moveToBeginningOfLine(_ sender: Any?) {
        
        self.moveCursors(affinity: .downstream) {
            self.locationOfBeginningOfLine(for: $0.location)
        }
    }
    
    
    /// move cursor to the beginning of the current visual line and modify selection (⇧⌘←).
    override func moveToBeginningOfLineAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            let location = self.locationOfBeginningOfLine(for: self.selectedRange.location)
            
            // repeat `moveBackwardAndModifySelection(_:)` until reaching to the goal location,
            // instead of setting `selectedRange` directly.
            // -> To avoid an issue that changing selection by shortcut ⇧→ just after this command
            //    expands the selection to the wrong direction. (2018-11 macOS 10.14 #863)
            while self.selectedRange.location > location {
                self.moveBackwardAndModifySelection(self)
            }
            return
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) {
            self.locationOfBeginningOfLine(for: $0)
        }
    }
    
    
    /// move cursor to the end of the current visual line (⌘→)
    override func moveToEndOfLine(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveToEndOfLine(sender)
        }
        
        let length = self.attributedString().length
        self.moveCursors(affinity: .upstream) {
            self.layoutManager?.lineFragmentRange(at: $0.upperBound).upperBound ?? length
        }
    }
    
    
    /// move cursor to the end of the current visual line and modify selection (⇧⌘→).
    override func moveToEndOfLineAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveToEndOfLineAndModifySelection(sender)
        }
        
        let length = self.attributedString().length
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) {
            self.layoutManager?.lineFragmentRange(at: $0).upperBound ?? length
        }
    }
    
    
    
    // MARK: Text View Methods - Emacs
    
    /// Move cursor backward (^B).
    ///
    /// - Note: `opt↑` invokes first this method and then `moveToBeginningOfParagraph(_:)`.
    override func moveBackward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveBackward(sender)
        }
        
        self.moveLeft(sender)
    }
    
    
    /// Move cursor backward and modify selection (^⇧B).
    ///
    /// - Note: `opt⇧↓` invokes first this method and then `moveToEndOfParagraphAndModifySelection(_:)`.
    override func moveBackwardAndModifySelection(_ sender: Any?) {
        
        // -> The default implementation cannot handle CRLF line endings correctly (2022-02 macOS 12).
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveBackwardAndModifySelection(sender)
        }
        
        self.moveLeftAndModifySelection(sender)
    }
    
    
    /// Move cursor forward (^F).
    ///
    /// - Note: `opt↓` invokes first this method and then `moveToEndOfParagraph(_:)`.
    override func moveForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveForward(sender)
        }
        
        self.moveRight(sender)
    }
    
    
    /// Move cursor forward and modify selection (^⇧F).
    ///
    /// - Note: `opt⇧↓` invokes first this method and then `moveToEndOfParagraphAndModifySelection(_:)`.
    override func moveForwardAndModifySelection(_ sender: Any?) {
        
        // -> The default implementation cannot handle CRLF line endings correctly (2022-02 macOS 12).
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveForwardAndModifySelection(sender)
        }
        
        self.moveRightAndModifySelection(sender)
    }
    
    
    /// Move cursor to the beginning of the logical line (^A).
    ///
    /// - Note: `opt↑` invokes first `moveBackward(_:)` and then this method.
    override func moveToBeginningOfParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveToBeginningOfParagraph(sender)
        }
        
        self.moveCursors(affinity: .downstream) {
            (self.string as NSString).lineStartIndex(at: $0.lowerBound)
        }
    }
    
    
    /// move cursor to the beginning of the logical line and modify selection (^⇧A).
    override func moveToBeginningOfParagraphAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveToBeginningOfParagraphAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) {
            (self.string as NSString).lineStartIndex(at: $0)
        }
    }
    
    
    /// Move cursor to the end of the logical line (^E).
    ///
    /// - Note: `opt↓` invokes first `moveForward(_:)` and then this method.
    override func moveToEndOfParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveToEndOfParagraph(sender)
        }
        
        self.moveCursors(affinity: .upstream) {
            (self.string as NSString).lineContentsEndIndex(at: $0.upperBound)
        }
    }
    
    
    /// move cursor to the end of the logical line and modify selection (^⇧E).
    override func moveToEndOfParagraphAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveToEndOfParagraphAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) {
            (self.string as NSString).lineContentsEndIndex(at: $0)
        }
    }
    
    
    /// move cursor to the beginning of the word (^⌥B)
    override func moveWordBackward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveWordBackward(sender)
        }
        
        self.moveCursors(affinity: .downstream) {
            self.textStorage!.nextWord(from: $0.lowerBound, forward: false, delimiters: .additionalWordSeparators)
        }
    }
    
    
    /// move cursor to the beginning of the word and modify selection (^⌥⇧B).
    override func moveWordBackwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveWordBackwardAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: false, affinity: .downstream) {
            self.textStorage!.nextWord(from: $0, forward: false, delimiters: .additionalWordSeparators)
        }
    }
    
    
    /// move cursor to the end of the word (^⌥F)
    override func moveWordForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.moveWordForward(sender)
        }
        
        self.moveCursors(affinity: .upstream) {
            self.textStorage!.nextWord(from: $0.upperBound, forward: true, delimiters: .additionalWordSeparators)
        }
    }
    
    
    /// move cursor to the end of the word and modify selection (^⌥⇧F).
    override func moveWordForwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions || self.lineEnding == .crlf else {
            return super.moveWordForwardAndModifySelection(sender)
        }
        
        self.moveCursorsAndModifySelection(forward: true, affinity: .upstream) {
            self.textStorage!.nextWord(from: $0, forward: true, delimiters: .additionalWordSeparators)
        }
    }
    
    // The following actions are also a part of NSStandardKeyBindingResponding but not implemented
    // since they seem just to bridge to `moveTo{Beginning|End}OfLine*` series. (2019-01 macOS 10.14)
    
    // moveToLeftEndOfLine(_ sender: Any?)
    // moveToLeftEndOfLineAndModifySelection(_ sender: Any?)
    // moveToRightEndOfLine(_ sender: Any?)
    // moveToRightEndOfLineAndModifySelection(_ sender: Any?)
    
    
    
    // MARK: Text View Methods - Select
    
    /// select logical line
    override func selectParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.selectParagraph(sender)
        }
        
        let ranges = self.insertionRanges.map { (self.string as NSString).lineRange(for: $0) }
        
        self.selectedRanges = ranges as [NSValue]
        
        self.scrollRangeToVisible(NSRange(ranges.first!.lowerBound..<ranges.last!.upperBound))
    }
    
    
    /// select word
    override func selectWord(_ sender: Any?) {
        
        if self.selectedRange.isEmpty {
            // select words where the cursors locate
            self.selectedRanges = self.insertionRanges.map { self.wordRange(at: $0.location) } as [NSValue]
            
        } else {
            let selectedRanges = self.selectedRanges.map(\.rangeValue)
            
            // select next instance
            guard let lastRange = selectedRanges.last else { return assertionFailure() }
            
            let string = self.string as NSString
            let selectedWord = string.substring(with: lastRange)
            var nextRange = string.range(of: selectedWord, range: NSRange(lastRange.upperBound..<string.length))
            
            // resume from the top of the document
            if nextRange == .notFound {
                var location = 0
                repeat {
                    nextRange = string.range(of: selectedWord, range: NSRange(location..<lastRange.lowerBound))
                    location = nextRange.upperBound
                    
                    guard nextRange != .notFound else { return }
                    
                } while selectedRanges.contains(where: { $0.intersects(nextRange) })
            }
            
            self.selectedRanges.append(NSValue(range: nextRange))
            self.scrollRangeToVisible(nextRange)
        }
    }
    
    
    
    // MARK: Actions
    
    /// process user's shortcut input
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        
        guard !super.performKeyEquivalent(with: event) else { return true }
        
        // interrupt for selectColumnUp/Down actions
        guard
            event.modifierFlags.intersection([.shift, .control, .option, .command]) == [.shift, .control],
            let key = event.specialKey
            else { return false }
        
        switch (key, self.layoutOrientation) {
            case (.upArrow, .horizontal),
                 (.rightArrow, .vertical):
                self.doCommand(by: #selector(selectColumnUp))
                return true
            
            case (.downArrow, .horizontal),
                 (.leftArrow, .vertical):
                self.doCommand(by: #selector(selectColumnDown))
                return true
            
            default:
                return false
        }
    }
    
    
    /// add insertion point just above the first selected range (^⇧↑)
    @IBAction func selectColumnUp(_ sender: Any?) {
        
        self.addSelectedColumn(affinity: .downstream)
    }
    
    
    /// add insertion point just below the last selected range (^⇧↓)
    @IBAction func selectColumnDown(_ sender: Any?) {
        
        self.addSelectedColumn(affinity: .upstream)
    }
    
}



// MARK: -

extension EditorTextView {
    
    // MARK: Deletion
    
    /// delete forward (fn+delete / ^D)
    override func deleteForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.deleteForward(sender)
        }
        
        guard self.multipleDelete(forward: true) else { return super.deleteForward(sender) }
    }
    
    
    /// delete to the end of logical line (^K)
    override func deleteToEndOfParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.deleteToEndOfParagraph(sender)
        }
        
        self.moveToEndOfParagraphAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    /// delete to the beginning of visual line (command+delete)
    override func deleteToBeginningOfLine(_ sender: Any?) {
        
        // -> Do not invoke super even with a single selection because the behavior of
        //    `moveToBeginningOfLineAndModifySelection` is different from the default implementation.
        
        self.moveToBeginningOfLineAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    /// delete to the biginning of word (opt+delete)
    override func deleteWordBackward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.deleteWordBackward(sender)
        }
        
        self.moveWordBackwardAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    /// delete to the end of word (opt⌦)
    override func deleteWordForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            return super.deleteWordForward(sender)
        }
        
        self.moveWordBackwardAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    
    // MARK: Editing
    
    /// swap characters before and after insertions (^T)
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



private extension CharacterSet {
    
    static let additionalWordSeparators = CharacterSet(charactersIn: ".")
}



private extension NSAttributedString {
    
    /// Returns the index of the first character of the word after or before the given index by taking custom additional word delimiters into consideration.
    ///
    /// - Parameters:
    ///   - location: The index in the attribute string.
    ///   - isForward: `true` if the search should be forward, otherwise false.
    ///   - delimiters: Additional characters to treat as word delimiters.
    /// - Returns: The index of the first character of the word after the given index if `isForward` is `true`; otherwise, after the given index.
    func nextWord(from location: Int, forward isForward: Bool, delimiters: CharacterSet) -> Int {
        
        assert(location >= 0)
        assert(location <= self.length)
        
        guard (isForward && location < self.length) || (!isForward && location > 0) else { return location }
        
        let rawNextIndex = self.nextWord(from: location, forward: isForward)
        let lastCharacterIndex = isForward ? max(rawNextIndex - 1, 0) : rawNextIndex
        let characterRange = (self.string as NSString).rangeOfComposedCharacterSequence(at: lastCharacterIndex)
        let nextIndex = isForward ? characterRange.upperBound : characterRange.lowerBound
        
        let options: NSString.CompareOptions = isForward ? [.literal] : [.literal, .backwards]
        let range = isForward ? (location + 1)..<nextIndex : nextIndex..<(location - 1)
        let trimmedRange = (self.string as NSString).rangeOfCharacter(from: delimiters, options: options, range: NSRange(range))
        
        guard trimmedRange != .notFound else { return nextIndex }
        
        return isForward ? trimmedRange.lowerBound : trimmedRange.upperBound
    }
    
}
