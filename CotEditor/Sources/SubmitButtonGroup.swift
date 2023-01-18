//
//  SubmitButtonGroup.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-18.
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

struct SubmitButtonGroup: View {
    
    private let submitLabel: LocalizedStringKey
    private let submitAction: () -> Void
    private let cancelAction: () -> Void
    
    @State private var buttonWidth: CGFloat?
    
    
    // MARK: View
    
    /// Create two buttons with the same width; one is the cancel button and another is the submit button.
    ///
    /// - Parameters:
    ///   - submitLabel: The label to be displayed in the submit button.
    ///   - action: The action invoked when the submit button was pressed.
    ///   - cancelAction: The action invoked when the cancel button was pressed.
    init(_ submitLabel: LocalizedStringKey = "OK", action: @escaping () -> Void, cancelAction: @escaping () -> Void) {
        
        self.submitLabel = submitLabel
        self.submitAction = action
        self.cancelAction = cancelAction
    }
    
    
    var body: some View {
        
        HStack {
            Button(role: .cancel, action: self.cancelAction) {
                Text("Cancel")
                    .background(WidthGetter(key: WidthKey.self))
                    .frame(width: self.buttonWidth)
            }.keyboardShortcut(.cancelAction)
            
            Button(action: self.submitAction) {
                Text(self.submitLabel)
                    .background(WidthGetter(key: WidthKey.self))
                    .frame(width: self.buttonWidth)
            }.keyboardShortcut(.defaultAction)
        }
        .onPreferenceChange(WidthKey.self) { self.buttonWidth = $0 }
        .fixedSize()
    }
}



// MARK: - Preview

struct SubmitButtonGroup_Previews: PreviewProvider {
    
    static var previews: some View {
        
        SubmitButtonGroup(action: {}, cancelAction: {})
    }
}
