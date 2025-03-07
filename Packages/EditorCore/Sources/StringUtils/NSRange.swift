//
//  NSRange.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-02-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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

extension NSRange: @retroactive Comparable {
    
    public static func < (lhs: _NSRange, rhs: _NSRange) -> Bool {
        
        lhs.location < rhs.location
    }
}


public extension NSRange {
    
    static let notFound = NSRange(location: NSNotFound, length: 0)
    
    
    /// A boolean value indicating whether the range contains no elements.
    var isEmpty: Bool {
        
        self.length == 0
    }
    
    
    /// A boolean value indicating whether the range is not found.
    var isNotFound: Bool {
        
        self.location == NSNotFound
    }
    
    
    /// Checks if the given index is in the receiver or touches to one of the receiver's bounds.
    ///
    /// - Parameter index: The index to test.
    func touches(_ index: Int) -> Bool {
        
        self.lowerBound <= index && index <= self.upperBound
    }
    
    
    /// Returns a boolean indicating whether the specified range intersects the receiver’s range.
    ///
    /// - Parameter other: The other range.
    func intersects(_ other: NSRange) -> Bool {
        
        self.intersection(other) != nil
    }
    
    
    /// Checks if the two ranges overlap or touch each other.
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
    
    
    /// Returns a copied NSRange but whose location is shifted toward the given `offset`.
    ///
    /// - Parameter offset: The offset to shift.
    /// - Returns: A new NSRange.
    func shifted(by offset: Int) -> NSRange {
        
        NSRange(location: self.location + offset, length: self.length)
    }
}


public extension NSRange {
    
    struct InsertionItem: Equatable, Sendable {
        
        public var string: String
        public var location: Int
        public var forward: Bool
        
        
        public init(string: String, location: Int, forward: Bool) {
            
            self.string = string
            self.location = location
            self.forward = forward
        }
    }
    
    
    /// Returns a new range by assuming the indices of the given items are inserted.
    ///
    /// - Parameter items: Insertion items to be inserted.
    /// - Returns: A new range that the receiver moved.
    func inserted(items: [Self.InsertionItem]) -> NSRange {
        
        let location = items
            .prefix { (self.isEmpty && $0.forward) ? $0.location <= self.lowerBound : $0.location < self.lowerBound }
            .map(\.string.length)
            .reduce(self.location, +)
        let length = items
            .filter { (self.isEmpty || !$0.forward) ? self.lowerBound < $0.location : self.lowerBound <= $0.location }
            .filter { (self.isEmpty || $0.forward) ? $0.location < self.upperBound : $0.location <= self.upperBound }
            .map(\.string.length)
            .reduce(self.length, +)
        
        return NSRange(location: location, length: length)
    }
    
    
    /// Returns a new range by assuming the indexes in the given ranges are removed.
    ///
    /// - Parameter ranges: An array of NSRange where the indexes are removed.
    /// - Returns: A new range that the receiver moved.
    func removed(ranges: [NSRange]) -> NSRange {
        
        let indices = IndexSet(integersIn: ranges)
        let location = self.location - indices.count(in: ..<self.lowerBound)
        let length = self.length - indices.count(in: Range(self)!)
        
        return NSRange(location: location, length: length)
    }
}


public extension IndexSet {
    
    /// Initializes an index set with multiple NSRanges.
    ///
    /// - Parameter ranges: The ranges to insert.
    init(integersIn ranges: [NSRange]) {
        
        assert(!ranges.contains(.notFound))
        
        self.init()
        
        for range in ranges.compactMap(Range.init) {
            self.insert(integersIn: range)
        }
    }
}
