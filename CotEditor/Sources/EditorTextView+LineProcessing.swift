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
//  © 2014-2022 1024jp
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
            let ranges = self.rangesForUserTextChange?.map(\.rangeValue),
            let editingInfo = self.string.moveLineUp(in: ranges)
            else { return NSSound.beep() }
        
        self.edit(with: editingInfo, actionName: "Move Line".localized)
    }
    
    
    /// move selected line down
    @IBAction func moveLineDown(_ sender: Any?) {
        
        guard
            let ranges = self.rangesForUserTextChange?.map(\.rangeValue),
            let editingInfo = self.string.moveLineDown(in: ranges)
            else { return NSSound.beep() }
        
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
        
        guard let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue) else { return }
        
        // process whole document if no text selected
        let ranges = self.selectedRange.isEmpty ? [self.string.nsRange] : selectedRanges
        
        guard let editingInfo = self.string.deleteDuplicateLine(in: ranges) else { return }
        
        self.edit(with: editingInfo, actionName: "Delete Duplicate Lines".localized)
    }
    
    
    /// duplicate selected lines below
    @IBAction func duplicateLine(_ sender: Any?) {
        
        guard let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue) else { return }
        
        guard let editingInfo = self.string.duplicateLine(in: selectedRanges, lineEnding: "\n") else { return }
        
        self.edit(with: editingInfo, actionName: "Duplicate Line".localized)
    }
    
    
    /// remove selected lines
    @IBAction func deleteLine(_ sender: Any?) {
        
        guard let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue) else { return }
        
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
        
        guard self.isEditable else { return NSSound.beep() }
        
        let viewController = PatternSortViewController.instantiate(storyboard: "PatternSortView")
        
        // sample the first line
        let location = self.selectedRange.isEmpty
            ? self.string.startIndex
            : String.Index(utf16Offset: self.selectedRange.location, in: self.string)
        let lineRange = self.string.lineContentsRange(at: location)
        viewController.sampleLine = String(self.string[lineRange])
        viewController.sampleFontName = self.font?.fontName
        
        viewController.completionHandler = { [weak self] (pattern, options) in
            self?.sortLines(pattern: pattern, options: options)
        }
        
        self.viewControllerForSheet?.presentAsSheet(viewController)
    }
    
    
    
    // MARK: Private Methods
    
    /// replace content according to EditingInfo
    private func edit(with info: String.EditingInfo, actionName: String) {
        
        self.replace(with: info.strings, ranges: info.ranges, selectedRanges: info.selectedRanges, actionName: actionName)
    }
    
    
    /// Sort lines in the text content.
    ///
    /// - Parameters:
    ///   - pattern: The sort pattern.
    ///   - options: The sort options.
    private func sortLines(pattern: SortPattern, options: SortOptions) {
        
        // process whole document if no text selected
        let range = self.selectedRange.isEmpty ? self.string.nsRange : self.selectedRange
        
        let string = self.string as NSString
        let lineRange = string.lineContentsRange(for: range)
        
        guard !lineRange.isEmpty else { return }
        
        let newString = pattern.sort(string.substring(with: lineRange), options: options)
        
        self.replace(with: newString, range: lineRange, selectedRange: lineRange,
                     actionName: "Sort Lines".localized)
    }
    
}



// MARK: -

extension String {
    
    typealias EditingInfo = (strings: [String], ranges: [NSRange], selectedRanges: [NSRange]?)
    
    
    
