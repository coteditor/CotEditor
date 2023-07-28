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
//  © 2022-2023 1024jp
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

final class FindPanelButtonViewController: NSHostingController<FindPanelButtonView> {
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder, rootView: FindPanelButtonView())
    }
}


struct FindPanelButtonView: View {
    
    @FirstResponder private var firstResponder
    
    
    // MARK: View
    
    var body: some View {
        
        HStack(alignment: .bottom) {
            Menu("Find All") {
                Button("Highlight All") {
                    self.performAction(.highlight)
                }
                Button("Select All") {
                    self.performAction(.selectAll)
                }
            } primaryAction: {
                self.performAction(.findAll)
            }
            .help("Find and list all matches up.")
            .fixedSize()
            
            Button("Replace All") {
                self.performAction(.replaceAll)
            }
            .help("Replace all matches with the replacement text.")
            .fixedSize()
            
            Spacer()
            
            Button("Replace") {
                self.performAction(.replaceAndFind)
            }
            .help("Replace the current selection with the replacement text, then find the next match.")
            .fixedSize()
            
            ControlGroup {
                Button {
                    self.performAction(.previousMatch)
                } label: {
                    Label("Find Previous", systemImage: "chevron.backward")
                }.help("Find previous match.")
                
                Button {
                    self.performAction(.nextMatch)
                } label: {
                    Label("Find Next", systemImage: "chevron.forward")
                }.help("Find next match.")
            }
            .labelStyle(.iconOnly)
            .frame(width: 70)
        }
        .responderChain(to: self.firstResponder)
        .padding(.top, 8)
        .padding(.horizontal, 20)
        .padding(.bottom)
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
