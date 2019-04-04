//
//  Collection.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2019 1024jp
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

extension RangeReplaceableCollection where Element: Equatable {
    
    /// Remove first collection element that is equal to the given `element`.
    ///
    /// - Parameter element: The element to be removed.
    mutating func remove(_ element: Element) {
        
        if let index = self.firstIndex(of: element) {
            self.remove(at: index)
        }
    }
    
}



extension Collection {

    /// Return the element at the specified index only if it is within bounds, otherwise nil.
    ///
    /// - Parameter index: The position of the element to obtain.
    subscript(safe index: Index) -> Element? {
        
        return self.indices.contains(index) ? self[index] : nil
    }
    
}



extension Sequence where Element: Equatable {
    
    /// An array consists of unique elements of receiver keeping ordering.
    var unique: [Element] {
        
        return self.reduce(into: []) { (unique, element) in
            guard !unique.contains(element) else { return }
            
            unique.append(element)
        }
    }
    
}



extension Dictionary {
    
    /// Return a new dictionary containing the keys transformed by the given closure with the values of this dictionary.
    ///
    /// - Parameter transform: A closure that transforms a key. Every transformed key must be unique.
    /// - Returns: A dictionary containing transformed keys and the values of this dictionary.
    func mapKeys<T>(transform: (Key) throws -> T) rethrows -> [T: Value] {
        
        let keysWithValues = try self.map { (key, value) -> (T, Value) in
             (try transform(key), value)
        }
        
        return [T: Value](uniqueKeysWithValues: keysWithValues)
    }
    
}



// MARK: - Count

extension Sequence {
    
    /// Count up elements that satisfy the given predicate.
    ///
    /// - Parameters:
    ///    - predicate: A closure that takes an element of the sequence as its argument
    ///                 and returns a Boolean value indicating whether the element should be counted.
    /// - Returns: The number of elements that satisfies the given predicate.
    func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        
        return try self.reduce(0) { try predicate($1) ? $0 + 1 : $0 }
    }
    
    
    /// Count up elements by enumerating collection until a element shows up that doesn't satisfy the given predicate.
    ///
    /// - Parameters:
    ///    - predicate: A closure that takes an element of the sequence as its argument
    ///                 and returns a Boolean value indicating whether the element should be counted.
    /// - Returns: The number of elements that satisfies the given predicate and are sequentially from the first index.
    func countPrefix(while predicate: (Element) throws -> Bool) rethrows -> Int {
        
        return try self.prefix(while: predicate).count
    }
    
}