    /// move selected line up
    func moveLineUp(in ranges: [NSRange]) -> EditingInfo? {
        
        // get line ranges to process
        let lineRanges = (self as NSString).lineRanges(for: ranges, includingLastEmptyLine: true)
        
        // cannot perform Move Line Up if one of the selections is already in the first line
        guard !lineRanges.isEmpty, lineRanges.first!.lowerBound != 0 else { return nil }
        
        var string = self as NSString
        var replacementRange = NSRange()
        var selectedRanges = [NSRange]()
        
        // swap lines
        for lineRange in lineRanges {
            let upperLineRange = string.lineRange(at: lineRange.location - 1)
            var lineString = string.substring(with: lineRange)
            var upperLineString = string.substring(with: upperLineRange)
            
            // last line
            if lineString.last?.isNewline != true, let lineEnding = upperLineString.popLast() {
                lineString.append(lineEnding)
            }
            
            // swap
            let editRange = lineRange.union(upperLineRange)
            string = string.replacingCharacters(in: editRange, with: lineString + upperLineString) as NSString
            replacementRange.formUnion(editRange)
            
            // move selected ranges in the line to move
            for selectedRange in ranges {
                if let intersectionRange = selectedRange.intersection(editRange) {
                    selectedRanges.append(intersectionRange.shifted(offset: -upperLineRange.length))
                    
                } else if editRange.touches(selectedRange.location) {
                    selectedRanges.append(selectedRange.shifted(offset: -upperLineRange.length))
                }
            }
        }
        selectedRanges = selectedRanges.unique.sorted(\.location)
        
        let replacementString = string.substring(with: replacementRange)
        
        return (strings: [replacementString], ranges: [replacementRange], selectedRanges: selectedRanges)
    }
    
    
    /// move selected line down
    func moveLineDown(in ranges: [NSRange]) -> EditingInfo? {
        
        // get line ranges to process
        let lineRanges = (self as NSString).lineRanges(for: ranges)
        
        // cannot perform Move Line Down if one of the selections is already in the last line
        guard !lineRanges.isEmpty, (lineRanges.last!.upperBound != self.length || self.last?.isNewline == true) else { return nil }
        
        var string = self as NSString
        var replacementRange = NSRange()
        var selectedRanges = [NSRange]()
        
        // swap lines
        for lineRange in lineRanges.reversed() {
            let lowerLineRange = string.lineRange(at: lineRange.upperBound)
            var lineString = string.substring(with: lineRange)
            var lowerLineString = string.substring(with: lowerLineRange)
            
            // last line
            if lowerLineString.last?.isNewline != true, let lineEnding = lineString.popLast() {
                lowerLineString.append(lineEnding)
            }
            
            // swap
            let editRange = lineRange.union(lowerLineRange)
            string = string.replacingCharacters(in: editRange, with: lowerLineString + lineString) as NSString
            replacementRange.formUnion(editRange)
            
            // move selected ranges in the line to move
            for selectedRange in ranges {
                if let intersectionRange = selectedRange.intersection(editRange) {
                    let offset = (lineString.last?.isNewline == true)
                        ? lowerLineRange.length
                        : lowerLineRange.length + lowerLineString.last!.utf16.count
                    selectedRanges.append(intersectionRange.shifted(offset: offset))
                    
                } else if editRange.touches(selectedRange.location) {
                    selectedRanges.append(selectedRange.shifted(offset: lowerLineRange.length))
                }
            }
        }
        selectedRanges = selectedRanges.unique.sorted(\.location)
        
        let replacementString = string.substring(with: replacementRange)
        
        return (strings: [replacementString], ranges: [replacementRange], selectedRanges: selectedRanges)
    }
    
    
    /// sort selected lines ascending
    func sortLinesAscending(in range: NSRange) -> EditingInfo? {
        
        let string = self as NSString
        let lineEndingRange = string.range(of: "\\R", options: .regularExpression, range: range)
        
        // do nothing with single line
        guard lineEndingRange != .notFound else { return nil }
        
        let lineEnding = string.substring(with: lineEndingRange)
        let lineRange = string.lineContentsRange(for: range)
        let newString = string
            .substring(with: lineRange)
            .components(separatedBy: .newlines)
            .sorted(options: [.localized, .caseInsensitive])
            .joined(separator: lineEnding)
        
        return (strings: [newString], ranges: [lineRange], selectedRanges: [lineRange])
    }
    
    
    /// reverse selected lines
    func reverseLines(in range: NSRange) -> EditingInfo? {
        
        let string = self as NSString
        let lineEndingRange = string.range(of: "\\R", options: .regularExpression, range: range)
        
        // do nothing with single line
        guard lineEndingRange != .notFound else { return nil }
        
        let lineEnding = string.substring(with: lineEndingRange)
        let lineRange = string.lineContentsRange(for: range)
        let newString = string
            .substring(with: lineRange)
            .components(separatedBy: .newlines)
            .reversed()
            .joined(separator: lineEnding)
        
        return (strings: [newString], ranges: [lineRange], selectedRanges: [lineRange])
    }
    
    
    /// delete duplicate lines in selection
    func deleteDuplicateLine(in ranges: [NSRange]) -> EditingInfo? {
        
        let string = self as NSString
        let lineContentRanges = ranges
            .map { string.lineRange(for: $0) }
            .flatMap { self.lineContentsRanges(for: $0) }
            .unique
            .sorted(\.location)
        
        var replacementRanges = [NSRange]()
        var uniqueLines = [String]()
        for lineContentRange in lineContentRanges {
            let line = string.substring(with: lineContentRange)
            
            if uniqueLines.contains(line) {
                replacementRanges.append(string.lineRange(for: lineContentRange))
            } else {
                uniqueLines.append(line)
            }
        }
        
        guard !replacementRanges.isEmpty else { return nil }
        
        let replacementStrings = [String](repeating: "", count: replacementRanges.count)
        
        return (strings: replacementStrings, ranges: replacementRanges, selectedRanges: nil)
    }
    
    
    /// duplicate selected lines below
    func duplicateLine(in ranges: [NSRange], lineEnding: Character) -> EditingInfo? {
        
        let string = self as NSString
        var replacementStrings = [String]()
        var replacementRanges = [NSRange]()
        var selectedRanges = [NSRange]()
        
        // group the ranges sharing the same lines
        let rangeGroups: [[NSRange]] = ranges.sorted(\.location)
            .reduce(into: []) { (groups, range) in
                if let last = groups.last?.last,
                    string.lineRange(for: last).intersects(string.lineRange(for: range))
                {
                    groups[groups.count - 1].append(range)
                } else {
                    groups.append([range])
                }
            }
        
        var offset = 0
        for group in rangeGroups {
            let unionRange = group.reduce(into: group[0]) { $0.formUnion($1) }
            let lineRange = string.lineRange(for: unionRange)
            let replacementRange = NSRange(location: lineRange.location, length: 0)
            var lineString = string.substring(with: lineRange)
            
            // add line break if it's the last line
            if lineString.last?.isNewline != true {
                lineString.append(lineEnding)
            }
            
            replacementStrings.append(lineString)
            replacementRanges.append(replacementRange)
            
            offset += lineString.length
            for range in group {
                selectedRanges.append(range.shifted(offset: offset))
            }
        }
        
        return (strings: replacementStrings, ranges: replacementRanges, selectedRanges: selectedRanges)
    }
    
    
    /// remove selected lines
    func deleteLine(in ranges: [NSRange]) -> EditingInfo? {
        
        guard !ranges.isEmpty else { return nil }
        
        let lineRanges = (self as NSString).lineRanges(for: ranges)
        let replacementStrings = [String](repeating: "", count: lineRanges.count)
        
        var selectedRanges: [NSRange] = []
        var offset = 0
        for range in lineRanges {
            selectedRanges.append(NSRange(location: range.location + offset, length: 0))
            offset -= range.length
        }
        selectedRanges = selectedRanges.unique.sorted(\.location)
        
        return (strings: replacementStrings, ranges: lineRanges, selectedRanges: selectedRanges)
    }
    
}
