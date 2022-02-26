//
//  String+NSRange.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

import Foundation.NSString

extension String {
    
    /// Whole range in NSRange.
    var nsRange: NSRange {
        
        return NSRange(location: 0, length: (self as NSString).length)
    }
    
    
    var length: Int {
        
        return self.utf16.count
    }
    
}



extension NSRange {
    
    static let notFound = NSRange(location: NSNotFound, length: 0)
    
    
    /// A boolean value indicating whether the range contains no elements.
    var isEmpty: Bool {
        
        return (self.length == 0)
    }
    
    
    /// Check if the given index is in the receiver or touchs to one of the receiver's bounds.
    ///
    /// - Parameter index: The index to test.
    func touches(_ index: Int) -> Bool {
        
        return self.lowerBound <= index && index <= self.upperBound
    }
    
    
    /// Return a boolean indicating whether the specified range intersects the receiver’s range.
    ///
    /// - Parameter other: The other range.
    func intersects(_ other: NSRange) -> Bool {
        
        return self.intersection(other) != nil
    }
    
    
    /// Check if the two ranges overlap or touch each other.
    ///
    /// - Parameter range: The range to test.
    /// - Note: Unlike Swift.Range's `overlaps(_:)`, this method returns `true` when a range length is 0.
    func touches(_ range: NSRange) -> Bool {
        
        if self.location == NSNotFound { return false }
        if range.location == NSNotFound { return false }
        if self.upperBound < range.lowerBound { return false }
        if range.upperBound < self.lowerBound { return false }
        
        return true
    }
    
    
    /// Return a copied NSRange but whose location is shifted toward the given `offset`.
    ///
    /// - Parameter offset: The offset to shift.
    /// - Returns: A new NSRange.
    func shifted(offset: Int) -> NSRange {
        
        return NSRange(location: self.location + offset, length: self.length)
    }
    
}



extension NSString {
    
