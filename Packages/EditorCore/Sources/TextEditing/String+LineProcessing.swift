//
//  String+LineProcessing.swift
//  TextEditing
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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

public import Foundation
import StringUtils

public extension String {
    
    /// Moves the lines intersecting the given ranges up.
    ///
    /// - Parameter ranges: The selection ranges whose intersecting lines should be moved.
    /// - Returns: An `EditingContext`, or `nil` if no move is possible.
    func moveLineUp(in ranges: [NSRange]) -> EditingContext? {
        
        // get line ranges to process
        let lineRanges = (self as NSString).lineRanges(for: ranges, includingLastEmptyLine: true)
        
        // cannot perform Move Line Up if one of the selections is already in the first line
        guard !lineRanges.isEmpty, lineRanges.first!.lowerBound != 0 else { return nil }
        
        var string = self as NSString
        var replacementRange = NSRange()
        var selectedRanges: [NSRange] = []
        
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
                    selectedRanges.append(intersectionRange.shifted(by: -upperLineRange.length))
                    
                } else if editRange.touches(selectedRange.location) {
                    selectedRanges.append(selectedRange.shifted(by: -upperLineRange.length))
                }
            }
        }
        selectedRanges = selectedRanges.uniqued.sorted(using: KeyPathComparator(\.location))
        
        let replacementString = string.substring(with: replacementRange)
        
        return EditingContext(strings: [replacementString], ranges: [replacementRange], selectedRanges: selectedRanges)
    }
    
    
    /// Moves the lines intersecting the given ranges down.
    ///
    /// - Parameter ranges: The selection ranges whose intersecting lines should be moved.
    /// - Returns: An `EditingContext`, or `nil` if no move is possible.
    func moveLineDown(in ranges: [NSRange]) -> EditingContext? {
        
        // get line ranges to process
        let lineRanges = (self as NSString).lineRanges(for: ranges)
        
        // cannot perform Move Line Down if one of the selections is already in the last line
        guard
            !lineRanges.isEmpty,
            lineRanges.last!.upperBound != self.length || self.last?.isNewline == true
        else { return nil }
        
        var string = self as NSString
        var replacementRange = NSRange()
        var selectedRanges: [NSRange] = []
        
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
                    selectedRanges.append(intersectionRange.shifted(by: offset))
                    
                } else if editRange.touches(selectedRange.location) {
                    selectedRanges.append(selectedRange.shifted(by: lowerLineRange.length))
                }
            }
        }
        selectedRanges = selectedRanges.uniqued.sorted(using: KeyPathComparator(\.location))
        
        let replacementString = string.substring(with: replacementRange)
        
        return EditingContext(strings: [replacementString], ranges: [replacementRange], selectedRanges: selectedRanges)
    }
    
    
    /// Deletes duplicate lines within the selections, keeping the first occurrence.
    ///
    /// - Parameter ranges: The selection ranges in which to detect and remove duplicate lines.
    /// - Returns: An `EditingContext`, or `nil` if there were no duplicates.
    func deleteDuplicateLine(in ranges: [NSRange]) -> EditingContext? {
        
        let string = self as NSString
        let lineContentsRanges = ranges
            .map { string.lineRange(for: $0) }
            .flatMap { self.lineContentsRanges(for: $0) }
            .uniqued
            .sorted(using: KeyPathComparator(\.location))
        
        var replacementRanges: [NSRange] = []
        var uniqueLines: [String] = []
        for lineContentsRange in lineContentsRanges {
            let line = string.substring(with: lineContentsRange)
            
            if uniqueLines.contains(line) {
                replacementRanges.append(string.lineRange(for: lineContentsRange))
            } else {
                uniqueLines.append(line)
            }
        }
        
        guard !replacementRanges.isEmpty else { return nil }
        
        let replacementStrings = [String](repeating: "", count: replacementRanges.count)
        
        return EditingContext(strings: replacementStrings, ranges: replacementRanges)
    }
    
    
    /// Duplicates the selected lines immediately below.
    ///
    /// - Parameters:
    ///   - ranges: The selection ranges whose intersecting lines should be duplicated.
    ///   - lineEnding: The line ending character to use when appending a missing newline.
    /// - Returns: An `EditingContext`, or `nil` if nothing to duplicate.
    func duplicateLine(in ranges: [NSRange], lineEnding: Character) -> EditingContext? {
        
        let string = self as NSString
        var replacementStrings: [String] = []
        var replacementRanges: [NSRange] = []
        var selectedRanges: [NSRange] = []
        
        // group the ranges sharing the same lines
        let rangeGroups: [[NSRange]] = ranges.sorted(using: KeyPathComparator(\.location))
            .reduce(into: []) { groups, range in
                if let last = groups.last?.last,
                   string.lineRange(for: last).intersects(string.lineRange(for: range))
                {
                    groups[groups.endIndex - 1].append(range)
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
                selectedRanges.append(range.shifted(by: offset))
            }
        }
        
        return EditingContext(strings: replacementStrings, ranges: replacementRanges, selectedRanges: selectedRanges)
    }
    
    
    /// Removes the lines that intersect the given ranges.
    ///
    /// - Parameter ranges: The selection ranges whose intersecting lines should be removed.
    /// - Returns: An `EditingContext`, or `nil` if no ranges were provided.
    func deleteLine(in ranges: [NSRange]) -> EditingContext? {
        
        guard !ranges.isEmpty else { return nil }
        
        let lineRanges = (self as NSString).lineRanges(for: ranges)
        let replacementStrings = [String](repeating: "", count: lineRanges.count)
        
        var selectedRanges: [NSRange] = []
        var offset = 0
        for range in lineRanges {
            selectedRanges.append(NSRange(location: range.location + offset, length: 0))
            offset -= range.length
        }
        selectedRanges = selectedRanges.uniqued.sorted(using: KeyPathComparator(\.location))
        
        return EditingContext(strings: replacementStrings, ranges: lineRanges, selectedRanges: selectedRanges)
    }
    
    
    /// Joins lines within the given ranges by collapsing intervening whitespace to a single space.
    ///
    /// - Parameter ranges: The ranges of text whose internal line breaks should be collapsed.
    /// - Returns: An `EditingContext`.
    func joinLines(in ranges: [NSRange]) -> EditingContext {
        
        let replacementStrings = ranges
            .map { (self as NSString).substring(with: $0) }
            .map { $0.replacing(/\s*\R\s*/, with: " ") }
        var selectedRanges: [NSRange] = []
        var offset = 0
        for (range, replacementString) in zip(ranges, replacementStrings) {
            selectedRanges.append(NSRange(location: range.location + offset, length: replacementString.length))
            offset += replacementString.length - range.length
        }
        
        return EditingContext(strings: replacementStrings, ranges: ranges, selectedRanges: selectedRanges)
    }
    
    
    /// Joins each selected line with its subsequent line by collapsing the line break and surrounding whitespace to a single space.
    ///
    /// - Parameter ranges: The selection ranges whose lines should be joined with the following line.
    /// - Returns: An `EditingContext`.
    func joinLines(after ranges: [NSRange]) -> EditingContext {
        
        let lineRanges = (self as NSString).lineRanges(for: ranges)
        let replacementRanges = lineRanges
            .map { (self as NSString).range(of: #"\s*\R\s*"#, options: .regularExpression, range: NSRange($0.lowerBound..<self.length)) }
            .filter { !$0.isNotFound }  // when in the last line
        let replacementStrings = Array(repeating: " ", count: replacementRanges.count)
        
        return EditingContext(strings: replacementStrings, ranges: replacementRanges)
    }
}
    
    
public extension String {
    
    /// Sorts the lines in the given range in ascending order.
    ///
    /// - Parameter range: The range in which to sort lines.
    /// - Returns: An `EditingContext`, or `nil` if only a single line is present.
    func sortLinesAscending(in range: NSRange) -> EditingContext? {
        
        self.sortLines(in: range) { $0.sorted(using: .localized) }
    }
    
    
    /// Reverses the order of lines in the given range.
    ///
    /// - Parameter range: The range containing the lines to reverse.
    /// - Returns: An `EditingContext`, or `nil` if only a single line is present.
    func reverseLines(in range: NSRange) -> EditingContext? {
        
        self.sortLines(in: range) { $0.reversed() }
    }
    
    
    /// Randomizes the order of lines in the given range.
    ///
    /// - Parameter range: The range containing the lines to shuffle.
    /// - Returns: An `EditingContext`, or `nil` if only a single line is present.
    func shuffleLines(in range: NSRange) -> EditingContext? {
        
        self.sortLines(in: range) { $0.shuffled() }
    }
    
    
    // MARK: Private Methods
    
    /// Sorts lines in the range using the given predicate.
    ///
    /// - Parameters:
    ///   - range: The range in which to sort lines.
    ///   - predicate: The predicate used to sort lines.
    /// - Returns: An `EditingContext`, or `nil` if no modification is required.
    private func sortLines(in range: NSRange, predicate: ([String]) -> [String]) -> EditingContext? {
        
        let string = self as NSString
        let lineEndingRange = string.range(of: "\\R", options: .regularExpression, range: range)
        
        // do nothing with single line
        guard !lineEndingRange.isNotFound else { return nil }
        
        let lineEnding = string.substring(with: lineEndingRange)
        let lineRange = string.lineContentsRange(for: range)
        let lines = string
            .substring(with: lineRange)
            .components(separatedBy: .newlines)
        let newString = predicate(lines)
            .joined(separator: lineEnding)
        
        return EditingContext(strings: [newString], ranges: [lineRange], selectedRanges: [lineRange])
    }
}


public extension String {
    
    /// Trims all trailing whitespace at line ends, optionally ignoring empty lines.
    ///
    /// - Parameters:
    ///   - ignoringEmptyLines: `true` to ignore lines that consist solely of whitespace.
    ///   - keepingEditingPoint: `true` to avoid trimming at positions that would move the caret.
    ///   - editingRanges: The current selection/caret ranges to consider when preserving editing points.
    /// - Returns: An `EditingContext`, or `nil` if nothing needed trimming.
    func trimTrailingWhitespace(ignoringEmptyLines: Bool, keepingEditingPoint: Bool = false, in editingRanges: [NSRange]) -> EditingContext? {
        
        let whitespaceRanges = self.rangesOfTrailingWhitespace(ignoringEmptyLines: ignoringEmptyLines)
        
        guard !whitespaceRanges.isEmpty else { return nil }
        
        let trimmingRanges: [NSRange] = keepingEditingPoint
            ? whitespaceRanges.filter { range in editingRanges.allSatisfy { !$0.touches(range) } }
            : whitespaceRanges
        
        guard !trimmingRanges.isEmpty else { return nil }
        
        let replacementStrings = [String](repeating: "", count: trimmingRanges.count)
        let selectedRanges = editingRanges.map { $0.removed(ranges: trimmingRanges) }
        
        return EditingContext(strings: replacementStrings, ranges: trimmingRanges, selectedRanges: selectedRanges)
    }
}

    
extension String {
    
    /// Returns the ranges of trailing whitespace at the ends of lines.
    ///
    /// - Parameter ignoringEmptyLines: Pass `true` to ignore lines that are only whitespace.
    /// - Returns: An array of ranges representing trailing whitespace segments.
    func rangesOfTrailingWhitespace(ignoringEmptyLines: Bool) -> [NSRange] {
        
        let pattern = ignoringEmptyLines ? "(?<!^|[ \t])[ \t]++$" : "[ \t]++$"
        let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        
        return regex.matches(in: self, range: self.nsRange).map(\.range)
    }
}
