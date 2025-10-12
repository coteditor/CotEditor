//
//  AddRemoveButton.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-08-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2025 1024jp
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

struct AddRemoveButton<Item: Identifiable>: View {
    
    @Binding private var items: [Item]
    @Binding private var selection: Set<Item.ID>
    private var newItem: () -> Item
    private var completion: @MainActor (Item) -> Void
    
    
    /// Creates a segmented add/remove control.
    ///
    /// - Parameters:
    ///   - items: The collection of identifiable data where adding/removing items.
    ///   - selection: A binding to a set that identifies selected items' IDs.
    ///   - newItem: A closure to return an item for when adding a new item from the button.
    ///   - completion: A closure to perform after an item is added.
    init(_ items: Binding<[Item]>, selection: Binding<Set<Item.ID>>, newItem: @autoclosure @escaping () -> Item, completion: @escaping @MainActor (Item) -> Void = { _ in }) {
        
        self._items = items
        self._selection = selection
        self.newItem = newItem
        self.completion = completion
    }
    
    
    var body: some View {
        
        ControlGroup {
            Button(String(localized: "Action.add.label", defaultValue: "Add"), systemImage: "plus") {
                let item = self.newItem()
                let index = self.items.lastIndex { self.selection.contains($0.id) } ?? self.items.endIndex - 1
                
                withAnimation {
                    self.items.insert(item, at: index + 1)
                    self.selection = [item.id]
                } completion: {
                    self.completion(item)
                }
            }
            .help(String(localized: "Action.add.tooltip", defaultValue: "Add new item"))
            
            Button(String(localized: "Action.delete.label", defaultValue: "Delete"), systemImage: "minus") {
                withAnimation {
                    self.items.removeAll {
                        self.selection.contains($0.id)
                    }
                    self.selection.removeAll()
                }
            }
            .help(String(localized: "Action.delete.tooltip", defaultValue: "Delete selected items"))
            .disabled(self.selection.isEmpty)
        }
        .modifier { content in
            if #available(macOS 26, *) {
                content
                    .buttonSizing(.flexible)
            } else {
                content
            }
        }
        .frame(width: 52)
    }
}
