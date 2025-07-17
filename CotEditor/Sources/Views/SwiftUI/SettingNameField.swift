//
//  SettingNameField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-06-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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

struct SettingNameField: View {
    
    var text: String
    var action: (String) -> Bool
    
    private var isDisabled: Bool = false
    
    @FocusState private var isFocused: Bool
    @State private var editingText: String
    
    
    init(text: String, action: @escaping (_ newName: String) -> Bool) {
        
        self.text = text
        self.action = action
        self.editingText = text
    }
    
    
    func editDisabled(_ editDisabled: Bool) -> some View {
        
        var view = self
        view.isDisabled = editDisabled
        return view
    }
    
    
    var body: some View {
        
        if self.isDisabled {
            Text(self.text)
        } else {
            TextField(text: $editingText, label: EmptyView.init)
                .focused($isFocused)
                .onChange(of: self.isFocused) { (_, isFocused) in
                    guard
                        !isFocused,
                        self.editingText != self.text
                    else { return }
                    
                    if self.editingText.isEmpty {
                        self.editingText = self.text
                        return
                    }
                    
                    guard self.action(self.editingText) else {
                        self.editingText = self.text
                        self.isFocused = true
                        return
                    }
                }
        }
    }
}
