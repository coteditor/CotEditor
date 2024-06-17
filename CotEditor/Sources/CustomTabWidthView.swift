//
//  CustomTabWidthView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-07-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2024 1024jp
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

struct CustomTabWidthView: View {
    
    weak var parent: NSHostingController<Self>?
    
    @State private var value: Int
    private let defaultWidth: Int
    private let completionHandler: (_ tabWidth: Int) -> Void
    
    
    // MARK: View
    
    /// Initializes view with given values.
    ///
    /// - Parameters:
    ///   - tabWidth: The default tab width.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init(tabWidth: Int, completionHandler: @escaping (_ tabWidth: Int) -> Void) {
        
        self._value = State(initialValue: tabWidth)
        self.defaultWidth = tabWidth
        self.completionHandler = completionHandler
    }
    
    
    var body: some View {
        
        VStack(alignment: .trailing) {
            LabeledContent(String(localized: "Tab width:", table: "CustomTabWidth")) {
                StepperNumberField(value: $value, default: self.defaultWidth, in: 1...99)
                    .onSubmit { self.submit() }
            }
            
            HStack {
                Spacer(minLength: 0)
                SubmitButtonGroup {
                    self.submit()
                } cancelAction: {
                    self.parent?.dismiss(nil)
                }
            }
        }
        .scenePadding()
    }
    
    
    // MARK: Private Methods
    
    /// Submits the current input.
    private func submit() {
        
        self.completionHandler(self.value)
        self.parent?.dismiss(nil)
    }
}



// MARK: - Preview

#Preview {
    CustomTabWidthView(tabWidth: 4) { _ in }
}
