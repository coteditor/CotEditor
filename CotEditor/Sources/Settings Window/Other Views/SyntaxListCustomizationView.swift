//
//  SyntaxListCustomizationView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-15.
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
import Defaults

struct SyntaxListCustomizationView: View {
    
    var items: [String]
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var hiddenItems: Set<String> = []
    @State private var selection: Set<String> = []
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Select the syntaxes you want to appear in syntax menus:", tableName: "SyntaxListCustomization")
                .fixedSize(horizontal: false, vertical: true)
            
            List(self.items, id: \.self, selection: $selection) { item in
                Toggle(item, isOn: $hiddenItems.notContains(item))
                    .onChange(of: self.hiddenItems.contains(item)) { _, newValue in
                        guard self.selection.contains(item) else { return }
                        if newValue {
                            self.hiddenItems.formUnion(self.selection)
                        } else {
                            self.hiddenItems.subtract(self.selection)
                        }
                    }
                    .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .background(.fill.quaternary, in: .rect(cornerRadius: 8))
            .frame(minHeight: 200, idealHeight: 250)
            
            HStack {
                Button(String(localized: "Select All", table: "SyntaxListCustomization")) {
                    self.hiddenItems.removeAll()
                }
                .disabled(self.hiddenItems.isEmpty)
                .fixedSize()
                Spacer()
            }
            
            Text("Hidden syntaxes are still used for automatic detection.", tableName: "SyntaxListCustomization")
                .controlSize(.small)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)
            
            HStack {
                HelpLink(anchor: "howto_customize_syntax_menu")
                
                Spacer()
                
                SubmitButtonGroup {
                    UserDefaults.standard[.hiddenSyntaxes] = self.hiddenItems.sorted()
                    self.dismiss()
                } cancelAction: {
                    self.dismiss()
                }
            }
        }
        .onAppear {
            self.hiddenItems = Set(UserDefaults.standard[.hiddenSyntaxes])
        }
        .scenePadding()
        .frame(minWidth: 300, idealWidth: 400, maxWidth: 1000, idealHeight: 450, maxHeight: .infinity)
        .presentationSizing(.fitted)
    }
}


private extension Binding where Value == Set<String> {
    
    /// Returns a binding that indicates whether the set does not contain the given element.
    ///
    /// - Parameter element: The element to check.
    /// - Returns: A binding that removes the element when set to `true`, or inserts it when set to `false`.
    func notContains(_ element: String) -> Binding<Bool> {
        
        Binding<Bool>(
            get: { !self.contains(element).wrappedValue },
            set: { self.contains(element).wrappedValue = !$0 }
        )
    }
}


// MARK: Preview -

#Preview {
    SyntaxListCustomizationView(items: ["HTML", "Swift", "Neko"])
}
