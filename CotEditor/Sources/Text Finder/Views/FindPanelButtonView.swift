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
//  © 2022-2026 1024jp
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
    
    var body: some View {
        
        HStack(alignment: .bottom) {
            Menu(.init("Find All", table: "TextFind", comment: "button label")) {
                Button(.init("Highlight All", table: "TextFind", comment: "button label"), systemImage: "highlighter") {
                    self.performAction(.highlight)
                }
                Button(.init("Select All", table: "TextFind", comment: "button label"), systemImage: "character.textbox") {
                    self.performAction(.selectAll)
                }
            } primaryAction: {
                self.performAction(.findAll)
            }
            .help(.init("Find and list all matches.", table: "TextFind", comment: "tooltip"))
            
            Button(.init("Replace All", table: "TextFind", comment: "button label")) {
                self.performAction(.replaceAll)
            }
            .help(.init("Replace all matches with the replacement text.", table: "TextFind", comment: "tooltip"))
            
            Spacer()
            
            Button(.init("Replace", table: "TextFind", comment: "button label")) {
                self.performAction(.replaceAndFind)
            }
            .help(.init("Replace the current selection with the replacement text, then find the next match.", table: "TextFind", comment: "tooltip"))
            
            ControlGroup {
                Button(.init("Find Previous", table: "TextFind", comment: "button label"), systemImage: "chevron.backward") {
                    self.performAction(.previousMatch)
                }.help(.init("Find previous match.", table: "TextFind", comment: "tooltip"))
                
                Button(.init("Find Next", table: "TextFind", comment: "button label"), systemImage: "chevron.forward") {
                    self.performAction(.nextMatch)
                }.help(.init("Find next match.", table: "TextFind", comment: "tooltip"))
            }
            .labelStyle(.iconOnly)
            .buttonSizing(.flexible)
            .frame(width: 70)
        }
        .padding(.top, 8)
        .scenePadding([.horizontal, .bottom])
    }
    
    
    // MARK: Private Methods
    
    /// Send a text finder action message to the legacy responder-chain.
    ///
    /// - Parameter action: The `TextFinder.Action` to perform.
    private func performAction(_ action: TextFinder.Action) {
        
        // create a dummy sender for tag
        let sender = NSControl()
        sender.tag = action.rawValue
        
        NSApp.sendAction(#selector((any TextFinderClient).performEditorTextFinderAction), to: nil, from: sender)
    }
}


// MARK: - Preview

#Preview {
    FindPanelButtonView()
}
