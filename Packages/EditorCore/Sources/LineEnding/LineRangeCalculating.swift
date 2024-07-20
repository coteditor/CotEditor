//
//  LineRangeCalculating.swift
//  LineEnding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import ValueRange

public protocol LineRangeCalculating {
    
    /// The UTF16-based length of the contents string.
    var length: Int { get }
    
    /// Line Endings sorted by location.
    var lineEndings: [ValueRange<LineEnding>] { get }
}


public extension LineRangeCalculating {
    
    /// Returns the 1-based line number at the given character index.
    ///
    /// - Parameter characterIndex: The character index.
    /// - Returns: The 1-based line number.
    func lineNumber(at characterIndex: Int) -> Int {
        
        assert(characterIndex <= self.length)
        
        (self as? any LazyLineEndingCaching)?.ensureLineEndings(upTo: characterIndex - 1)
        
        return self.lineEndings.lineIndex(at: characterIndex) + 1
    }
    
    
    /// Returns the index of the first character of the line touches the given index.
    ///
    /// - Parameter characterIndex: The index of character for finding the line start.
    /// - Returns: The character index of the nearest line start.
    func lineStartIndex(at characterIndex: Int) -> Int {
        
        assert(characterIndex <= self.length)
        
        (self as? any LazyLineEndingCaching)?.ensureLineEndings(upTo: characterIndex - 1)
        
        return self.lineEndings.lineBounds(for: NSRange(location: characterIndex, length: 0)).start
    }
    
    
    /// Returns the range of the line touches the given index.
    ///
    /// - Parameter characterIndex: The index of character for finding the line range.
    /// - Returns: The character range of the line.
    func lineRange(at characterIndex: Int) -> NSRange {
        
        assert(characterIndex <= self.length)
        
        (self as? any LazyLineEndingCaching)?.ensureLineEndings(upTo: characterIndex, needsNextEnd: true)
        
        let bounds = self.lineEndings.lineBounds(for: NSRange(location: characterIndex, length: 0))
        
        return NSRange(bounds.start..<(bounds.end?.upperBound ?? self.length))
    }
    
    
    /// Returns the range of the contents lines including the given range.
    ///
    /// - Parameter range: The range of character for finding the line range.
    /// - Returns: The character range of the contents line.
    func lineContentsRange(for range: NSRange) -> NSRange {
        
        assert(range.upperBound <= self.length)
        
        (self as? any LazyLineEndingCaching)?.ensureLineEndings(upTo: range.upperBound, needsNextEnd: true)
        
        let bounds = self.lineEndings.lineBounds(for: range)
        
        return NSRange(bounds.start..<(bounds.end?.lowerBound ?? self.length))
    }
}


extension BidirectionalCollection where Element == ValueRange<LineEnding>, Index == Int {
    
    /// Returns the 0-based line number at the given character index.
    ///
    /// - Note: Elements must be sorted by location without range overwrap.
    ///
    /// - Parameter characterIndex: The character index.
    /// - Returns: The 0-based line number.
    func lineIndex(at characterIndex: Int) -> Int {
        
        if let last = self.last, last.upperBound <= characterIndex {
            self.endIndex
        } else if let index = self.binarySearchedFirstIndex(where: { $0.upperBound > characterIndex }) {
            index
        } else {
            0
        }
    }
    
    
    /// Returns the bounds of the lines including the given range.
    ///
    /// - Note: Elements must be sorted by location without range overwrap.
    ///
    /// - Parameter range: The character range to find.
    /// - Returns: The character index where starts the line and the range of the line ending.
    func lineBounds(for range: NSRange) -> (start: Int, end: ValueRange<LineEnding>?) {
        
        guard !self.isEmpty else { return (0, nil) }
        
        let startPassedIndex = if let lastBound = self.last?.upperBound, lastBound <= range.lowerBound {
            self.endIndex
        } else {
            self.binarySearchedFirstIndex { range.lowerBound < $0.upperBound } ?? self.startIndex
        }
        let start = (startPassedIndex > self.startIndex) ? self[self.index(before: startPassedIndex)].upperBound : 0
        
        let startPassed = self.indices.contains(startPassedIndex) ? self[startPassedIndex] : nil
        let end: ValueRange<LineEnding>? = if let startPassed, range.upperBound <= startPassed.upperBound {
            startPassed
        } else if range.length > 0 {
            self.binarySearchedFirstIndex(in: startPassedIndex..<self.endIndex) { range.upperBound <= $0.upperBound }
                .flatMap { self[$0] }
        } else {
            nil
        }
        
        return (start, end)
    }
}
