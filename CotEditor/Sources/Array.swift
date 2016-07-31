/*
 
 Array.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-27.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

// element
extension Array where Element: Equatable {
    
    /// Remove first collection element that is equal to the given `element`
    mutating func remove(_ element: Element) {
        
        if let index = index(of: element) {
            remove(at: index)
        }
    }
    
}


extension IndexableBase {

    /// Returns the element at the specified index only if it is within bounds, otherwise nil.
    public subscript(safe index: Index) -> _Element? {
        
        return index >= startIndex && index < endIndex
            ? self[index]
            : nil
    }
}



// IndexSet
extension Array {
    
    /// Remove elements with IndexSet
    mutating func remove(in indexes: IndexSet) {
        
        for index in indexes.reversed() {
            self.remove(at: index)
        }
    }
    
    
    /// Return subset at IndexSet
    func elements(at indexes: IndexSet) -> [Element] {
        
        return indexes.flatMap({ index in
            guard index < self.count else { return nil }
            return self[index]
        })
    }
    
}
