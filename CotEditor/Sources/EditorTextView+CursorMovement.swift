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
        
        self.moveCursors(affinity: .downstream) { max($0.lowerBound - 1, 0) }
    }
    
    
    /// move cursor backward and modify selection (⇧←).
    override func moveLeftAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveLeftAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return (max(range.upperBound - 1, 0), range.lowerBound)
            } else {
                return (max(range.lowerBound - 1, 0), range.upperBound)
            }
        }
    }
    
    
    /// move cursor forward (→)
    override func moveRight(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveRight(sender) }
        
        let length = self.attributedString().length
        self.moveCursors(affinity: .upstream) { min($0.upperBound + 1, length) }
    }
    
    
    /// move cursor forward and modify selection (⇧→).
    override func moveRightAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveRightAndModifySelection(sender) }
        
        let length = self.attributedString().length
        self.moveCursorsAndModifySelection(affinity: .upstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return (min(range.lowerBound + 1, length), range.upperBound)
            } else {
                return (min(range.upperBound + 1, length), range.lowerBound)
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
        
        self.moveCursors(affinity: .downstream) { self.wordRange(at: max($0.lowerBound - 1, 0)).lowerBound }
    }
    
    
    /// move cursor to the beginning of the word and modify selection continuasly (⇧opt←).
    override func moveWordLeftAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordLeftAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return (self.wordRange(at: max(range.upperBound - 1, 0)).lowerBound, range.lowerBound)
            } else {
                return (self.wordRange(at: max(range.lowerBound - 1, 0)).lowerBound, range.upperBound)
            }
        }
    }
    
    
    /// move cursor to the end of the word continuasly (opt→)
    override func moveWordRight(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordRight(sender) }
        
        let length = self.attributedString().length
        self.moveCursors(affinity: .upstream) { self.wordRange(at: min($0.upperBound + 1, length)).upperBound }
    }
    
    
    /// move cursor to the end of the word and modify selection continuasly (⇧opt→).
    override func moveWordRightAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordRightAndModifySelection(sender) }
        
        let length = self.attributedString().length
        self.moveCursorsAndModifySelection(affinity: .upstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return (self.wordRange(at: min(range.lowerBound + 1, length)).upperBound, range.upperBound)
            } else {
                return (self.wordRange(at: min(range.upperBound + 1, length)).upperBound, range.lowerBound)
            }
        }
    }
    
    
    /// move cursor to the beginning of the logical line and modify selection continuasly (⇧opt↑).
    override func moveParagraphBackwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveParagraphBackwardAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return ((self.string as NSString).lineRange(at: max(range.upperBound - 1, 0)).lowerBound, range.lowerBound)
            } else {
                return ((self.string as NSString).lineRange(at: max(range.lowerBound - 1, 0)).lowerBound, range.upperBound)
            }
        }
    }
    
    
    /// move cursor to the end of the logical line and modify selection continuasly (⇧opt↓).
    override func moveParagraphForwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveParagraphForwardAndModifySelection(sender) }
        
        let length = self.attributedString().length
        self.moveCursorsAndModifySelection(affinity: .upstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return ((self.string as NSString).lineRange(at: min(range.lowerBound + 1, length), excludingLastLineEnding: true).upperBound, range.upperBound)
            } else {
                return ((self.string as NSString).lineRange(at: min(range.upperBound + 1, length), excludingLastLineEnding: true).upperBound, range.lowerBound)
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
        
        self.moveCursors(affinity: .downstream) { self.wordRange(at: $0.lowerBound).lowerBound }
    }
    
    
    /// move cursor to the beginning of the word and modify selection (^⌥⇧B).
    override func moveWordBackwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordBackwardAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .downstream) { (range, origin) in
            if let origin = origin, origin < range.upperBound {
                return (self.wordRange(at: range.upperBound).lowerBound, range.lowerBound)
            } else {
                return (self.wordRange(at: range.lowerBound).lowerBound, range.upperBound)
            }
        }
    }
    
    
    /// move cursor to the end of the word (^⌥F)
    override func moveWordForward(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordForward(sender) }
        
        self.moveCursors(affinity: .upstream) { self.wordRange(at: $0.upperBound).upperBound }
    }
    
    
    /// move cursor to the end of the word and modify selection (^⌥⇧F).
    override func moveWordForwardAndModifySelection(_ sender: Any?) {
        
        guard self.hasMultipleInsertions else { return super.moveWordForwardAndModifySelection(sender) }
        
        self.moveCursorsAndModifySelection(affinity: .upstream) { (range, origin) in
            if let origin = origin, origin > range.lowerBound {
                return (self.wordRange(at: range.lowerBound).upperBound, range.upperBound)
            } else {
                return (self.wordRange(at: range.upperBound).upperBound, range.lowerBound)
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
    
    
    
    // MARK: - Actions
    
    @IBAction func selectColumnUp(_ sender: Any?) {
        
        let firstRange = self.selectedRange
        let lowerBound = self.upperInsertionLocation(of: firstRange.lowerBound)
        let upperBound = self.upperInsertionLocation(of: firstRange.upperBound)
        let range = NSRange(lowerBound..<upperBound)
        
        let insertionRanges = [range] + self.insertionRanges
        
        guard let set = self.prepareForSelectionUpdate(insertionRanges) else { return }
        
        self.setSelectedRanges(set.selectedRanges, affinity: .downstream, stillSelecting: false)
        self.insertionLocations = set.insertionLocations
        self.scrollRangeToVisible(range)
    }
    
    
    @IBAction func selectColumnDown(_ sender: Any?) {
        
        let lastRange = self.selectedRanges.last!.rangeValue
        let lowerBound = self.lowerInsertionLocation(of: lastRange.lowerBound)
        let upperBound = self.lowerInsertionLocation(of: lastRange.upperBound)
        let range = NSRange(lowerBound..<upperBound)
        
        let insertionRanges = self.insertionRanges + [range]
        
        guard let set = self.prepareForSelectionUpdate(insertionRanges) else { return }
        
        self.setSelectedRanges(set.selectedRanges, affinity: .upstream, stillSelecting: false)
        self.insertionLocations = set.insertionLocations
        self.scrollRangeToVisible(range)
    }
    
}
