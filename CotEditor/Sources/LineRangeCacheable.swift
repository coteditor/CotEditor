//
//  LineRangeCacheable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2023 1024jp
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

protocol LineRangeCacheable: AnyObject {
    
    var string: NSString { get }
    var lineRangeCache: LineRangeCache { get set }
    
    /// Invalidate the line range cache.
    ///
    /// This method must be invoked every time when the receiver's `.string` is updated.
    ///
    /// - Parameters:
    ///   - newRange: The range in the final string that was edited.
    ///   - delta: The length delta for the editing changes.
    func invalidateLineRanges(in newRange: NSRange, changeInLength delta: Int)
}


struct LineRangeCache {
    
    fileprivate var lineStartIndexes = IndexSet()
    fileprivate var parsedIndexes = IndexSet()
    fileprivate var firstUncountedIndex = 0
}



extension LineRangeCacheable {
    
    // MARK: Public Methods
    
    /// Return the 1-based line number at the given character index.
    ///
    /// - Parameter index: The character index.
    /// - Returns: The 1-based line number.
    func lineNumber(at index: Int) -> Int {
        
        assert(index <= self.string.length)
        
        self.ensureLineRanges(upTo: index - 1)
        
        return self.lineRangeCache.lineStartIndexes.count(in: 0...index) + 1
    }
    
    
    /// Return the range of the line touched by the given index.
    ///
    /// Because this method count up all the line ranges up to the given index when not cached yet,
    /// there is a large performance disadvantage when just a single line range is needed.
    ///
    /// - Parameter index: The index of character for finding the line range.
    /// - Returns: The character range of the line.
    func lineRange(at index: Int) -> NSRange {
        
        self.lineRange(for: NSRange(location: index, length: 0))
    }
    
    
    /// Return the range of the lines including the given range.
    ///
    /// Because this method count up all the line ranges up to the given index when not cached yet,
    /// there is a large performance disadvantage when just a single line range is needed.
    ///
    /// - Parameter range: The range of character for finding the line range.
    /// - Returns: The character range of the line.
    func lineRange(for range: NSRange) -> NSRange {
        
        assert(range.upperBound <= self.string.length)
        
        self.ensureLineRanges(upTo: range.upperBound)
        
        let indexes = self.lineRangeCache.lineStartIndexes
        let lowerBound = indexes.integerLessThanOrEqualTo(range.lowerBound) ?? 0
        let upperBound = range.isEmpty
            ? indexes.integerGreaterThan(range.upperBound) ?? self.string.length
            : indexes.integerGreaterThanOrEqualTo(range.upperBound) ?? self.string.length
        
        return NSRange(location: lowerBound, length: upperBound - lowerBound)
    }
    
    
    /// Return the range of the content lines including the given range.
    ///
    /// Because this method count up all the line ranges up to the given index when not cached yet,
    /// there is a large performance disadvantage when just a single line range is needed.
    /// In addition, this method actually doesn't has much performance advantage becaouse it checks the line ending range.
    ///
    /// - Parameter range: The range of character for finding the line range.
    /// - Returns: The character range of the content line.
    func lineContentRange(for range: NSRange) -> NSRange {
        
        let lineRange = self.lineRange(for: range)
        
        guard range.upperBound < lineRange.upperBound else { return lineRange }
        
        let lineEndingRange = self.string.range(of: "\\R$", options: .regularExpression, range: lineRange)
        
        guard !lineEndingRange.isNotFound else { return lineRange }
        
        return NSRange(lineRange.lowerBound..<lineEndingRange.lowerBound)
    }
    
    
    /// Return the index of the first character of the line touched by the given index.
    ///
    /// Because this method count up all the line ranges up to the given index when not cached yet,
    /// there is a large performance disadvantage when just a single line start index is needed.
    ///
    /// - Parameter index: The index of character for finding the line start.
    /// - Returns: The character index of the nearest line start.
    func lineStartIndex(at index: Int) -> Int {
        
        assert(index <= self.string.length)
        
        self.ensureLineRanges(upTo: index - 1)
        
        return self.lineRangeCache.lineStartIndexes.integerLessThanOrEqualTo(index) ?? 0
    }
    
    
    /// Invalidate the line range cache.
    ///
    /// This method must be invoked every time when the receiver's `.string` is updated.
    ///
    /// - Parameters:
    ///   - newRange: The range in the final string that was edited.
    ///   - delta: The length delta for the editing changes.
    func invalidateLineRanges(in newRange: NSRange, changeInLength delta: Int) {
        
        self.lineRangeCache.invalidate(in: newRange, changeInLength: delta)
    }
    
    
    
    // MARK: Private Methods
    
    /// Calculate and cache line ranges up to the line that contains the given character index, if it has not already done so.
    ///
    /// - Parameter endIndex: The character index where needs the line number.
    private func ensureLineRanges(upTo endIndex: Int) {
        
        assert(endIndex <= self.string.length)
        
        guard endIndex >= self.lineRangeCache.firstUncountedIndex else { return }
        
        let string = self.string
        
        guard string.length > 0 else { return }
        
        let lowerParseBound = self.lineRangeCache.firstUncountedIndex
        let upperParseBound = self.lineRangeCache.parsedIndexes.contains(endIndex)
            ? self.lineRangeCache.parsedIndexes.rangeView(of: lowerParseBound...endIndex).last?.first ?? endIndex
            : endIndex
        
        var index = lowerParseBound
        while index <= min(upperParseBound, string.length - 1) {
            string.getLineStart(nil, end: &index, contentsEnd: nil, for: NSRange(location: index, length: 0))
            
            guard index != string.length || string.character(at: index - 1).isNewline else { break }
            
            self.lineRangeCache.lineStartIndexes.insert(index)
        }
        self.lineRangeCache.parsedIndexes.insert(integersIn: lowerParseBound..<index)
        self.lineRangeCache.invalidateFirstUncountedIndex()
    }
}


private extension LineRangeCache {
    
    /// Invalidate the cache.
    ///
    /// - Parameters:
    ///   - newRange: The range in the final string that was edited.
    ///   - delta: The length delta for the editing changes.
    mutating func invalidate(in newRange: NSRange, changeInLength delta: Int) {
        
        self.parsedIndexes.shift(startingAt: max(newRange.lowerBound - delta, 0), by: delta)
        self.parsedIndexes.remove(integersIn: newRange.lowerBound..<newRange.upperBound)
        
        self.lineStartIndexes.shift(startingAt: max(newRange.lowerBound + 1 - delta, 0), by: delta)
        self.lineStartIndexes.remove(integersIn: (newRange.lowerBound + 1)..<(newRange.upperBound + 1))
        
        self.invalidateFirstUncountedIndex()
    }
    
    
    /// Update the first uncounted index.
    mutating func invalidateFirstUncountedIndex() {
        
        let firstInvalidIndex = self.parsedIndexes.contains(0)
            ? self.parsedIndexes.rangeView.first?.last.flatMap { $0 + 1 } ?? 0
            : 0
        
        self.firstUncountedIndex = self.lineStartIndexes.integerLessThanOrEqualTo(firstInvalidIndex) ?? 0
    }
}
