//
//  GoToLineView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2023 1024jp
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

struct GoToLineView: View {
    
    weak var parent: NSHostingController<Self>?  // workaround presentationMode.dismiss() doesn't work
    
    @State private var value: String
    private let completionHandler: (_ lineRange: FuzzyRange) -> Bool
    
    
    // MARK: View
    
    /// Initialize view with given values.
    ///
    /// - Parameters:
    ///   - lineRange: The current line range.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init(lineRange: FuzzyRange, completionHandler: @escaping (_ lineRange: FuzzyRange) -> Bool) {
        
        self._value = State(initialValue: lineRange.string)
        self.completionHandler = completionHandler
    }
    
    
    var body: some View {
        
        VStack {
            Form {
                TextField("Line:", text: $value, prompt: Text("Line Number"))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .onSubmit(self.submit)
            }
            
            HStack {
                HelpButton(anchor: "howto_jump")
                
                Spacer()
                
                SubmitButtonGroup("Go", action: self.submit) {
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
        
        guard
            let lineRange = FuzzyRange(string: self.value),
            self.completionHandler(lineRange)
        else { return NSSound.beep() }
        
        self.parent?.dismiss(nil)
    }
}



// MARK: - Preview

struct GoToLineView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        GoToLineView(lineRange: FuzzyRange(location: 1, length: 1)) { _ in true }
    }
}
