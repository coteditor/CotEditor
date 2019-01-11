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
//  © 2019 1024jp
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
    ///   This rule is valid for all `move*{Left|Right}(_:)` actions.
    override func moveLeft(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveLeft(sender) }
        
        self.moveCursors(affinity: .downstream) { (self.string as NSString).index(before: $0.lowerBound) }
    }
    
    
    /// move cursor backward and modify selection (⇧←).
    override func moveLeftAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveLeftAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return ((self.string as NSString).index(before: range.upperBound), range.lowerBound)
            } else {
                return ((self.string as NSString).index(before: range.lowerBound), range.upperBound)
            }
        }
    }
    
    
    /// move cursor forward (→)
    override func moveRight(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveRight(sender) }
        
        self.moveCursors(affinity: .upstream) { (self.string as NSString).index(after: $0.upperBound) }
    }
    
    
    /// move cursor forward and modify selection (⇧→).
    override func moveRightAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveRightAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .upstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return ((self.string as NSString).index(after: range.lowerBound), range.upperBound)
            } else {
                return ((self.string as NSString).index(after: range.upperBound), range.lowerBound)
            }
        }
    }
    
    
    /// move cursor up to the upper visual line (↑ / ^P)
    override func moveUp(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveUp(sender) }
        
        self.moveCursors(affinity: .downstream) { self.upperInsertionLocation(of: $0.lowerBound) }
    }
    
    
    /// move cursor up and modify selection (⇧↑ / ^⇧P).
    override func moveUpAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveUpAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return (self.upperInsertionLocation(of: range.upperBound), range.lowerBound)
            } else {
                return (self.upperInsertionLocation(of: range.lowerBound), range.upperBound)
            }
        }
    }
    
    
    /// move cursor down to the lower visual line (↓ / ^N)
    override func moveDown(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveDown(sender) }
        
        self.moveCursors(affinity: .downstream) { self.lowerInsertionLocation(of: $0.upperBound) }
    }
    
    
    /// move cursor down and modify selection (⇧↓ / ^⇧N).
    override func moveDownAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveDownAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return (self.lowerInsertionLocation(of: range.lowerBound), range.upperBound)
            } else {
                return (self.lowerInsertionLocation(of: range.upperBound), range.lowerBound)
            }
        }
    }
    
    
    
    // MARK: Text View Methods - Option+Arrow
    
    /// move cursor to the beginning of the word continuasly (opt←)
    override func moveWordLeft(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordLeft(sender) }
        
        self.moveCursors(affinity: .downstream) { self.textStorage!.nextWord(from: $0.lowerBound, forward: false) }
    }
    
    
    /// move cursor to the beginning of the word and modify selection continuasly (⇧opt←).
    override func moveWordLeftAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordLeftAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return (self.textStorage!.nextWord(from: range.upperBound, forward: false), range.lowerBound)
            } else {
                return (self.textStorage!.nextWord(from: range.lowerBound, forward: false), range.upperBound)
            }
        }
    }
    
    
    /// move cursor to the end of the word continuasly (opt→)
    override func moveWordRight(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordRight(sender) }
        
        self.moveCursors(affinity: .upstream) { self.textStorage!.nextWord(from: $0.upperBound, forward: true) }
    }
    
    
    /// move cursor to the end of the word and modify selection continuasly (⇧opt→).
    override func moveWordRightAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordRightAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .upstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return (self.textStorage!.nextWord(from: range.lowerBound, forward: true), range.upperBound)
            } else {
                return (self.textStorage!.nextWord(from: range.upperBound, forward: true), range.lowerBound)
            }
        }
    }
    
    
    /// move cursor to the beginning of the logical line and modify selection continuasly (⇧opt↑).
    override func moveParagraphBackwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveParagraphBackwardAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return ((self.string as NSString).lineRange(at: self.string.index(before: range.upperBound)).lowerBound, range.lowerBound)
            } else {
                return ((self.string as NSString).lineRange(at: self.string.index(before: range.lowerBound)).lowerBound, range.upperBound)
            }
        }
    }
    
    
    /// move cursor to the end of the logical line and modify selection continuasly (⇧opt↓).
    override func moveParagraphForwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveParagraphForwardAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .upstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return ((self.string as NSString).lineRange(at: self.string.index(after: range.lowerBound), excludingLastLineEnding: true).upperBound, range.upperBound)
            } else {
                return ((self.string as NSString).lineRange(at: self.string.index(after: range.upperBound), excludingLastLineEnding: true).upperBound, range.lowerBound)
            }
        }
    }
    
    
    
    // MARK: Text View Methods - Command+Arrow
    
    /// move cursor to the beginning of the current visual line (⌘←)
    override func moveToBeginningOfLine(_ sender: Any?) {
        
        self.moveCursors(affinity: .downstream) { self.locationOfBeginningOfLine(for: $0) }
    }
    
    
    /// move cursor to the beginning of the current visual line and modify selection (⇧⌘←).
    override func moveToBeginningOfLineAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else {
            let location = self.locationOfBeginningOfLine(for: self.selectedRange)
            
            // repeat `moveBackwardAndModifySelection(_:)` until reaching to the goal location,
            // instead of setting `selectedRange` directly.
            // -> To avoid an issue that changing selection by shortcut ⇧→ just after this command
            //    expands the selection to a wrong direction. (2018-11 macOS 10.14 #863)
            while self.selectedRange.location > location {
                self.moveBackwardAndModifySelection(self)
            }
            return
        }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return (self.locationOfBeginningOfLine(for: range), range.lowerBound)
            } else {
                return (self.locationOfBeginningOfLine(for: range), range.upperBound)
            }
        }
    }
    
    
    /// move cursor to the end of the current visual line (⌘→)
    override func moveToEndOfLine(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveToEndOfLine(sender) }
        
        let length = self.attributedString().length
        self.moveCursors(affinity: .upstream) { self.layoutManager?.lineFragmentRange(at: $0.upperBound).upperBound ?? length }
    }
    
    
    /// move cursor to the end of the current visual line and modify selection (⇧⌘→).
    override func moveToEndOfLineAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveToEndOfLineAndModifySelection(sender) }
        
        let length = self.attributedString().length
        self.moveCursorsAndModifySelection(affinity: .upstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return (self.layoutManager?.lineFragmentRange(at: range.upperBound).upperBound ?? length, range.upperBound)
            } else {
                return (self.layoutManager?.lineFragmentRange(at: range.upperBound).upperBound ?? length, range.lowerBound)
            }
        }
    }
    
    
    
    // MARK: Text View Methods - Emacs
    
    /// Move cursor backward (^B).
    ///
    /// - Note: `opt↑` invokes first this method and then `moveToBeginningOfParagraph(_:)`.
    override func moveBackward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveBackward(sender) }
        
        self.moveLeft(sender)
    }
    
    
    /// Move cursor backward and modify selection (^⇧B).
    ///
    /// - Note: `opt⇧↓` invokes first this method and then `moveToEndOfParagraphAndModifySelection(_:)`.
    override func moveBackwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveBackwardAndModifySelection(sender) }
        
        self.moveLeftAndModifySelection(sender)
    }
    
    
    /// Move cursor forward (^F).
    ///
    /// - Note: `opt↓` invokes first this method and then `moveToEndOfParagraph(_:)`.
    override func moveForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveForward(sender) }
        
        self.moveRight(sender)
    }
    
    
    /// Move cursor forward and modify selection (^⇧F).
    ///
    /// - Note: `opt⇧↓` invokes first this method and then `moveToEndOfParagraphAndModifySelection(_:)`.
    override func moveForwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveForwardAndModifySelection(sender) }
        
        self.moveRightAndModifySelection(sender)
    }
    
    
    /// Move cursor to the beginning of the logical line (^A).
    ///
    /// - Note: `opt↑` invokes first `moveBackward(_:)` and then this method.
    override func moveToBeginningOfParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveToBeginningOfParagraph(sender) }
        
        self.moveCursors(affinity: .downstream) { (self.string as NSString).lineRange(at: $0.lowerBound).lowerBound }
    }
    
    
    /// move cursor to the beginning of the logical line and modify selection (^⇧A).
    override func moveToBeginningOfParagraphAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveToBeginningOfParagraphAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return ((self.string as NSString).lineRange(at: range.upperBound).lowerBound, range.lowerBound)
            } else {
                return ((self.string as NSString).lineRange(at: range.lowerBound).lowerBound, range.upperBound)
            }
        }
    }
    
    
    /// Move cursor to the end of the logical line (^E).
    ///
    /// - Note: `opt↓` invokes first `moveForward(_:)` and then this method.
    override func moveToEndOfParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveToEndOfParagraph(sender) }
        
        self.moveCursors(affinity: .upstream) { (self.string as NSString).lineRange(at: $0.upperBound, excludingLastLineEnding: true).upperBound }
    }
    
    
    /// move cursor to the end of the logical line and modify selection (^⇧E).
    override func moveToEndOfParagraphAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveToEndOfParagraphAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .upstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return ((self.string as NSString).lineRange(at: range.lowerBound, excludingLastLineEnding: true).upperBound, range.upperBound)
            } else {
                return ((self.string as NSString).lineRange(at: range.upperBound, excludingLastLineEnding: true).upperBound, range.lowerBound)
            }
        }
    }
    
    
    /// move cursor to the beginning of the word (^⌥B)
    override func moveWordBackward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordBackward(sender) }
        
        self.moveCursors(affinity: .downstream) { self.textStorage!.nextWord(from: $0.lowerBound, forward: false) }
    }
    
    
    /// move cursor to the beginning of the word and modify selection (^⌥⇧B).
    override func moveWordBackwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordBackwardAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return (self.textStorage!.nextWord(from: range.upperBound, forward: false), range.lowerBound)
            } else {
                return (self.textStorage!.nextWord(from: range.lowerBound, forward: false), range.upperBound)
            }
        }
    }
    
    
    /// move cursor to the end of the word (^⌥F)
    override func moveWordForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordForward(sender) }
        
        self.moveCursors(affinity: .upstream) { self.textStorage!.nextWord(from: $0.upperBound, forward: true) }
    }
    
    
    /// move cursor to the end of the word and modify selection (^⌥⇧F).
    override func moveWordForwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordForwardAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .upstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return (self.textStorage!.nextWord(from: range.lowerBound, forward: true), range.upperBound)
            } else {
                return (self.textStorage!.nextWord(from: range.upperBound, forward: true), range.lowerBound)
            }
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
        
        guard self.hasMultipleInsertions else { return super.selectParagraph(sender) }
        
        let ranges = self.insertionRanges.map { (self.string as NSString).lineRange(for: $0) }
        
        self.selectedRanges = ranges as [NSValue]
        
        self.scrollRangeToVisible(NSRange(ranges.first!.lowerBound..<ranges.last!.upperBound))
    }
    
    
    /// select word
    override func selectWord(_ sender: Any?) {
        
        if self.selectedRange.length == 0 {
            // select words where the cursors locate
            self.selectedRanges = self.insertionRanges.map { self.wordRange(at: $0.location) } as [NSValue]
            
        } else {
            // select next instance
            guard let lastRange = self.selectedRanges.last as? NSRange else { return assertionFailure() }
            
            let string = self.string as NSString
            let selectedWord = string.substring(with: lastRange)
            let nextRange = string.range(of: selectedWord, range: NSRange(lastRange.upperBound..<string.length))
            
            guard nextRange != .notFound else { return }
            
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
            let character = event.charactersIgnoringModifiers?.utf16.first
            else { return false }
        
        switch Int(character) {
        case NSUpArrowFunctionKey:
            self.doCommand(by: #selector(selectColumnUp))
            return true
            
        case NSDownArrowFunctionKey:
            self.doCommand(by: #selector(selectColumnDown))
            return true
            
        default:
             return false
        }
    }
    
    
    /// add insertion point just above the first selected range (^⇧↑)
    @IBAction func selectColumnUp(_ sender: Any?) {
        
        let ranges = self.insertionRanges
        let baseRange = ranges.first!
        let lowerBound = self.upperInsertionLocation(of: baseRange.lowerBound)
        let upperBound = self.upperInsertionLocation(of: baseRange.upperBound)
        let range = NSRange(lowerBound..<upperBound)
        
        let insertionRanges = [range] + ranges
        
        guard let set = self.prepareForSelectionUpdate(insertionRanges) else { return }
        
        self.setSelectedRanges(set.selectedRanges, affinity: .downstream, stillSelecting: false)
        self.insertionLocations = set.insertionLocations
        self.scrollRangeToVisible(range)
    }
    
    
    /// add insertion point just below the last selected range (^⇧↓)
    @IBAction func selectColumnDown(_ sender: Any?) {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { assertionFailure(); return }
        
        let ranges = self.insertionRanges
        let newRanges = layoutManager.verticalRanges(in: NSRange(ranges.first!.lowerBound..<ranges.last!.upperBound), baseRange: ranges[0], in: textContainer)
        
        guard let set = self.prepareForSelectionUpdate(newRanges) else { return }
        
        self.setSelectedRanges(set.selectedRanges, affinity: .upstream, stillSelecting: false)
        self.insertionLocations = set.insertionLocations
        self.scrollRangeToVisible(newRanges.last!)
    }
    
}



extension NSLayoutManager {
    
    func verticalRanges(in range: NSRange, baseRange: NSRange, in textContainer: NSTextContainer) -> [NSRange] {
        
        let glyphRange = self.glyphRange(forCharacterRange: baseRange, actualCharacterRange: nil)
        let lowerRect = self.boundingRect(forGlyphRange: NSRange(location: glyphRange.lowerBound, length: 0), in: textContainer)
        let upperRect = self.boundingRect(forGlyphRange: NSRange(location: glyphRange.upperBound, length: 0), in: textContainer)
        let baseRect = NSRect(x: min(lowerRect.minX, upperRect.minX), y: 0,
                              width: abs(lowerRect.minX - upperRect.minX), height: 1)
        
        var ranges: [NSRange] = []
        var targetRect: NSRect = .zero
        self.enumeratelineFragmentUsedRects(in: range) { (rect) in
            targetRect = baseRect.offsetBy(dx: 0, dy: rect.midY)
//            guard rect.intersects(targetRect) else { return }
            
            ranges.append(self.characterRange(for: targetRect, in: textContainer))
        }
        
        assert(!ranges.isEmpty)
        
        targetRect.origin.y = targetRect.maxY + targetRect.height
        moof(targetRect)
        ranges.append(self.characterRange(for: targetRect, in: textContainer))
        moof(ranges)
        return ranges
    }
    
    
    private func characterRange(for rect: NSRect, in textContainer: NSTextContainer) -> NSRange {
        
        let lowerGlyphIndex = self.glyphIndex(for: NSPoint(x: rect.minX, y: rect.minY), in: textContainer)
        let upperGlyphIndex = self.glyphIndex(for: NSPoint(x: rect.maxX, y: rect.minY), in: textContainer)
        
        return self.characterRange(forGlyphRange: NSRange(lowerGlyphIndex..<upperGlyphIndex), actualGlyphRange: nil)
    }
    
    
    private func enumeratelineFragmentUsedRects(in characterRange: NSRange, body: (_ usedLineRect: NSRect) -> Void) {
        
        let glyphRange = self.glyphRange(forCharacterRange: characterRange, actualCharacterRange: nil)
        
        // enumerate visible line numbers
        var glyphIndex = glyphRange.lowerBound
        repeat {  // process logical lines
            var effectiveRange = NSRange.notFound
            let rect = self.lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
            body(rect)
            
            glyphIndex = effectiveRange.upperBound
        } while (glyphIndex < glyphRange.upperBound)
        
        guard  glyphRange.upperBound == self.numberOfGlyphs else { return }
        
        body(self.extraLineFragmentUsedRect)
    }
    
}



// MARK: - Editing

extension EditorTextView {
    
    /// swap characters before and after insertions (^T)
    override func transpose(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.transpose(sender) }
        
        let string = self.string as NSString
        
        var replacementRanges: [NSRange] = []
        var replacementStrings: [String] = []
        var selectedRanges: [NSRange] = []
        for range in self.insertionRanges.reversed() {
            guard range.length == 0 else {
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



// MARK: - Deletion

extension EditorTextView {
    
    /// delete forward (fn+delete / ^D)
    override func deleteForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.deleteForward(sender) }
        
        self.moveForwardAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    /// delete to the end of logical line (^K)
    override func deleteToEndOfParagraph(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.deleteToEndOfParagraph(sender) }
        
        self.moveToEndOfParagraphAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    /// delete to the beginning of visual line (command+delete)
    override func deleteToBeginningOfLine(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.deleteToBeginningOfLine(sender) }
        
        self.moveToBeginningOfLineAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    /// delete to the biginning of word (opt+delete)
    override func deleteWordBackward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.deleteWordBackward(sender) }
        
        self.moveWordForwardAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
    
    /// delete to the end of word (opt⌦)
    override func deleteWordForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.deleteWordForward(sender) }
        
        self.moveWordBackwardAndModifySelection(sender)
        self.deleteBackward(sender)
    }
    
}
