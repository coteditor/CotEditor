//
//  OrderedCounter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-02-22.
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

struct OrderedCounter<Element: Hashable> {
    
    private var elements: [Element] = []
    private var counter: [Element: Int] = [:]
    
    
    init() { }
    
    
    init<S: Sequence>(_ elements: S) where S.Element == Element {
        
        self.append(contentsOf: elements)
    }
    
    
    /// A Boolean value indicating whether the collection is empty.
    var isEmpty: Bool {
        
        self.elements.isEmpty
    }
    
    
    /// The number of elements in the counter.
    var count: Int {
        
        self.elements.count
    }
    
    
    /// The set of elements.
    var set: Set<Element> {
        
        Set(self.counter.keys)
    }
    
    
    /// The most occurred element.
    ///
    /// When the multiple elements with the same count exisits, return the element added earlier.
    var firstMaxElement: Element? {
        
        guard let maxCount = self.counter.values.max() else { return nil }
        
        let maxElements = self.counter.filter { $0.value == maxCount }.keys
        
        return self.elements.first { maxElements.contains($0) }
    }
    
    
    /// Add a new element at the end of the counter.
    ///
    /// - Parameter element: The element to append.
    mutating func append(_ element: Element) {
        
        self.elements.append(element)
        self.counter[element, default: 0] += 1
    }
    
    
    /// Add new elements at the end of the counter.
    ///
    /// - Parameter elements: The elements to append.
    mutating func append<S: Sequence>(contentsOf elements: S) where S.Element == Element {
        
        for element in elements {
            self.append(element)
        }
    }
    
    
    /// Count the number of the given element.
    ///
    /// - Parameter element: The element to count.
    /// - Returns: The number of the given element.
    func count(_ element: Element) -> Int {
        
        self.counter[element] ?? 0
    }
    
}
