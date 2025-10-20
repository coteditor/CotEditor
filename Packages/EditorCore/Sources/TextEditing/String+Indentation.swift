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
//  © 2015-2025 1024jp
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

public enum IndentStyle: Equatable, Sendable {
    
    case tab
    case space
}


private enum DetectionLines {
    
    static let min = 3
    static let max = 100
}


public extension String {
    
    /// Increases the indentation level of each line that intersects the given selections.
    ///
    /// - Parameters:
    ///   - style: The indent style to covert to.
    ///   - indentWidth: The number of characters for the indentation.
    ///   - selectedRanges: The selection in the editor.
    /// - Returns: An `EditingContext`.
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
            let lineCount = lineRanges.prefix(while: selectedRange.intersects).count
            let lengthDiff = max(lineCount - 1, 0) * indentLength
            
            return NSRange(location: selectedRange.location + shift * indentLength,
                           length: selectedRange.length + lengthDiff)
        }
        
        return EditingContext(strings: newLines, ranges: lineRanges, selectedRanges: newSelectedRanges)
    }
    
    
    /// Decreases the indentation level of each line that intersects the given selections.
    ///
    /// - Parameters:
    ///   - style: The indent style to covert to.
    ///   - indentWidth: The number of characters for the indentation.
    ///   - selectedRanges: The selection in the editor.
    /// - Returns: An `EditingContext`, or `nil` if no changes were necessary.
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
    
    
    /// Standardizes leading indentation to the specified style within the given selections.
    ///
    /// - Parameters:
    ///   - style: The target indentation style.
    ///   - indentWidth: The number of characters for the indentation.
    ///   - selectedRanges: The selection in the editor.
    /// - Returns: An `EditingContext`, or `nil` if no changes were necessary.
    func convertIndentation(to style: IndentStyle, indentWidth: Int, in selectedRanges: [NSRange]) -> EditingContext? {
        
        assert(indentWidth > 0)
        
        guard !self.isEmpty else { return nil }
        
        let string = self as NSString
        
        // process whole document if no text selected
        let ranges = selectedRanges.contains(where: { !$0.isEmpty }) ? selectedRanges : [string.range]
        
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
    
    /// The predominant indentation style used in the string.
    var detectedIndentStyle: IndentStyle? {
        
        guard !self.isEmpty else { return nil }
        
        // count up indentation
        var tabCount = 0
        var spaceCount = 0
        var lineCount = 0
        self.enumerateLines { line, stop in
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
    
    
    /// Converts leading indentation to the specified style.
    ///
    /// - Parameters:
    ///   - indentStyle: The desired indentation style.
    ///   - tabWidth: The number of spaces that represent one tab stop.
    /// - Returns: A new string with standardized indentation.
    func standardizingIndent(to indentStyle: IndentStyle, tabWidth: Int) -> String {
        
        let spaces = String(repeating: " ", count: tabWidth)
        
        let indent: (before: String, after: String) = switch indentStyle {
            case .space: (before: "\t", after: spaces)
            case .tab:   (before: spaces, after: "\t")
        }
        
        let regex = try! Regex("(^|\\G)" + indent.before).anchorsMatchLineEndings()
        
        return self.replacing(regex, with: indent.after)
    }
    
    
    /// Computes the visual indent level at the given index by expanding tabs.
    ///
    /// - Parameters:
    ///   - index: A character index within the string.
    ///   - tabWidth: The number of spaces that represent one tab stop.
    /// - Returns: The number of indent levels.
    func indentLevel(at index: String.Index, tabWidth: Int) -> Int {
        
        assert(tabWidth > 0)
        
        guard let indentRange = self.rangeOfIndent(at: index) else { return 0 }
        
        let indent = self[indentRange]
        let numberOfTabs = indent.count { $0 == "\t" }
        
        return numberOfTabs + ((indent.count - numberOfTabs) / tabWidth)
    }
    
    
    /// Returns the range of leading whitespace (spaces or tabs) for the line containing `location`.
    ///
    /// - Parameter location: A UTF-16 offset within the string.
    /// - Returns: The `NSRange` covering the contiguous run of leading whitespace, or `nil` if the line does not start with whitespace.
    func rangeOfIndent(at location: Int) -> NSRange? {
        
        let lineRange = (self as NSString).lineRange(at: location)
        let range = (self as NSString).range(of: "^[ \\t]++", options: .regularExpression, range: lineRange)
        
        guard !range.isNotFound else { return nil }
        
        return range
    }
    
    
    /// Returns the range of leading whitespace (spaces or tabs) for the line containing `index`.
    ///
    /// - Parameter index: A character index within the string.
    /// - Returns: The range covering the contiguous run of leading whitespace, or `nil` if the line does not start with whitespace.
    func rangeOfIndent(at index: String.Index) -> Range<String.Index>? {
        
        self[self.lineRange(at: index)].firstRange(of: /^[ \t]++/)
    }
    
    
    /// Returns the soft-tab deletion range when the insertion point is within leading spaces.
    ///
    /// - Parameters:
    ///   - range: The current selection.
    ///   - tabWidth: The number of spaces that represent one tab stop.
    /// - Returns: The range of spaces to delete, or `nil` if the character to delete is not a space.
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
    
    
    /// Returns the soft-tab string (spaces) needed to reach the next tab stop.
    ///
    /// - Parameters:
    ///   - location: The base character index as a UTF-16 offset.
    ///   - tabWidth: The number of spaces that represent one tab stop.
    /// - Returns: A string of spaces.
    func softTab(at location: Int, tabWidth: Int) -> String {
        
        assert(tabWidth > 0)
        assert(location >= 0)
        
        let column = self.column(of: location, tabWidth: tabWidth)
        let length = tabWidth - (column % tabWidth)
        
        return String(repeating: " ", count: length)
    }
    
    
    // MARK: Private Methods
    
    /// Calculates the visual column from the start of the line to `location` by expanding tab characters.
    ///
    /// - Parameters:
    ///   - location: The base character index as a UTF-16 offset.
    ///   - tabWidth: The number of spaces that represent one tab stop.
    /// - Returns: The visual column count from the beginning of the line up to `location`.
    private func column(of location: Int, tabWidth: Int) -> Int {
        
        assert(tabWidth > 0)
        
        let index = String.Index(utf16Offset: location, in: self)
        let lineStartIndex = self.lineStartIndex(at: index)
        
        return self[lineStartIndex..<index].lazy
            .map { $0 == "\t" ? tabWidth : $0.utf16.count }
            .reduce(0, +)
    }
}
