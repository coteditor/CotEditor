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

/// A range representation that allows negative values.
///
/// When a negative value is set, it generally counts the elements from the end of the sequence.
struct FuzzyRange: Equatable {
    
    var location: Int
    var length: Int = 0
}



// MARK: - Format Style

extension FuzzyRange {
    
    /// Gets a formatted string from a format style.
    ///
    /// - Parameter style: The fuzzy range format style.
    /// - Returns: A formatted string.
    func formatted(_ style: FuzzyRangeFormatStyle = .init()) -> FuzzyRangeFormatStyle.FormatOutput {
        
        style.format(self)
    }
}


extension FormatStyle where Self == FuzzyRange.FuzzyRangeFormatStyle {
    
    static var fuzzyRange: FuzzyRange.FuzzyRangeFormatStyle {
        
        FuzzyRange.FuzzyRangeFormatStyle()
    }
}


extension FuzzyRange {
    
    struct FuzzyRangeFormatStyle: ParseableFormatStyle {
        
        var parseStrategy: FuzzyRangeParseStrategy {
            
            FuzzyRangeParseStrategy()
        }
        
        
        func format(_ value: FuzzyRange) -> String {
            
            (0...1).contains(value.length)
                ? String(value.location)
                : String(value.location) + ":" + String(value.length)
        }
    }
}


struct FuzzyRangeParseStrategy: ParseStrategy {
    
    enum ParseError: Error {
        
        case invalidValue
    }
    
    
    /// Creates an instance of the `ParseOutput` type from `value`.
    ///
    /// - Parameter value: The string representation of `FuzzyRange` instance.
    /// - Returns: A `FuzzyRange` instance.
    /// - Throws: `ParseError`.
    func parse(_ value: String) throws -> FuzzyRange {
        
        let components = value.split(separator: ":").map(String.init).map(Int.init)
        
        guard
            (1...2).contains(components.count),
            let location = components[0],
            let length = (components.count > 1) ? components[1] : 0
        else { throw ParseError.invalidValue }
        
        return FuzzyRange(location: location, length: length)
    }
}


// MARK: - NSRange conversion

extension String {
    
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
        
        let pattern = includingLineEnding ? "(?<=\\A|\\R).*(?:\\R|\\z)" : "(?<=\\A|\\R).*$"
        let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        let lineRanges = regex.matches(in: self, range: self.nsRange).map(\.range)
        let count = lineRanges.count
        
        guard lineRange.location != 0 else { return NSRange(0..<0) }
        guard lineRange.location <= count else { return NSRange(location: self.length, length: 0) }
        
        let newLocation = (lineRange.location > 0) ? lineRange.location - 1 : (count + lineRange.location)  // 1-based to 0-based
        let newLength: Int = switch lineRange.length {
            case ..<0: count - newLocation + lineRange.length - 1
            case 0: 0
            default: lineRange.length - 1
        }
        
        guard
            let firstLineRange = lineRanges[safe: newLocation],
            let lastLineRange = lineRanges[safe: newLocation + newLength]
        else { return nil }
        
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
    /// - Throws: `FuzzyLocationError`.
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



enum FuzzyLocationError: Error, Equatable {
    
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
