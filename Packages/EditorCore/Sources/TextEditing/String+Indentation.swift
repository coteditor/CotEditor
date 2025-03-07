//
//  String+Indentation.swift
//  TextEditing
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-10-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2024 1024jp
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

import Foundation
import StringUtils

public enum IndentStyle: Equatable, Sendable {
    
    case tab
    case space
}


private enum DetectionLines {
    
    static let min = 3
    static let max = 100
}


public extension String {
    
    /// Increases indent level in.
    func indent(style: IndentStyle, indentWidth: Int, in selectedRanges: [NSRange]) -> EditingContext {
        
        assert(indentWidth > 0)
        
        // get indent target
        let string = self as NSString
        
        // create indent string to prepend
        let indent = switch style {
            case .tab: "\t"
            case .space: String(repeating: " ", count: indentWidth)
        }
        let indentLength = indent.length
        
        // create shifted string
        let lineRanges = string.lineRanges(for: selectedRanges, includingLastEmptyLine: true)
        let newLines = lineRanges.map { indent + string.substring(with: $0) }
        
        // calculate new selection range
        let newSelectedRanges = selectedRanges.map { selectedRange -> NSRange in
            let shift = lineRanges.prefix(while: { $0.location <= selectedRange.location }).count
            let lineCount = lineRanges.prefix(while: { selectedRange.intersects($0) }).count
            let lengthDiff = max(lineCount - 1, 0) * indentLength
            
            return NSRange(location: selectedRange.location + shift * indentLength,
                           length: selectedRange.length + lengthDiff)
        }
        
        return EditingContext(strings: newLines, ranges: lineRanges, selectedRanges: newSelectedRanges)
    }
    
    
    /// Decreases indent level.
    func outdent(style: IndentStyle, indentWidth: Int, in selectedRanges: [NSRange]) -> EditingContext? {
        
        assert(indentWidth > 0)
        
        // get indent target
        let string = self as NSString
        
        // find ranges to remove
        let lineRanges = string.lineRanges(for: selectedRanges)
        let lines = lineRanges.map { string.substring(with: $0) }
        let dropCounts = lines.map { line -> Int in
            switch line.first {
                case "\t": 1
                case " ": line.prefix(indentWidth).prefix(while: { $0 == " " }).count
                default: 0
            }
        }
        
        // cancel if nothing to shift
        guard dropCounts.contains(where: { $0 > 0 }) else { return nil }
        
        // create shifted string
        let newLines = zip(lines, dropCounts).map { String($0.dropFirst($1)) }
        
        // calculate new selection range
        let droppedRanges: [NSRange] = zip(lineRanges, dropCounts)
            .filter { $1 > 0 }
            .map { NSRange(location: $0.location, length: $1) }
        let newSelectedRanges = selectedRanges.map { selectedRange -> NSRange in
            let offset = droppedRanges
                .prefix { $0.location < selectedRange.location }
                .map { (selectedRange.intersection($0) ?? $0).length }
                .reduce(0, +)
            let lengthDiff = droppedRanges
                .compactMap { selectedRange.intersection($0)?.length }
                .reduce(0, +)
            
            return NSRange(location: selectedRange.location - offset,
                           length: selectedRange.length - lengthDiff)
        }
        
        return EditingContext(strings: newLines, ranges: lineRanges, selectedRanges: newSelectedRanges)
    }
    
    
    /// Standardizes indentation of given ranges.
    func convertIndentation(to style: IndentStyle, indentWidth: Int, in selectedRanges: [NSRange]) -> EditingContext? {
        
        guard !self.isEmpty else { return nil }
        
        let string = self as NSString
        
        // process whole document if no text selected
        let ranges = selectedRanges.contains(where: { !$0.isEmpty }) ? [string.range] : selectedRanges
        
        var replacementRanges: [NSRange] = []
        var replacementStrings: [String] = []
        
        for range in ranges {
            let selectedString = string.substring(with: range)
            let convertedString = selectedString.standardizingIndent(to: style, tabWidth: indentWidth)
            
            guard convertedString != selectedString else { continue }  // no need to convert
            
            replacementRanges.append(range)
            replacementStrings.append(convertedString)
        }
        
        return EditingContext(strings: replacementStrings, ranges: replacementRanges)
    }
}

    
public extension String {
    
