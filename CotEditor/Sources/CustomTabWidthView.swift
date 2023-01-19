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
//  © 2018-2023 1024jp
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
    
    /// Initialize view with given values.
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
        
        VStack {
            Form {
                TextField("Tab width:", value: $value,
                          format: .ranged(1...99, defaultValue: self.defaultWidth),
                          prompt: Text(self.defaultWidth, format: .number))
                .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .onSubmit(self.submit)
            }
            
            HStack {
                Spacer()
                SubmitButtonGroup(action: self.submit) {
                    self.parent?.dismiss(nil)
                }
            }
        }
        .fixedSize()
        .padding()
    }
    
    
    // MARK: Private Methods
    
    /// Submit the current input.
    private func submit() {
        
        self.completionHandler(self.value)
        self.parent?.dismiss(nil)
    }
}



// MARK: - Preview

struct CustomTabWidthView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        CustomTabWidthView(tabWidth: 4) { _ in }
    }
}
