//
//  FindPanelButtonView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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

struct FindPanelButtonView: View {
    
    @FirstResponder private var firstResponder
    
    
    // MARK: View
    
    var body: some View {
        
        HStack(alignment: .bottom) {
            Menu(String(localized: "Find All", table: "TextFind", comment: "button label")) {
                Button(String(localized: "Highlight All", table: "TextFind", comment: "button label")) {
                    self.performAction(.highlight)
                }
                Button(String(localized: "Select All", table: "TextFind", comment: "button label")) {
                    self.performAction(.selectAll)
                }
            } primaryAction: {
                self.performAction(.findAll)
            }
            .help(String(localized: "Find and list all matches.", table: "TextFind", comment: "tooltip"))
            .fixedSize()
            
            Button(String(localized: "Replace All", table: "TextFind", comment: "button label")) {
                self.performAction(.replaceAll)
            }
            .help(String(localized: "Replace all matches with the replacement text.", table: "TextFind", comment: "tooltip"))
            .fixedSize()
            
            Spacer()
            
            Button(String(localized: "Replace", table: "TextFind", comment: "button label")) {
                self.performAction(.replaceAndFind)
            }
            .help(String(localized: "Replace the current selection with the replacement text, then find the next match.", table: "TextFind", comment: "tooltip"))
            .fixedSize()
            
            ControlGroup {
                Button {
                    self.performAction(.previousMatch)
                } label: {
                    Label(String(localized: "Find Previous", table: "TextFind", comment: "button label"),
                          systemImage: "chevron.backward")
                }.help(String(localized: "Find previous match.", table: "TextFind", comment: "tooltip"))
                
                Button {
                    self.performAction(.nextMatch)
                } label: {
                    Label(String(localized: "Find Next", table: "TextFind", comment: "button label"),
                          systemImage: "chevron.forward")
                }.help(String(localized: "Find next match.", table: "TextFind", comment: "tooltip"))
            }
            .labelStyle(.iconOnly)
            .frame(width: 70)
        }
        .responderChain(to: self.firstResponder)
        .padding(.top, 8)
        .scenePadding([.horizontal, .bottom])
    }
    
    
    // MARK: Private Methods
    
    @MainActor private func performAction(_ action: TextFinder.Action) {
        
        self.firstResponder.performAction(#selector((any TextFinderClient).performEditorTextFinderAction), tag: action.rawValue)
    }
}



// MARK: - Preview

#Preview {
    FindPanelButtonView()
}
