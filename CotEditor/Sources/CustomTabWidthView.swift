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
//  © 2018-2022 1024jp
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
import Cocoa

struct CustomTabWidthView: View {
    
    weak var parent: NSHostingController<Self>?  // workaround presentationMode.dismiss() doesn't work
    
    @State private var value: Int
    private let defaultWidth: Int
    private let completionHandler: (_ tabWidth: Int) -> Void
    
    @State private var buttonWidth: CGFloat?
    
    
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
                TextField("Tab width:", value: $value, format: .number, prompt: Text(self.defaultWidth, format: .number))
                    .font(.body.monospacedDigit())
                    .onSubmit(self.submit)
            }
            
            HStack(alignment: .firstTextBaseline) {
                Spacer()
                
                Button(role: .cancel) {
                    self.parent?.dismiss(nil)
                } label: {
                    Text("Cancel")
                        .background(WidthGetter(key: WidthKey.self))
                        .frame(width: self.buttonWidth)
                }.keyboardShortcut(.cancelAction)
                
                Button(action: self.submit) {
                    Text("OK")
                        .background(WidthGetter(key: WidthKey.self))
                        .frame(width: self.buttonWidth)
                }.keyboardShortcut(.defaultAction)
            }.onPreferenceChange(WidthKey.self) { self.buttonWidth = $0 }
        }
        .fixedSize()
        .padding()
    }
    
    
    // MARK: Private Methods
    
    /// Submit the current input.
    private func submit() {
        
        let width = (self.value > 0) ? self.value : self.defaultWidth
        
        self.completionHandler(width)
        
        self.parent?.dismiss(nil)
    }
    
}



// MARK: - Preview

struct CustomTabWidthView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        CustomTabWidthView(tabWidth: 4) { _ in }
    }
    
}
