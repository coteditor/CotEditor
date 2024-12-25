//
//  Identifiable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-12.
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

extension Sequence where Element: Identifiable {
    
    subscript(id id: Element.ID?) -> Element? {
        
        self.first { $0.id == id }
    }
    
    
    /// Returns an array containing, in order, the elements with the given ids.
    ///
    /// - Parameter ids: The identifiers of the elements to include.
    /// - Returns: An array of the elements.
    func filter(with ids: Set<Element.ID>) -> [Element] {
        
        self.filter { ids.contains($0.id) }
    }
}


extension MutableCollection where Self: RangeReplaceableCollection, Element: Identifiable {
    
    subscript(id id: Element.ID?) -> Element? {
        
        get {
            self.first { $0.id == id }
        }
        
        set {
            guard let index = self.firstIndex(where: { $0.id == id }) else { return }
            
            if let newValue {
                self[index] = newValue
            } else {
                self.remove(at: index)
            }
        }
    }
}
