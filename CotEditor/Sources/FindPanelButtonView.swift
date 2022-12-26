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
//  © 2022 1024jp
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

final class FindPanelButtonViewHostingController: NSHostingController<FindPanelButtonView> {
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder, rootView: FindPanelButtonView())
    }
}


struct FindPanelButtonView: View {
    
    private let textFinder: TextFinder = .shared
    
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline) {
            if #available(macOS 13, *) {
                Menu("Find All") {
                    Button("Highlight All") {
                        self.textFinder.highlight(nil)
                    }
                    Button("Select All") {
                        self.textFinder.selectAllMatches(nil)
                    }
                } primaryAction: {
                    self.textFinder.findAll(nil)
                }
                .help("List all matches.")
                .fixedSize()
            } else {
                Button("Find All") {
                    self.textFinder.findAll(nil)
                }.help("List all matches.")
            }
            
            Button("Replace All") {
                self.textFinder.replaceAll(nil)
            }.help("Replace all matches with the replacement text.")
            
            Spacer()
            
            Button("Replace") {
                self.textFinder.replace(nil)
            }.help("Replace the current selection with the replacement text, then find the next match.")
            
            ControlGroup {
                Button {
                    self.textFinder.findPrevious(nil)
                } label: {
                    Label("Find Previous", systemImage: "chevron.backward")
                }.help("Find previous match.")
                
                Button {
                    self.textFinder.findNext(nil)
                } label: {
                    Label("Find Next", systemImage: "chevron.forward")
                }.help("Find next match.")
            }
            .labelStyle(.iconOnly)
            .frame(width: 70)
        }
        .padding(.top, 8)
        .padding(.horizontal, 20)
        .padding(.bottom)
    }
}



// MARK: - Preview

struct FindPanelButtonView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        FindPanelButtonView()
    }
}
