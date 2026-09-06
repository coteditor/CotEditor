//
//  Binding.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-09-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2026 1024jp
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

import SwiftUI

// MARK: OptionSet

extension Binding where Value: OptionSet & Sendable, Value == Value.Element {
    
    /// Enables binding to an option using Bool.
    ///
    /// - Parameter options: The option to bind.
    /// - Returns: A `Binding<Bool>` struct.
    func bind(_ options: Value) -> Binding<Bool> {
        
        .init(
            get: {
                self.wrappedValue.contains(options)
            },
            set: { newValue in
                if newValue {
                    self.wrappedValue.insert(options)
                } else {
                    self.wrappedValue.remove(options)
                }
            }
        )
    }
}


// MARK: Set

extension Binding {
    
    /// Returns a binding that indicates whether the set contains the given element.
    ///
    /// - Parameter element: The element to check.
    /// - Returns: A binding that inserts the element when set to `true`, or removes it when set to `false`.
    func contains<Element: Sendable>(_ element: Element) -> Binding<Bool> where Value == Set<Element> {
        
        Binding<Bool>(
            get: {
                self.wrappedValue.contains(element)
            },
            set: {
                if $0 {
                    self.wrappedValue.insert(element)
                } else {
                    self.wrappedValue.remove(element)
                }
            }
        )
    }
}


// MARK: Selection

extension Binding {
    
    /// Returns a Boolean binding that applies edits to the selected items when the given item is selected.
    ///
    /// - Parameters:
    ///   - item: The item whose value is displayed.
    ///   - selection: The selected item IDs.
    ///   - keyPath: The Boolean property to edit.
    /// - Returns: A binding that updates the selected items, or only the given item if it is not selected.
    func selectionBinding<Element: Identifiable & Sendable>(for item: Binding<Element>, selection: Binding<Set<Element.ID>>, keyPath: any WritableKeyPath<Element, Bool> & Sendable) -> Binding<Bool> where Value == [Element], Element.ID: Sendable {
        
        Binding<Bool>(
            get: { item.wrappedValue[keyPath: keyPath] },
            set: { newValue, transaction in
                let id = item.wrappedValue.id
                let selection = selection.wrappedValue
                let ids: Set<Element.ID> = selection.contains(id) ? selection : [id]
                var items = self.wrappedValue
                for index in items.indices where ids.contains(items[index].id) {
                    items[index][keyPath: keyPath] = newValue
                }
                self.transaction(transaction).wrappedValue = items
            }
        )
    }
}


// MARK: Optional Binding

func ?? <T: Sendable>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}


func ?? (lhs: Binding<String?>, rhs: String) -> Binding<String> {
    
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0.isEmpty ? nil : $0 }
    )
}


func ?? <T: Sendable>(lhs: Binding<[T]?>, rhs: [T]) -> Binding<[T]> {
    
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0.isEmpty ? nil : $0 }
    )
}
