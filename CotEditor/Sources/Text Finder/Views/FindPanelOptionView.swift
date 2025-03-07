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
//  © 2023-2024 1024jp
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

struct FindPanelOptionView: View {
    
    @AppStorage(.findUsesRegularExpression) private var usesRegularExpression: Bool
    @AppStorage(.findIgnoresCase) private var ignoresCase: Bool
    @AppStorage(.findInSelection) private var inSelection: Bool
    
    @State private var isRegexReferencePresented = false
    @State private var isSettingsPresented = false
    
    
    // MARK: View
    
    var body: some View {
        
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Toggle(String(localized: "Regular Expression", table: "TextFind", comment: "toggle button label"), isOn: $usesRegularExpression)
                    .help(String(localized: "Select to search with regular expression.", table: "TextFind", comment: "tooltip"))
                    .fixedSize()
                HelpLink {
                    self.isRegexReferencePresented.toggle()
                }
                .help(String(localized: "Show quick reference for regular expression syntax.", table: "TextFind", comment: "tooltip"))
                .detachablePopover(isPresented: $isRegexReferencePresented, arrowEdge: .bottom) {
                    RegularExpressionReferenceView()
                }
                .controlSize(.mini)
            }
            Toggle(String(localized: "Ignore Case", table: "TextFind", comment: "toggle button label"), isOn: $ignoresCase)
                .help(String(localized: "Select to ignore character case on search.", table: "TextFind", comment: "tooltip"))
                .fixedSize()
            Toggle(String(localized: "In Selection", table: "TextFind", comment: "toggle button label"), isOn: $inSelection)
                .help(String(localized: "Select to search text only from selection.", table: "TextFind", comment: "tooltip"))
                .fixedSize()
            
            Spacer()
            
            Button(String(localized: "Advanced options", table: "TextFind", comment: "accessibility label"), systemImage: "ellipsis") {
                self.isSettingsPresented.toggle()
            }
            .popover(isPresented: $isSettingsPresented, arrowEdge: .trailing) {
                FindSettingsView()
            }
            .symbolVariant(.circle)
            .labelStyle(.iconOnly)
            .help(String(localized: "Show advanced options", table: "TextFind", comment: "tooltip"))
        }
        .controlSize(.small)
    }
}


// MARK: - Preview

#Preview {
    FindPanelOptionView()
        .padding()
}
