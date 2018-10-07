//
//  EditorTextView+LineProcessing.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2018 1024jp
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
    
    // MARK: Action Messages
    
    /// move selected line up
    @IBAction func moveLineUp(_ sender: Any?) {
        
        guard let textStorage = self.textStorage else { return }
        
        // get line ranges to process
        let lineRanges = self.selectedLineRanges
        
        // cannot perform Move Line Up if one of the selections is already in the first line
        guard !lineRanges.isEmpty, lineRanges.first?.location != 0 else {
            NSSound.beep()
            return
        }
        
        let selectedRanges = self.selectedRanges as! [NSRange]
        
        // register redo for text selection
        self.setSelectedRangesWithUndo(self.selectedRanges)
        
        var newSelectedRanges = [NSRange]()
        
        // swap lines
        textStorage.beginEditing()
        for lineRange in lineRanges {
            let string = textStorage.string as NSString
            
            let upperLineRange = string.lineRange(at: lineRange.location - 1)
            var lineString = string.substring(with: lineRange)
            var upperLineString = string.substring(with: upperLineRange)
            
            // last line
            if !lineString.hasSuffix("\n") {
                lineString += "\n"
                upperLineString = upperLineString.trimmingCharacters(in: .newlines)
            }
            
            let replacementString = lineString + upperLineString
            let editRange = NSRange(location: upperLineRange.location, length: replacementString.utf16.count)
            
            // swap
            guard self.shouldChangeText(in: editRange, replacementString: replacementString) else { continue }
            
            textStorage.replaceCharacters(in: editRange, with: replacementString)
            self.didChangeText()
            
            // move selected ranges in the line to move
            for selectedRange in selectedRanges {
                if let intersectionRange = selectedRange.intersection(editRange) {
                    newSelectedRanges.append(NSRange(location: intersectionRange.location - upperLineRange.length,
                                                     length: intersectionRange.length))
                    
                } else if editRange.contains(selectedRange.location) || selectedRange.upperBound == editRange.upperBound {
                    newSelectedRanges.append(NSRange(location: selectedRange.location - upperLineRange.length,
                                                     length: selectedRange.length))
                }
            }
        }
        textStorage.endEditing()
        
        self.setSelectedRangesWithUndo(newSelectedRanges)
        
        self.undoManager?.setActionName("Move Line".localized)
    }
    
    
    /// move selected line down
    @IBAction func moveLineDown(_ sender: Any?) {
        
        guard let textStorage = self.textStorage else { return }
        
        // get line ranges to process
        let lineRanges = self.selectedLineRanges
        
        // cannot perform Move Line Down if one of the selections is already in the last line
        guard !lineRanges.isEmpty, lineRanges.last?.upperBound != textStorage.length else {
            NSSound.beep()
            return
        }
        
        let selectedRanges = self.selectedRanges as! [NSRange]
        
        // register redo for text selection
        self.setSelectedRangesWithUndo(self.selectedRanges)
        
        var newSelectedRanges = [NSRange]()
        
        // swap lines
        textStorage.beginEditing()
        for lineRange in lineRanges.reversed() {
            let string = textStorage.string as NSString
            
            var lowerLineRange = string.lineRange(at: lineRange.upperBound)
            var lineString = string.substring(with: lineRange)
            var lowerLineString = string.substring(with: lowerLineRange)
            
            // last line
            if !lowerLineString.hasSuffix("\n") {
                lineString = lineString.trimmingCharacters(in: .newlines)
                lowerLineString += "\n"
                lowerLineRange.length += 1
            }
            
            let replacementString = lowerLineString + lineString
            let editRange = NSRange(location: lineRange.location, length: replacementString.utf16.count)
            
            // swap
            guard self.shouldChangeText(in: editRange, replacementString: replacementString) else { continue }
            
            textStorage.replaceCharacters(in: editRange, with: replacementString)
            self.didChangeText()
            
            // move selected ranges in the line to move
            for selectedRange in selectedRanges {
                if let intersectionRange = selectedRange.intersection(editRange) {
                    newSelectedRanges.append(NSRange(location: intersectionRange.location + lowerLineRange.length,
                                                     length: intersectionRange.length))
                    
                } else if editRange.contains(selectedRange.location) {
                    newSelectedRanges.append(NSRange(location: selectedRange.location + lowerLineRange.length,
                                                     length: selectedRange.length))
                }
            }
        }
        textStorage.endEditing()
        
        self.setSelectedRangesWithUndo(newSelectedRanges)
        
        self.undoManager?.setActionName("Move Line".localized)
    }
    
    
    /// sort selected lines (only in the first selection) ascending
    @IBAction func sortLinesAscending(_ sender: Any?) {
        
        let string = self.string as NSString
        
        // process whole document if no text selected
        if self.selectedRange.length == 0 {
            self.selectedRange = string.range
        }
        
        let lineRange = string.lineRange(for: self.selectedRange, excludingLastLineEnding: true)
        
        guard lineRange.length > 0 else { return }
        
        let lines = string
            .substring(with: lineRange)
            .components(separatedBy: .newlines)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        
        // do nothing with single line
        guard lines.count > 1 else { return }
        
        let newString = lines.joined(separator: "\n")
        
        self.replace(with: newString, range: lineRange, selectedRange: lineRange,
                     actionName: "Sort Lines".localized)
    }
    
    
    /// show pattern sort sheet
    @IBAction func patternSort(_ sender: Any?) {
        
        guard self.isEditable else {
            NSSound.beep()
            return
        }
        
        let viewController = NSStoryboard(name: "PatternSortView", bundle: nil).instantiateInitialController() as! PatternSortViewController
        viewController.representedObject = self
        
        // sample the first line
        let string = self.string
        let range = Range(self.selectedRange, in: string)!
        let location = range.isEmpty ? string.startIndex : range.lowerBound
        let lineRange = string.lineRange(at: location, excludingLastLineEnding: true)
        viewController.sampleLine = String(string[lineRange])
        viewController.sampleFontName = (self.layoutManager as? LayoutManager)?.textFont?.fontName
        
        self.viewControllerForSheet?.presentAsSheet(viewController)
    }
    
    
    /// reverse selected lines (only in the first selection)
    @IBAction func reverseLines(_ sender: Any?) {
        
        let string = self.string as NSString
        
        // process whole document if no text selected
        if self.selectedRange.length == 0 {
            self.selectedRange = string.range
        }
        
        let lineRange = string.lineRange(for: self.selectedRange, excludingLastLineEnding: true)
        
        guard lineRange.length > 0 else { return }
        
        let lines = string.substring(with: lineRange).components(separatedBy: .newlines)
        
        // do nothing with single line
        guard lines.count > 1 else { return }
        
        // make new string
        let newString = lines.reversed().joined(separator: "\n")
        
        self.replace(with: newString, range: lineRange, selectedRange: lineRange,
                     actionName: "Reverse Lines".localized)
    }
    
    
    /// delete duplicate lines in selection
    @IBAction func deleteDuplicateLine(_ sender: Any?) {
        
        let string = self.string as NSString
        
        // process whole document if no text selected
        if self.selectedRange.length == 0 {
            self.selectedRange = string.range
        }
        
        guard self.selectedRange.length > 0 else { return }
        
        var replacementRanges = [NSRange]()
        var replacementStrings = [String]()
        var uniqueLines = OrderedSet<String>()
        var processedCount = 0
        
        // collect duplicate lines
        for range in self.selectedRanges as! [NSRange] {
            let lineRange = string.lineRange(for: range, excludingLastLineEnding: true)
            let targetString = string.substring(with: lineRange)
            let lines = targetString.components(separatedBy: .newlines)
            
            // filter duplicate lines
            uniqueLines.append(contentsOf: lines)
            
            let targetLinesRange: Range<Int> = processedCount..<uniqueLines.count
            processedCount += targetLinesRange.count
            
            // do nothing if no duplicate line exists
            guard targetLinesRange.count != lines.count else { continue }
            
            let replacementString = uniqueLines[targetLinesRange].joined(separator: "\n")
            
            replacementStrings.append(replacementString)
            replacementRanges.append(lineRange)
        }
        
        self.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: nil,
                     actionName: "Delete Duplicate Lines".localized)
    }
    
    
    /// duplicate selected lines below
    @IBAction func duplicateLine(_ sender: Any?) {
        
        var replacementRanges = [NSRange]()
        var replacementStrings = [String]()
        
        let string = self.string as NSString
        let selectedRanges = self.selectedRanges as! [NSRange]
        
        // get lines to process
        for selectedRange in selectedRanges {
            let lineRange = string.lineRange(for: selectedRange)
            let replacementRange = NSRange(location: lineRange.location, length: 0)
            var lineString = string.substring(with: lineRange)
            
            // add line break if it's the last line
            if !lineString.hasSuffix("\n") {
                lineString += "\n"
            }
            
            replacementRanges.append(replacementRange)
            replacementStrings.append(lineString)
        }
        
        self.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: nil,
                     actionName: "Duplicate Line".localized)
    }
    
    
    /// remove selected lines
    @IBAction func deleteLine(_ sender: Any?) {
        
        let replacementRanges = self.selectedLineRanges
        
        // on empty last line
        guard !replacementRanges.isEmpty else { return }
        
        let replacementStrings = [String](repeating: "", count: replacementRanges.count)
        
        self.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: nil,
                     actionName: "Delete Line".localized)
    }
    
    
    /// trim all trailing whitespace
    @IBAction func trimTrailingWhitespace(_ sender: Any?) {
        
        let trimsWhitespaceOnlyLines = UserDefaults.standard[.trimsWhitespaceOnlyLines]
        
        self.trimTrailingWhitespace(ignoresEmptyLines: !trimsWhitespaceOnlyLines)
    }
    
}


extension NSTextView {
    
    func sortLines(pattern: SortPattern, options: SortOptions) {
        
        let string = self.string as NSString
        
        // process whole document if no text selected
        if self.selectedRange.length == 0 {
            self.selectedRange = string.range
        }
        
        let lineRange = string.lineRange(for: self.selectedRange, excludingLastLineEnding: true)
        
        guard lineRange.length > 0 else { return }
        
        let newString = pattern.sort(string.substring(with: lineRange), options: options)
        
        self.replace(with: newString, range: lineRange, selectedRange: lineRange,
                     actionName: "Sort Lines".localized)
    }
    
}



// MARK: Private NSTextView Extension

private extension NSTextView {
    
    /// extract line by line line ranges which selected ranges include
    var selectedLineRanges: [NSRange] {
        
        return (self.string as NSString).lineRanges(for: self.selectedRanges as! [NSRange])
    }
    
}