    /// Detected indent style.
    var detectedIndentStyle: IndentStyle? {
        
        guard !self.isEmpty else { return nil }
        
        // count up indentation
        var tabCount = 0
        var spaceCount = 0
        var lineCount = 0
        self.enumerateLines { (line, stop) in
            // check first character
            switch line.first {
                case "\t":
                    tabCount += 1
                case " " where line.starts(with: "  "):
                    spaceCount += 1
                default:
                    break
            }
            
            lineCount += 1
            if lineCount >= DetectionLines.max {
                stop = true
            }
        }
        
        // no enough lines to detect
        guard max(tabCount, spaceCount) >= DetectionLines.min else { return nil }
        
        // detect indent style
        if tabCount > spaceCount * 2 {
            return .tab
        }
        if spaceCount > tabCount * 2 {
            return .space
        }
        
        return nil
    }
    
    
    /// Standardizes indent style.
    func standardizingIndent(to indentStyle: IndentStyle, tabWidth: Int) -> String {
        
        let spaces = String(repeating: " ", count: tabWidth)
        
        let indent: (before: String, after: String) = switch indentStyle {
            case .space: (before: "\t", after: spaces)
            case .tab:   (before: spaces, after: "\t")
        }
        
        let regex = try! Regex("(^|\\G)" + indent.before).anchorsMatchLineEndings()
        
        return self.replacing(regex, with: indent.after)
    }
    
    
    /// Detects indent level of line at the location.
    func indentLevel(at index: String.Index, tabWidth: Int) -> Int {
        
        assert(tabWidth > 0)
        
        guard let indentRange = self.rangeOfIndent(at: index) else { return 0 }
        
        let indent = self[indentRange]
        let numberOfTabs = indent.count { $0 == "\t" }
        
        return numberOfTabs + ((indent.count - numberOfTabs) / tabWidth)
    }
    
    
    /// Returns the range of indent characters in line at the location.
    func rangeOfIndent(at location: Int) -> NSRange? {
        
        let lineRange = (self as NSString).lineRange(at: location)
        let range = (self as NSString).range(of: "^[ \\t]++", options: .regularExpression, range: lineRange)
        
        guard range.location != NSNotFound else { return nil }
        
        return range
    }
    
    
    /// Returns the range of indent characters in line at the location.
    func rangeOfIndent(at index: String.Index) -> Range<String.Index>? {
        
        self[self.lineRange(at: index)].firstRange(of: /^[ \t]++/)
    }
    
    
    /// Returns the range for deleting soft-tab or nil if the character to delete is not a space.
    ///
    /// - Parameters:
    ///   - range: The range of selection.
    ///   - tabWidth: The number of spaces for the soft tab.
    /// - Returns: Range to delete or nil if the character to delete is not soft-tab.
    func rangeForSoftTabDeletion(in range: NSRange, tabWidth: Int) -> NSRange? {
        
        assert(tabWidth > 0)
        assert(range.location != NSNotFound)
        
        guard range.isEmpty else { return nil }
        
        let lineStartIndex = (self as NSString).lineStartIndex(at: range.location)
        let forwardRange = NSRange(lineStartIndex..<range.location)
        
        guard (self as NSString).range(of: "^ ++$", options: .regularExpression, range: forwardRange).length > 1 else { return nil }
        
        let column = self.column(of: range.location, tabWidth: tabWidth)
        let targetLength = tabWidth - (column % tabWidth)
        let targetRange = NSRange(location: range.location - targetLength, length: targetLength)
        
        guard
            range.location >= targetLength,
            (self as NSString).substring(with: targetRange).allSatisfy({ $0 == " " })
        else { return nil }
        
        return targetRange
    }
    
    
    /// Returns the oft-tab string to add.
    ///
    /// - Parameters:
    ///   - location: The location of insertion point.
    ///   - tabWidth: The number of spaces for the soft tab.
    /// - Returns: String to insert as the tab.
    func softTab(at location: Int, tabWidth: Int) -> String {
        
        assert(tabWidth > 0)
        assert(location >= 0)
        
        let column = self.column(of: location, tabWidth: tabWidth)
        let length = tabWidth - (column % tabWidth)
        
        return String(repeating: " ", count: length)
    }
    
    
    // MARK: Private Methods
    
    /// Calculates column number at location in the line expanding tab (\t) character.
    private func column(of location: Int, tabWidth: Int) -> Int {
        
        assert(tabWidth > 0)
        
        let index = String.Index(utf16Offset: location, in: self)
        let lineStartIndex = self.lineStartIndex(at: index)
        
        return self[lineStartIndex..<index].lazy
            .map { $0 == "\t" ? tabWidth : $0.utf16.count }
            .reduce(0, +)
    }
}
