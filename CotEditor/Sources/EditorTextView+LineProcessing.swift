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
//  © 2014-2019 1024jp
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
        
        guard
            let ranges = self.rangesForUserTextChange as? [NSRange],
            let editingInfo = self.string.moveLineUp(in: ranges)
            else {
                NSSound.beep()
                return
            }
        
        self.edit(with: editingInfo, actionName: "Move Line".localized)
    }
    
    
    /// move selected line down
    @IBAction func moveLineDown(_ sender: Any?) {
        
        guard
            let ranges = self.rangesForUserTextChange as? [NSRange],
            let editingInfo = self.string.moveLineDown(in: ranges)
            else {
                NSSound.beep()
                return
            }
        
        self.edit(with: editingInfo, actionName: "Move Line".localized)
    }
    
    
    /// sort selected lines (only in the first selection) ascending
    @IBAction func sortLinesAscending(_ sender: Any?) {
        
        // process whole document if no text selected
        let range = self.selectedRange.isEmpty ? self.string.nsRange : self.selectedRange
        
        guard let editingInfo = self.string.sortLinesAscending(in: range) else { return }
        
        self.edit(with: editingInfo, actionName: "Sort Lines".localized)
    }
    
    
    /// reverse selected lines (only in the first selection)
    @IBAction func reverseLines(_ sender: Any?) {
        
        // process whole document if no text selected
        let range = self.selectedRange.isEmpty ? self.string.nsRange : self.selectedRange
        
        guard let editingInfo = self.string.reverseLines(in: range) else { return }
        
        self.edit(with: editingInfo, actionName: "Reverse Lines".localized)
    }
    
    
    /// delete duplicate lines in selection
    @IBAction func deleteDuplicateLine(_ sender: Any?) {
        
        guard let selectedRanges = self.rangesForUserTextChange as? [NSRange] else { return }
        
        // process whole document if no text selected
        let ranges = self.selectedRange.isEmpty ? [self.string.nsRange] : selectedRanges
        
        guard let editingInfo = self.string.deleteDuplicateLine(in: ranges) else { return }
        
        self.edit(with: editingInfo, actionName: "Delete Duplicate Lines".localized)
    }
    
    
    /// duplicate selected lines below
    @IBAction func duplicateLine(_ sender: Any?) {
        
        guard let selectedRanges = self.rangesForUserTextChange as? [NSRange] else { return }
        
        guard let editingInfo = self.string.duplicateLine(in: selectedRanges) else { return }
        
        self.edit(with: editingInfo, actionName: "Duplicate Line".localized)
    }
    
    
    /// remove selected lines
    @IBAction func deleteLine(_ sender: Any?) {
        
        guard let selectedRanges = self.rangesForUserTextChange as? [NSRange] else { return }
        
        guard let editingInfo = self.string.deleteLine(in: selectedRanges) else { return }
        
        self.edit(with: editingInfo, actionName: "Delete Line".localized)
    }
    
    
    /// trim all trailing whitespace
    @IBAction func trimTrailingWhitespace(_ sender: Any?) {
        
        let trimsWhitespaceOnlyLines = UserDefaults.standard[.trimsWhitespaceOnlyLines]
        
        self.trimTrailingWhitespace(ignoresEmptyLines: !trimsWhitespaceOnlyLines)
    }
    
    
    /// show pattern sort sheet
    @IBAction func patternSort(_ sender: Any?) {
        
        guard self.isEditable else {
            NSSound.beep()
            return
        }
        
        let viewController = PatternSortViewController.instantiate(storyboard: "PatternSortView")
        viewController.representedObject = self
        
        // sample the first line
        let range = Range(self.selectedRange, in: self.string)!
        let location = range.isEmpty ? self.string.startIndex : range.lowerBound
        let lineRange = self.string.lineRange(at: location, excludingLastLineEnding: true)
        viewController.sampleLine = String(self.string[lineRange])
        viewController.sampleFontName = self.font?.fontName
        
        self.viewControllerForSheet?.presentAsSheet(viewController)
    }
    
    
    
    // MARK: Private Methods
    
    /// replace content according to EditingInfo
    private func edit(with info: String.EditingInfo, actionName: String) {
        
        self.replace(with: info.strings, ranges: info.ranges, selectedRanges: info.selectedRanges, actionName: actionName)
    }
    
}



