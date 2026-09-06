//
//  BindingTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-09-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import Testing
@testable import CotEditor

@MainActor struct BindingTests {
    
    private struct Item: Identifiable, Equatable {
        
        let id: Int
        var isOn: Bool
        var text: String = "unchanged"
    }
    
    
    /// Tests that a toggle edits the appropriate rows with a single collection write.
    @Test(arguments: [Set([0, 1]), Set([1, 2]), Set<Int>()], [false, true])
    func selectionBinding(selection: Set<Int>, newValue: Bool) {
        
        var items = [Item(id: 0, isOn: !newValue), Item(id: 1, isOn: newValue), Item(id: 2, isOn: !newValue)]
        var writeCount = 0
        let binding = Binding(
            get: { items },
            set: {
                items = $0
                writeCount += 1
            }
        )
        let toggle = binding.selectionBinding(for: binding[0], selection: .constant(selection), keyPath: \.isOn)
        
        #expect(toggle.wrappedValue == !newValue)
        toggle.wrappedValue = newValue
        
        #expect(items == [Item(id: 0, isOn: newValue), Item(id: 1, isOn: newValue), Item(id: 2, isOn: !newValue)])
        #expect(toggle.wrappedValue == newValue)
        #expect(writeCount == 1)
    }
    
    
    /// Tests that multiple selected rows are changed with a single collection write.
    @Test(arguments: [false, true])
    func selectedRows(newValue: Bool) {
        
        var items = [Item(id: 0, isOn: !newValue), Item(id: 1, isOn: !newValue), Item(id: 2, isOn: newValue)]
        var writeCount = 0
        let binding = Binding(
            get: { items },
            set: {
                items = $0
                writeCount += 1
            }
        )
        let toggle = binding.selectionBinding(for: binding[0], selection: .constant([0, 1]), keyPath: \.isOn)
        
        toggle.wrappedValue = newValue
        
        #expect(items == [Item(id: 0, isOn: newValue), Item(id: 1, isOn: newValue), Item(id: 2, isOn: newValue)])
        #expect(writeCount == 1)
    }
    
    
    /// Tests that the setter reads the latest selection and preserves intervening edits.
    @Test func updatedSelection() {
        
        var items = [Item(id: 0, isOn: false), Item(id: 1, isOn: false), Item(id: 2, isOn: false)]
        var selection: Set<Int> = [0, 1]
        let binding = Binding(get: { items }, set: { items = $0 })
        let selectionBinding = Binding(get: { selection }, set: { selection = $0 })
        let toggle = binding.selectionBinding(for: binding[0], selection: selectionBinding, keyPath: \.isOn)
        
        selection = [0, 2]
        items[2].text = "edited"
        toggle.wrappedValue = true
        
        #expect(items == [Item(id: 0, isOn: true), Item(id: 1, isOn: false), Item(id: 2, isOn: true, text: "edited")])
        #expect(selection == [0, 2])
    }
}
