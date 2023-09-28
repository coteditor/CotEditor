//
//  FindPanelOptionView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-09-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

struct FindPanelOptionView: View {
    
    @AppStorage(.findUsesRegularExpression) private var usesRegularExpression: Bool
    @AppStorage(.findIgnoresCase) private var ignoresCase: Bool
    @AppStorage(.findInSelection) private var inSelection: Bool
    
    @State private var isRegexReferencePresented = false
    @State private var isSettingsPresented = false
    
    
    
    // MARK: View
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Toggle("Regular Expression", isOn: $usesRegularExpression)
                    .help("Select to search with regular expression.")
                    .fixedSize()
                HelpButton {
                    self.isRegexReferencePresented.toggle()
                }
                .help("Show quick reference for regular expression syntax.")
                .detachablePopover(isPresented: $isRegexReferencePresented, arrowEdge: .bottom) {
                    RegularExpressionReferenceView()
                }
                .controlSize(.mini)
            }
            Toggle("Ignore Case", isOn: $ignoresCase)
                .help("Select to ignore character case on search.")
                .fixedSize()
            Toggle("In Selection", isOn: $inSelection)
                .help("Select to search text only from selection.")
                .fixedSize()
            
            Spacer()
            
            Button {
                self.isSettingsPresented.toggle()
            } label: {
                Image(systemName: "ellipsis").symbolVariant(.circle)
            }
            .popover(isPresented: $isSettingsPresented, arrowEdge: .trailing) {
                FindSettingsView()
            }
            .accessibilityLabel("Advanced options")
            .help("Show advanced options")
        }
        .controlSize(.small)
    }
}



// MARK: - Preview

#Preview {
    FindPanelOptionView()
        .padding()
}
