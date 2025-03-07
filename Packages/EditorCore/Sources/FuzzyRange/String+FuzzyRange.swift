//
//  String+FuzzyRange.swift
//  FuzzyRange
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-25.
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

import Foundation

public extension String {
    
    /// Converts FuzzyRange that allows negative values to a valid NSRange.
    ///
    /// - Note:
    ///   A negative location accesses the element by counting backwards from the end.
    ///   For example, `location == -1` is the location after the last character.
    ///
    ///   Likewise, a negative length can be used to select rest elements except the last one element.
    ///   e.g. Passing `FuzzyRange(location: 3, length: -1)` to a string that has 10 characters returns `NSRange(3..<9)`.
    ///
    /// - Parameters:
    ///   - range: The character range using the grapheme cluster unit that allows also negative values.
    /// - Returns: A character range, or `nil` if the given value is out of range.
    func range(in range: FuzzyRange) -> NSRange? {
        
        let wholeLength = self.count
        let newLocation = (range.location >= 0) ? range.location : (wholeLength + range.location + 1)
        let newLength = (range.length >= 0) ? range.length : (wholeLength - newLocation + range.length)
        
        guard
            newLocation >= 0,
            newLength >= 0,
            newLocation <= wholeLength
        else { return nil }
        
        let lowerBound = self.index(self.startIndex, offsetBy: newLocation)
        let upperBound = self.index(lowerBound, offsetBy: newLength, limitedBy: self.endIndex) ?? self.endIndex
        
        return NSRange(lowerBound..<upperBound, in: self)
    }
    
    
    /// Returns the character range for the line range that allows negative values.
    ///
    /// - Note:
    ///   `location` of the passed-in range is 1-based. Passing a fuzzy range whose location is `0` returns `nil`.
    ///   The last line ending will be included to the return value.
    ///
    /// - Parameters:
    ///   - lineRange: The line range that allows also negative values.
    ///   - includingLineEnding: Whether includes the last line ending to the return value.
    /// - Returns: A character range, or `nil` if the given value is out of range.
    func rangeForLine(in lineRange: FuzzyRange, includingLineEnding: Bool = true) -> NSRange? {
        
        let length = (self as NSString).length
        let pattern = includingLineEnding ? #"(?<=\A|\R).*(?:\R|\z)"# : #"(?<=\A|\R).*$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        let lineRanges = regex.matches(in: self, range: NSRange(..<length)).map(\.range)
        let count = lineRanges.count
        
        guard lineRange.location != 0 else { return NSRange(0..<0) }
        guard lineRange.location <= count else { return NSRange(location: length, length: 0) }
        
        let newLocation = (lineRange.location > 0) ? lineRange.location - 1 : (count + lineRange.location)  // 1-based to 0-based
        let newLength: Int = switch lineRange.length {
            case ..<0: count - newLocation + lineRange.length - 1
            case 0: 0
            default: lineRange.length - 1
        }
        
        guard lineRanges.indices.contains(newLocation + newLength) else { return nil }
        
        let firstLineRange = lineRanges[newLocation]
        let lastLineRange = lineRanges[newLocation + newLength]
        
        return NSRange(firstLineRange.lowerBound..<lastLineRange.upperBound)
    }
    
    
    /// Returns the cursor location for fuzzily specified line and column.
    ///
    /// - Note:
    ///   `line` of the passed-in range is 1-based.
    ///
    /// - Parameters:
    ///   - line: The number of the line that allows also negative values.
    ///   - column: The number of the column that allows also negative values.
    /// - Returns: An NSRange-based cursor location.
    func fuzzyLocation(line: Int, column: Int = 0) throws(FuzzyLocationError) -> Int {
        
        let fuzzyLineRange = FuzzyRange(location: line == 0 ? 1 : line, length: 0)
        guard let lineRange = self.rangeForLine(in: fuzzyLineRange, includingLineEnding: false) else {
            throw .invalidLine(line)
        }
        
        let fuzzyColumnRange = FuzzyRange(location: column, length: 0)
        guard let rangeInLine = (self as NSString).substring(with: lineRange).range(in: fuzzyColumnRange) else {
            throw .invalidColumn(column)
        }
        
        return lineRange.location + rangeInLine.location
    }
}


public enum FuzzyLocationError: Error, Equatable {
    
    case invalidLine(Int)
    case invalidColumn(Int)
    
    
    var localizedDescription: String {
        
        switch self {
            case .invalidLine(let line):
                "The line number \(line) is out of the range."
            case .invalidColumn(let column):
                "The column number \(column) is out of the range."
        }
    }
}
