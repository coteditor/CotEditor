//
//  Collection+IndexSet.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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

import struct Foundation.IndexSet

extension RangeReplaceableCollection where Index == Int {
    
    /// Removes elements with IndexSet.
    ///
    /// - Parameter indexes: The indexes of the elements to remove.
    mutating func remove(in indexes: IndexSet) {
        
        for index in indexes.reversed() {
            self.remove(at: index)
        }
    }
    
    
    /// Returns subset at IndexSet.
    ///
    /// - Parameter indexes: The indexes of the elements to return.
    /// - Returns: The elements at `indexes`.
    func elements(at indexes: IndexSet) -> [Element] {
        
        assert((indexes.max() ?? .max) <= self.endIndex)
        
        return indexes
            .filter { $0 < self.endIndex }
            .map { self[$0] }
    }
    
    
    /// Inserts elements at indexes.
    ///
    /// - Parameters:
    ///   - elements: The elements to insert.
    ///   - indexes: The indexes to insert at.
    mutating func insert(_ elements: [Element], at indexes: IndexSet) {
        
        assert(elements.count == indexes.count)
        
        for (index, element) in zip(indexes, elements) {
            self.insert(element, at: index)
        }
    }
}
