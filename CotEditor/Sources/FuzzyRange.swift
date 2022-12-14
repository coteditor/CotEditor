//
//  FuzzyRange.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2022 1024jp
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

/// A range representation that allows negative values.
///
/// When a negative value is set, it generally counts the elements from the end of the sequence.
struct FuzzyRange: Equatable {
    
    var location: Int
    var length: Int
}


extension FuzzyRange {
    
    /// Create a FuzzyRange instance from a string representation joined by `:`.
    init?(string: String) {
        
        let components = string.components(separatedBy: ":").map(Int.init)
        
        guard
            (1...2).contains(components.count),
            let location = components[0],
            let length = (components.count > 1) ? components[1] : 0
        else { return nil }
        
        self.location = location
        self.length = length
    }
    
    
    /// String representation joined by `:`.
    ///
    /// The length is omitted when it is 0 or 1.
    var string: String {
        
        (0...1).contains(self.length)
            ? String(self.location)
            : String(self.location) + ":" + String(self.length)
    }
}



extension String {
    
    /// Convert FuzzyRange that allows negative values to the valid NSRange.
    ///
    /// - Note:
    ///   A negative location accesses the element by counting backwards from the end.
    ///   For example, `location == -1` is the location after the last character.
    ///
    ///   Likewise, a negative length can be used to select rest elements except the last one element.
    ///   e.g. Passing `FuzzyRange(location: 3, length: -1)` to a string that has 10 characters returns `NSRange(3..<9)`.
    ///
    /// - Parameters:
    ///   - range: The character range that allows also negative values.
    /// - Returns: A character range, or `nil` if the given value is out of range.
    func range(in range: FuzzyRange) -> NSRange? {
        
        let wholeLength = self.length
        let newLocation = (range.location >= 0) ? range.location : (wholeLength + range.location + 1)
        let newLength = (range.length >= 0) ? range.length : (wholeLength - newLocation + range.length)
        
        guard
            newLocation >= 0,
            newLength >= 0,
            newLocation <= wholeLength
        else { return nil }
        
        return NSRange(newLocation..<min(newLocation + newLength, wholeLength))
    }
    
    
    /// Return the character range for the line range that allows negative values.
    ///
    /// - Note:
    ///   `location` of the passed-in range is 1-based. Passing a fuzzy range whose location is `0` returns `nil`.
    ///   The last new line character will be included to the return value.
    ///
    /// - Parameters:
    ///   - lineRange: The line range that allows also negative values.
    ///   - includingLineEnding: Whether includes the last line ending to the return value.
    /// - Returns: A character range, or `nil` if the given value is out of range.
    func rangeForLine(in lineRange: FuzzyRange, includingLineEnding: Bool = true) -> NSRange? {
        
        let pattern = includingLineEnding ? "(?<=\\A|\\R).*(?:\\R|\\z)" : "(?<=\\A|\\R).*$"
        let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        let lineRanges = regex.matches(in: self, range: self.nsRange).map(\.range)
        let count = lineRanges.count
        
        guard lineRange.location != 0 else { return NSRange(0..<0) }
        guard lineRange.location <= count else { return NSRange(location: self.length, length: 0) }
        
        let newLocation = (lineRange.location > 0) ? lineRange.location - 1 : (count + lineRange.location)  // 1-based to 0-based
        let newLength: Int = {
            switch lineRange.length {
                case ..<0:
                    return count - newLocation + lineRange.length - 1
                case 0:
                    return 0
                default:
                    return lineRange.length - 1
            }
        }()
        
        guard
            let firstLineRange = lineRanges[safe: newLocation],
            let lastLineRange = lineRanges[safe: newLocation + newLength]
        else { return nil }
        
        return NSRange(firstLineRange.lowerBound..<lastLineRange.upperBound)
    }
    
    
    /// Return the cursor location for fuzzily specified line and column.
    ///
    /// - Note:
    ///   `line` of the passed-in range is 1-based.
    ///
    /// - Parameters:
    ///   - line: The number of the line that allows also negative values.
    ///   - column: The number of the column that allows also negative values.
    /// - Throws: FuzzyLocationError
    /// - Returns: An NSRange-based cursor location.
    func fuzzyLocation(line: Int, column: Int = 0) throws -> Int {
        
        let fuzzyLineRange = FuzzyRange(location: line == 0 ? 1 : line, length: 0)
        guard let lineRange = self.rangeForLine(in: fuzzyLineRange, includingLineEnding: false) else {
            throw FuzzyLocationError.invalidLine(line)
        }
        
        let fuzzyColumnRange = FuzzyRange(location: column, length: 0)
        guard let rangeInLine = (self as NSString).substring(with: lineRange).range(in: fuzzyColumnRange) else {
            throw FuzzyLocationError.invalidColumn(column)
        }
        
        return lineRange.location + rangeInLine.location
    }
}



enum FuzzyLocationError: Error {
    
    case invalidLine(Int)
    case invalidColumn(Int)
    
    
    var localizedDescription: String {
        
        switch self {
            case .invalidLine(let line):
                return "The line number \(line) is out of the range."
            case .invalidColumn(let column):
                return "The column number \(column) is out of the range."
        }
    }
}
