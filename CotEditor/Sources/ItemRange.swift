//
//  ItemRange.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

import struct Foundation.NSRange

struct ItemRange<Item> {
    
    var item: Item
    var range: NSRange
    
    var location: Int  { self.range.location }
    
    
    /// Return a copy by shifting the range location toward the given offset .
    ///
    /// - Parameter offset: The offset to shift.
    /// - Returns: A new ItemRange.
    func shifted(by offset: Int) -> Self {
        
        Self(item: self.item, range: self.range.shifted(by: offset))
    }
    
    
    /// Shift the range location toward the given offset .
    ///
    /// - Parameter offset: The offset to shift.
    mutating func shift(by offset: Int) {
        
        self.range.location += offset
    }
    
}


extension ItemRange: Equatable where Item: Equatable { }
extension ItemRange: Hashable where Item: Hashable { }
