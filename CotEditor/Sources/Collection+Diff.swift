//
//  Collection+Diff.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-08-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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
import Differ

extension String {
    
    /// calculate equivalent ranges in the receiver to the given ranges in the given string using Differ.
    ///
    /// - Parameters:
    ///   - ranges: The original ranges to be based on.
    ///   - string: The string to compare with the receiver.
    /// - Returns: The equivalent ranges to the given ranges.
    func equivalentRanges(to nsRanges: [NSRange], in other: String) -> [NSRange] {
        
        let ranges = nsRanges.map { Range($0, in: other)! }
        
        return self.equivalentRanges(to: ranges, in: other)
            .map { NSRange($0, in: self) }
    }
    
}



extension Collection where Element: Equatable {
    
    /// calculate equivalent ranges in the receiver to the given ranges in the given collection using Differ.
    ///
    /// - Parameters:
    ///   - ranges: The original ranges to be based on.
    ///   - other: The collection to compare with the receiver.
    /// - Returns: The equivalent ranges to the given ranges.
    func equivalentRanges(to ranges: [Range<Index>], in other: Self) -> [Range<Index>] {
        
        return other.diff(self)
            .map { element -> (offset: Int, diff: Int) in
                switch element {
                case .insert(at: let offset): return (offset, 1)
                case .delete(at: let offset): return (offset, -1)
                }
            }
            .reduce(into: ranges) { (ranges, item) in
                let index = other.index(other.startIndex, offsetBy: item.offset)
                
                if let rangeIndex = ranges.index(where: { $0.lowerBound > index })  {
                    ranges[rangeIndex].shift(offset: item.diff, in: self)
                    
                } else if let rangeIndex = ranges.index(where: { $0.contains(index) }) {
                    ranges[rangeIndex].adjustLength(offset: item.diff, in: self)
                }
            }
    }
    
}



// MARK: -

private extension Range {
    
    mutating func shift<C>(offset: Int, in collection: C) where Bound == C.Index, C: Collection {
        
        let lowerBound = collection.index(self.lowerBound, offsetBy: offset)
        let upperBound = collection.index(self.upperBound, offsetBy: offset)
        
        self = lowerBound..<upperBound
    }
    
    
    mutating func adjustLength<C>(offset: Int, in collection: C) where Bound == C.Index, C: Collection {
        
        let upperBound = collection.index(self.upperBound, offsetBy: offset)
        
        self = self.lowerBound..<upperBound
    }
    
}