extension NSTextView {
    
    func sortLines(pattern: SortPattern, options: SortOptions) {
        
        // process whole document if no text selected
        let range = self.selectedRange.isEmpty ? self.string.nsRange : self.selectedRange
        
        let string = self.string as NSString
        let lineRange = string.lineRange(for: range, excludingLastLineEnding: true)
        
        guard !lineRange.isEmpty else { return }
        
        let newString = pattern.sort(string.substring(with: lineRange), options: options)
        
        self.replace(with: newString, range: lineRange, selectedRange: lineRange,
                     actionName: "Sort Lines".localized)
    }
    
}




// MARK: -

private extension String {
    
    typealias EditingInfo = (strings: [String], ranges: [NSRange], selectedRanges: [NSRange]?)
    
    
    
    /// move selected line up
    func moveLineUp(in ranges: [NSRange]) -> EditingInfo? {
        
        // get line ranges to process
        let lineRanges = (self as NSString).lineRanges(for: ranges)
        
        // cannot perform Move Line Up if one of the selections is already in the first line
        guard !lineRanges.isEmpty, lineRanges.first?.location != 0 else { return nil }
        
        var string = self as NSString
        var replacementRange = NSRange()
        var selectedRanges = [NSRange]()
        
        // swap lines
        for lineRange in lineRanges {
            let upperLineRange = string.lineRange(at: lineRange.location - 1)
            var lineString = string.substring(with: lineRange)
            var upperLineString = string.substring(with: upperLineRange)
            
            // last line
            if !lineString.hasSuffix("\n") {
                lineString += "\n"
                upperLineString = upperLineString.trimmingCharacters(in: .newlines)
            }
            
            // swap
            let editRange = lineRange.union(upperLineRange)
            string = string.replacingCharacters(in: editRange, with: lineString + upperLineString) as NSString
            replacementRange.formUnion(editRange)
            
            // move selected ranges in the line to move
            for selectedRange in ranges {
                if let intersectionRange = selectedRange.intersection(editRange) {
                    selectedRanges.append(NSRange(location: intersectionRange.location - upperLineRange.length,
                                                  length: intersectionRange.length))
                    
                } else if editRange.contains(selectedRange.location) || selectedRange.upperBound == editRange.upperBound {
                    selectedRanges.append(NSRange(location: selectedRange.location - upperLineRange.length,
                                                  length: selectedRange.length))
                }
            }
        }
        
        let replacementString = string.substring(with: replacementRange)
        
        return (strings: [replacementString], ranges: [replacementRange], selectedRanges: selectedRanges)
    }
    
    
    /// move selected line down
    func moveLineDown(in ranges: [NSRange]) -> EditingInfo? {
        
        // get line ranges to process
        let lineRanges = (self as NSString).lineRanges(for: ranges)
        
        // cannot perform Move Line Down if one of the selections is already in the last line
        guard !lineRanges.isEmpty, lineRanges.last?.upperBound != self.nsRange.upperBound else { return nil }
        
        var string = self as NSString
        var replacementRange = NSRange()
        var selectedRanges = [NSRange]()
        
        // swap lines
        for lineRange in lineRanges.reversed() {
            var lowerLineRange = string.lineRange(at: lineRange.upperBound)
            var lineString = string.substring(with: lineRange)
            var lowerLineString = string.substring(with: lowerLineRange)
            
            // last line
            if !lowerLineString.hasSuffix("\n") {
                lineString = lineString.trimmingCharacters(in: .newlines)
                lowerLineString += "\n"
                lowerLineRange.length += 1
            }
            
            // swap
            let editRange = lineRange.union(lowerLineRange)
            string = string.replacingCharacters(in: editRange, with: lowerLineString + lineString) as NSString
            replacementRange.formUnion(editRange)
            
            // move selected ranges in the line to move
            for selectedRange in ranges {
                if let intersectionRange = selectedRange.intersection(editRange) {
                    selectedRanges.append(NSRange(location: intersectionRange.location + lowerLineRange.length,
                                                  length: intersectionRange.length))
                    
                } else if editRange.contains(selectedRange.location) {
                    selectedRanges.append(NSRange(location: selectedRange.location + lowerLineRange.length,
                                                  length: selectedRange.length))
                }
            }
        }
        
        let replacementString = string.substring(with: replacementRange)
        
        return (strings: [replacementString], ranges: [replacementRange], selectedRanges: selectedRanges)
    }
    
    
    /// sort selected lines ascending
    func sortLinesAscending(in range: NSRange) -> EditingInfo? {
        
        let string = self as NSString
        let lineRange = string.lineRange(for: range, excludingLastLineEnding: true)
        
        // do nothing with single line
        guard string.rangeOfCharacter(from: .newlines, range: lineRange) != .notFound else { return nil }
        
        let newString = string
            .substring(with: lineRange)
            .components(separatedBy: .newlines)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            .joined(separator: "\n")
        
        return (strings: [newString], ranges: [lineRange], selectedRanges: [lineRange])
    }
    
    
    /// reverse selected lines
    func reverseLines(in range: NSRange) -> EditingInfo? {
        
        let string = self as NSString
        let lineRange = string.lineRange(for: range, excludingLastLineEnding: true)
        
        // do nothing with single line
        guard string.rangeOfCharacter(from: .newlines, range: lineRange) != .notFound else { return nil }
        
        let newString = string
            .substring(with: lineRange)
            .components(separatedBy: .newlines)
            .reversed()
            .joined(separator: "\n")
        
        return (strings: [newString], ranges: [lineRange], selectedRanges: [lineRange])
    }
    
    
    /// delete duplicate lines in selection
    func deleteDuplicateLine(in ranges: [NSRange]) -> EditingInfo? {
        
        let string = self as NSString
        var replacementStrings = [String]()
        var replacementRanges = [NSRange]()
        var uniqueLines = OrderedSet<String>()
        var processedCount = 0
        
        // collect duplicate lines
        for range in ranges {
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
        
        guard processedCount > 0 else { return nil }
        
        return (strings: replacementStrings, ranges: replacementRanges, selectedRanges: nil)
    }
    
    
    /// duplicate selected lines below
    func duplicateLine(in ranges: [NSRange]) -> EditingInfo? {
        
        let string = self as NSString
        var replacementStrings = [String]()
        var replacementRanges = [NSRange]()
        
        for range in ranges {
            let lineRange = string.lineRange(for: range)
            let replacementRange = NSRange(location: lineRange.location, length: 0)
            var lineString = string.substring(with: lineRange)
            
            // add line break if it's the last line
            if !lineString.hasSuffix("\n") {
                lineString += "\n"
            }
            
            replacementStrings.append(lineString)
            replacementRanges.append(replacementRange)
        }
        
        return (strings: replacementStrings, ranges: replacementRanges, selectedRanges: nil)
    }
    
    
    /// remove selected lines
    func deleteLine(in ranges: [NSRange]) -> EditingInfo? {
        
        guard !ranges.isEmpty else { return nil }
        
        let replacementRanges = (self as NSString).lineRanges(for: ranges)
        let replacementStrings = [String](repeating: "", count: replacementRanges.count)
        
        return (strings: replacementStrings, ranges: replacementRanges, selectedRanges: nil)
    }
    
}
