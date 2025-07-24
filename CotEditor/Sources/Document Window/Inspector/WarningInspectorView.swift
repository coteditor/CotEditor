//
//  WarningInspectorView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2025 1024jp
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

struct WarningInspectorView: View, HostedPaneView {
    
    var document: DataDocument?
    var isPresented = false
    
    
    var body: some View {
        
        VSplitView {
            IncompatibleCharactersView(document: self.isPresented ? self.document as? Document : nil)
                .padding(.bottom, 12)
            InconsistentLineEndingsView(document: self.isPresented ? self.document as? Document : nil)
                .padding(.top, 8)
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12))
        .accessibilityLabel(String(localized: "InspectorPane.warnings.label",
                                   defaultValue: "Warnings", table: "Document"))
    }
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 240, height: 300)) {
    WarningInspectorView(isPresented: true)
}
