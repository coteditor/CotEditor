//
//  Collection+ValueRange.swift
//  LineEnding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2026 1024jp
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

public import Foundation
public import ValueRange

public extension RangeReplaceableCollection {
    
    /// Replace the elements in the specified range with the given items.
    ///
    /// This API assumes the elements are sorted by range location.
    ///
    /// - Parameters:
    ///   - items: The items to replace with.
    ///   - editedRange: The edited range.
    ///   - delta: The change in length.
    mutating func replace<Value>(items: [Element], in editedRange: NSRange, changeInLength delta: Int = 0) where Element == ValueRange<Value> {
        
        guard let lowerEditedIndex = self.binarySearchedFirstIndex(where: { $0.lowerBound >= editedRange.lowerBound }) else {
            self += items
            return
        }
        
        if let upperEditedIndex = self.binarySearchedFirstIndex(in: lowerEditedIndex..<self.endIndex, where: { $0.lowerBound >= editedRange.upperBound - delta }) {
            let shiftedElements = self[upperEditedIndex...].map { $0.shifted(by: delta) }
            self.replaceSubrange(lowerEditedIndex..., with: shiftedElements)
        } else {
            self.removeSubrange(lowerEditedIndex...)
        }
        
        self.insert(contentsOf: items, at: lowerEditedIndex)
    }
    
    
    /// Returns whether the collection contains an element whose range starts at `location`.
    ///
    /// This API assumes the elements are sorted by range location.
    ///
    /// - Parameter location: The start location to look up.
    /// - Returns: `true` if an element starts at `location`; otherwise `false`.
    func contains<Value>(rangeStartingAt location: Int) -> Bool where Element == ValueRange<Value> {
        
        guard let index = self.binarySearchedFirstIndex(where: { $0.lowerBound >= location }) else { return false }
        
        return self[index].lowerBound == location
    }
}


public extension Sequence {
    
    /// Returns the Value mostly occurred in the collection.
    func majorValue<Value: Hashable>() -> Value? where Element == ValueRange<Value> {
        
        Dictionary(grouping: self, by: \.value)
            .sorted(using: KeyPathComparator(\.value.first?.lowerBound))
            .max { $0.value.count < $1.value.count }?
            .key
    }
}
