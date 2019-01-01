//
//  Array+IndexSet.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2018 1024jp
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

extension Array {
    
    /// Remove elements with IndexSet
    mutating func remove(in indexes: IndexSet) {
        
        for index in indexes.reversed() {
            self.remove(at: index)
        }
    }
    
    
    /// Return subset at IndexSet
    func elements(at indexes: IndexSet) -> [Element] {
        
        return indexes
            .filter { $0 < self.count }
            .map { self[$0] }
    }
    
    
    /// Insert elements at indexes
    mutating func insert(_ elements: [Element], at indexes: IndexSet) {
        
        for (index, element) in zip(indexes, elements).reversed() {
            self.insert(element, at: index)
        }
    }
    
}
