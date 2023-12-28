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
//  © 2016-2023 1024jp
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

extension StringProtocol {
    
    /// Whole range in NSRange.
    var nsRange: NSRange {
        
        NSRange(location: 0, length: self.length)
    }
    
    
    var length: Int {
        
        self.utf16.count
    }
}


extension NSString {
    
    /// Whole range in NSRange
    var range: NSRange {
        
        NSRange(location: 0, length: self.length)
    }
    
    
    /// Returns NSRange-based character index where just before the given character index
    /// by taking grapheme clusters into account.
    ///
    /// - Parameter location: NSRange-based character index to refer.
    /// - Returns: NSRange-based character index just before the given `location`,
    ///            or `0` when the given `location` is the first.
    func index(before location: Int) -> Int {
        
        guard location > 0 else { return 0 }
        
        // avoid returning index between CRLF
        let index = location - 1
        let isCRLF = (index > 0 && self.character(at: index) == 0xA && self.character(at: index - 1) == 0xD)
        
        return self.rangeOfComposedCharacterSequence(at: isCRLF ? index - 1 : index).lowerBound
    }
    
    
    /// Returns NSRange-based character index where just after the given character index
    /// by taking grapheme clusters into account.
    ///
    /// - Parameter location: NSRange-based character index to refer.
    /// - Returns: NSRange-based character index just before the given `location`,
    ///            or `location` when the given `location` is the last.
    func index(after location: Int) -> Int {
        
        guard location < self.length - 1 else { return self.length }
        
        // avoid returning index between CRLF
        let index = location
        let isCRLF = (self.character(at: index) == 0xD && self.character(at: index + 1) == 0xA)
        
        return self.rangeOfComposedCharacterSequence(at: isCRLF ? index + 1 : index).upperBound
    }
    
    
    /// Finds and returns ranges of passed-in substring with the given range of receiver.
    ///
    /// - Parameters:
    ///   - searchString: The string for which to search.
    ///   - options: A mask specifying search options.
    ///   - searchRange: The range with in the receiver for which to search for aString.
    /// - Returns: An array of NSRange in the receiver of `searchString` within `searchRange`.
    func ranges(of searchString: String, options: NSString.CompareOptions = .literal, range searchRange: NSRange? = nil) -> [NSRange] {
        
        let searchRange = searchRange ?? self.range
        var ranges: [NSRange] = []
        
        var location = searchRange.location
        while location != NSNotFound {
            let range = self.range(of: searchString, options: options, range: NSRange(location..<searchRange.upperBound))
            location = range.upperBound
            
            guard range.location != NSNotFound else { break }
            
            ranges.append(range)
        }
        
        return ranges
    }
    
    
    /// Returns line range containing a given location.
    func lineRange(at location: Int) -> NSRange {
        
        self.lineRange(for: NSRange(location: location, length: 0))
    }
    
    
    /// Returns line content range containing a given location.
    func lineContentsRange(at location: Int) -> NSRange {
        
        self.lineContentsRange(for: NSRange(location: location, length: 0))
    }
    
    
    /// Returns line range excluding last line ending character if exists.
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
    
    
    /// Returns the index of the first character of the line touched by the given index.
    ///
    /// - Parameters:
    ///   - index: The index of character for finding the line start.
    /// - Returns: The character index of the nearest line start.
    func lineStartIndex(at index: Int) -> Int {
        
        var start = 0
        self.getLineStart(&start, end: nil, contentsEnd: nil, for: NSRange(location: index, length: 0))
        
        return start
    }
    
    
    /// Returns the index of the last character before the line ending of the line touched by the given index.
    ///
    /// - Parameters:
    ///   - index: The index of character for finding the line contents end.
    /// - Returns: The character index of the nearest line contents end.
    func lineContentsEndIndex(at index: Int) -> Int {
        
        var contentsEnd = 0
        self.getLineStart(nil, end: nil, contentsEnd: &contentsEnd, for: NSRange(location: index, length: 0))
        
        return contentsEnd
    }
    
    
    /// Calculates line-by-line ranges that given ranges include.
    ///
    /// - Parameters:
    ///   - ranges: Ranges to include.
    ///   - includingLastEmptyLine: Whether the last empty line should be included; otherwise, return value can be empty.
    /// - Returns: Array of ranges of each individual line.
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
    
    
    /// Finds the widest character range that contains the given `index` and not contains given character set.
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
        let lowerBound = !lowerDelimiterRange.isNotFound ? lowerDelimiterRange.upperBound : range.lowerBound
        
        let upperDelimiterRange = self.rangeOfCharacter(from: set, range: NSRange(index..<range.upperBound))
        let upperBound = !upperDelimiterRange.isNotFound ? upperDelimiterRange.lowerBound : range.upperBound
        
        return NSRange(lowerBound..<upperBound)
    }
    
    
    /// Returns the lower bound of the composed character sequence by moving the bound in the head direction by counting offset in composed character sequences.
    ///
    /// - Parameters:
    ///   - index: The reference character index in UTF-16.
    ///   - offset: The number of composed character sequences to move index.
    /// - Returns: A character index in UTF-16.
    func lowerBoundOfComposedCharacterSequence(_ index: Int, offsetBy offset: Int) -> Int {
        
        assert((0...self.length).contains(index))
        assert(offset >= 0)
        
        if index == self.length, offset == 0 { return index }
        
        var remainingCount = (index == self.length) ? offset : offset + 1
        var boundary = index
        
        let range = NSRange(..<min(index + 1, self.length))
        let options: EnumerationOptions = [.byComposedCharacterSequences, .substringNotRequired, .reverse]
        self.enumerateSubstrings(in: range, options: options) { (_, range, _, stop) in
            
            boundary = range.lowerBound
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
            case 0x000A, 0x000B, 0x000C, 0x000D, 0x0085, 0x2028, 0x2029: true
            default: false
        }
    }
}
