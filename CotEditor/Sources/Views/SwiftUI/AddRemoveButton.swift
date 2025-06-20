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
    
    private var focus: FocusState<Item.ID?>.Binding?
    @State private var added: Item.ID?
    
    private var newItem: () -> Item
    
    
    /// Creates a segmented add/remove control.
    ///
    /// - Parameters:
    ///   - items: The identifiable data array where adding/removing items.
    ///   - selection: A binding to a set that identifies selected items IDs.
    ///   - focus: A binding to the focus state in the window.
    ///   - newItem: A closure to return an item for when adding a new item from the button.
    init(_ items: Binding<[Item]>, selection: Binding<Set<Item.ID>>, focus: FocusState<Item.ID?>.Binding? = nil, newItem: @escaping () -> Item) {
        
        self._items = items
        self._selection = selection
        self.focus = focus
        self.newItem = newItem
    }
    
    
    var body: some View {
        
        ControlGroup {
            Button(String(localized: "Button.add.label", defaultValue: "Add", table: "Control"), systemImage: "plus") {
                let item = self.newItem()
                let index = self.items.lastIndex { self.selection.contains($0.id) } ?? self.items.endIndex - 1
                
                self.selection.removeAll()
                self.added = item.id
                
                withAnimation {
                    self.items.insert(item, at: index + 1)
                    self.selection = [item.id]
                }
            }
            .onChange(of: self.added) { (_, newValue) in
                self.focus?.wrappedValue = newValue
            }
            .help(String(localized: "Button.add.tooltip", defaultValue: "Add new item", table: "Control"))
            
            Button(String(localized: "Button.remove.label", defaultValue: "Remove", table: "Control"), systemImage: "minus") {
                withAnimation {
                    self.items.removeAll {
                        self.selection.contains($0.id)
                    }
                    self.selection.removeAll()
                }
            }
            .help(String(localized: "Button.remove.tooltip", defaultValue: "Remove selected items", table: "Control"))
            .disabled(self.selection.isEmpty)
        }
        .frame(width: 52)
    }
}
