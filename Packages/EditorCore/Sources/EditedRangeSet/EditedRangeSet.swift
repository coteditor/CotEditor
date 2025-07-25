//
//  EditedRangeSet.swift
//  EditedRangeSet
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-02-13.
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
import StringUtils

/// Edited range storage to postpone validations.
///
/// This is similar to the IndexSet but preserving zero-width edited ranges.
public struct EditedRangeSet: Sendable {
    
    public private(set) var ranges: [NSRange] = []
    
    
    public init(range: NSRange? = nil) {
        
        if let range {
            self.ranges = [range]
        }
    }
    
    
    /// The range that contains all ranges.
    public var range: NSRange? {
        
        self.ranges.union
    }
    
    
    /// Clears all stored ranges.
    public mutating func clear() {
        
        self.ranges.removeAll()
    }
    
    
    /// Clear the current ranges and replaces with the given range.
    ///
    /// - Parameter editedRange: The new range.
    public mutating func update(editedRange: NSRange) {
        
        self.clear()
        self.ranges = [editedRange]
    }
    
    
    /// Updates edit ranges by assuming the string was edited in an NSTextStorage and the storage returns the given `editedRange` and `changeInLength`.
    ///
    /// - Parameters:
    ///   - editedRange: The current remained range where edited.
    ///   - changeInLength: The difference between the current length of the edited range and its length before editing.
    public mutating func append(editedRange: NSRange, changeInLength: Int) {
        
        assert(editedRange.location != NSNotFound)
        
        let effectRange = NSRange(location: editedRange.location, length: editedRange.length - changeInLength)
        
        var added = false
        self.ranges = self.ranges.reduce(into: []) { ranges, range in
            if range.upperBound < editedRange.lowerBound {
                ranges.append(range)
                
            } else if effectRange.touches(range) {
                let union = range.union(effectRange)
                let modifiedRange = NSRange(location: union.location, length: union.length + changeInLength)
                
                if added, let last = ranges.last, last.touches(modifiedRange) {
                    ranges[ranges.endIndex - 1].formUnion(modifiedRange)
                } else {
                    ranges.append(modifiedRange)
                    added = true
                }
                
            } else {
                ranges.append(range.shifted(by: changeInLength))
            }
        }
        
        if !added {
            let index = self.ranges.firstIndex { editedRange.location < $0.location } ?? self.ranges.endIndex
            
            self.ranges.insert(editedRange, at: index)
        }
    }
}