    /// Whole range in NSRange
    var range: NSRange {
        
        return NSRange(location: 0, length: self.length)
    }
    
    
    /// Return NSRange-based character index where just before the given character index
    /// by taking grapheme clusters into account.
    ///
    /// - Parameter location: NSRange-based character index to refer.
    /// - Returns: NSRange-based character index just before the given `location`,
    ///            or `0` when the given `location` is the first.
    func index(before location: Int) -> Int {
        
        guard location > 0 else { return 0 }
        
        // avoid returing index between CRLF
        let index = location - 1
        let offset = (self.character(at: index) == 0x000A && self.character(at: index - 1) == 0x000D) ? 1 : 0
        
        return self.rangeOfComposedCharacterSequence(at: index - offset).lowerBound
    }
    
    
    /// Return NSRange-based character index where just after the given character index
    /// by taking grapheme clusters into account.
    ///
    /// - Parameter location: NSRange-based character index to refer.
    /// - Returns: NSRange-based character index just before the given `location`,
    ///            or `location` when the given `location` is the last.
    func index(after location: Int) -> Int {
        
        guard location < self.length - 1 else { return self.length }
        
        // avoid returing index between CRLF
        let index = location
        let offset = (self.character(at: index) == 0x000D && self.character(at: index + 1) == 0x000A) ? 1 : 0
        
        return self.rangeOfComposedCharacterSequence(at: index + offset).upperBound
    }
    
    
    /// Find and return ranges of passed-in substring with the given range of receiver.
    ///
    /// - Parameters:
    ///   - searchString: The string for which to search.
    ///   - options: A mask specifying search options.
    ///   - searchRange: The range with in the receiver for which to search for aString.
    /// - Returns: An array of NSRange in the receiver of `searchString` within `searchRange`.
    func ranges(of searchString: String, options: NSString.CompareOptions = .literal, range searchRange: NSRange? = nil) -> [NSRange] {
        
        let searchRange = searchRange ?? self.range
        var ranges = [NSRange]()
        
        var location = searchRange.location
        while location != NSNotFound {
            let range = self.range(of: searchString, options: options, range: NSRange(location..<searchRange.upperBound))
            location = range.upperBound
            
            guard range.location != NSNotFound else { break }
            
            ranges.append(range)
        }
        
        return ranges
    }
    
    
    /// line range containing a given location
    func lineRange(at location: Int) -> NSRange {
        
        return self.lineRange(for: NSRange(location: location, length: 0))
    }
    
    
    /// line range containing a given location
    func lineContentsRange(at location: Int) -> NSRange {
        
        return self.lineContentsRange(for: NSRange(location: location, length: 0))
    }
    
    
    /// Return line range excluding last line ending character if exists.
    ///
    /// - Parameters:
    ///   - range: A range within the receiver.
    /// - Returns: The range of characters representing the line or lines containing a given range.
    func lineContentsRange(for range: NSRange) -> NSRange {
        
        var start = 0
        var contentsEnd = 0
        self.getLineStart(&start, end: nil, contentsEnd: &contentsEnd, for: range)
        
        return NSRange(location: start, length: contentsEnd - start)
    }
    
    
    /// Return the index of the first character of the line touched by the given index.
    ///
    /// - Parameters:
    ///   - index: The index of character for finding the line start.
    /// - Returns: The character index of the nearest line start.
    func lineStartIndex(at index: Int) -> Int {
        
        var start = 0
        self.getLineStart(&start, end: nil, contentsEnd: nil, for: NSRange(location: index, length: 0))
        
        return start
    }
    
    
    /// Return the index of the last character before the line ending of the line touched by the given index.
    ///
    /// - Parameters:
    ///   - index: The index of character for finding the line contents end.
    /// - Returns: The character index of the nearest line contents end.
    func lineContentsEndIndex(at index: Int) -> Int {
        
        var contentsEnd = 0
        self.getLineStart(nil, end: nil, contentsEnd: &contentsEnd, for: NSRange(location: index, length: 0))
        
        return contentsEnd
    }
    
    
    /// Calculate line-by-line ranges that given ranges include.
    ///
    /// - Parameters:
    ///   - ranges: Ranges to include.
    ///   - includingLastEmptyLine: Whether the last empty line sould be included; otherwise, return value can be empty.
    /// - Returns: Array of ranges of each indivisual line.
    func lineRanges(for ranges: [NSRange], includingLastEmptyLine: Bool = false) -> [NSRange] {
        
        guard !ranges.isEmpty else { return [] }
        
        if includingLastEmptyLine,
            ranges == [NSRange(location: self.length, length: 0)],
            (self.length == 0 || self.character(at: self.length - 1).isNewline)
        {
            return ranges
        }
        
        var lineRanges = OrderedSet<NSRange>()
        
        // get line ranges to process
        for range in ranges {
            let linesRange = self.lineRange(for: range)
            
            // store each line to process
            self.enumerateSubstrings(in: linesRange, options: [.byLines, .substringNotRequired]) { (_, _, enclosingRange, _) in
                lineRanges.append(enclosingRange)
            }
        }
        
        return lineRanges.array
    }
    
    
    /// Fast way to count the number of lines at the character index (1-based).
    ///
    /// Counting in this way is significantly faster than other ways such as `enumerateSubstrings(in:options:.byLines)`,
    /// `components(separatedBy: .newlines)`, or even just counting `\n` in `.utf16`. (2020-02, Swift 5.1)
    ///
    /// - Parameter location: NSRange-based character index.
    /// - Returns: The number of lines (1-based).
    func lineNumber(at location: Int) -> Int {
        
        assert(location == 0 || location <= self.length)
        
        guard self.length > 0, location > 0 else { return 1 }
        
        var count = 0
        var index = 0
        while index < location {
            self.getLineStart(nil, end: &index, contentsEnd: nil, for: NSRange(location: index, length: 0))
            count += 1
        }
        
        if self.character(at: location - 1).isNewline {
            count += 1
        }
        
        return count
    }
    
    
    /// Find the widest character range that contains the given `index` and not contains given character set.
    ///
    /// - Parameters:
    ///   - set: The character set to end expanding range.
    ///   - index: The index of character to be contained to the result range. `index` must be within `range`.
    ///   - range: The range in which to search. `range` must not exceed the bounds of the receiver.
    /// - Returns: The found character range.
    func rangeOfCharacter(until set: CharacterSet, at index: Int, range: NSRange? = nil) -> NSRange {
        
        let range = range ?? self.range
        
        assert(range.contains(index))
        
        let lowerDelimiterRange = self.rangeOfCharacter(from: set, options: .backwards, range: NSRange(range.lowerBound..<index))
        let lowerBound = (lowerDelimiterRange != .notFound) ? lowerDelimiterRange.upperBound : range.lowerBound
        
        let upperDelimiterRange = self.rangeOfCharacter(from: set, range: NSRange(index..<range.upperBound))
        let upperBound = (upperDelimiterRange != .notFound) ? upperDelimiterRange.lowerBound : range.upperBound
        
        return NSRange(lowerBound..<upperBound)
    }
    
    
    /// Return the boundary of the composed character sequence by moving the offset by counting offset in composed character sequences.
    ///
    /// - Parameters:
    ///   - index: The reference characer index in UTF-16.
    ///   - offset: The number of composed character sequences to move index.
    /// - Returns:A characer index in UTF-16.
    func boundaryOfComposedCharacterSequence(_ index: Int, offsetBy offset: Int) -> Int {
        
        assert(index >= 0 && index < self.length)
        
        let reverse = (offset <= 0)
        let range = reverse ? NSRange(location: 0, length: min(index + 1, self.length)) : NSRange(location: index, length: self.length - index)
        var options: EnumerationOptions = [.byComposedCharacterSequences, .substringNotRequired]
        if reverse {
            options.formUnion(.reverse)
        }
        
        var boundary = index
        var remainingCount = reverse ? -offset + 1 : offset
        self.enumerateSubstrings(in: range, options: options) { (_, range, _, stop) in
            
            boundary = reverse ? range.lowerBound : range.upperBound
            
            remainingCount -= 1
            if remainingCount <= 0 {
                stop.pointee = true
            }
        }
        
        return boundary
    }
    
}


extension unichar {
    
    /// A Boolean value indicating whether this character represents a newline.
    ///
    /// cf. <https://developer.apple.com/documentation/swift/character/3127014-isnewline>
    var isNewline: Bool {
        
        switch self {
            case 0x000A, 0x000B, 0x000C, 0x000D, 0x0085, 0x2028, 0x2029:
                return true
            default:
                return false
        }
    }
    
}
