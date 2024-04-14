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
//  © 2016-2024 1024jp
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
    
    weak var parent: NSHostingController<Self>?
    
    /// The current line range.
    @State var lineRange: FuzzyRange
    
    /// The callback method to perform when the command was accepted.
    let completionHandler: (_ lineRange: FuzzyRange) -> Bool
    
    
    // MARK: View
    
    var body: some View {
        
        VStack {
            Form {
                TextField(String(localized: "Line:", table: "GoToLine"), value: $lineRange, format: .fuzzyRange,
                          prompt: Text("Line Number", tableName: "GoToLine", comment: "placeholder"))
                    .monospacedDigit()
                    .environment(\.layoutDirection, .rightToLeft)
                    .onSubmit { self.submit() }
            }
            
            HStack {
                HelpButton(anchor: "howto_jump")
                
                Spacer()
                
                SubmitButtonGroup(String(localized: "Go", table: "GoToLine", comment: "button label")) {
                    self.submit()
                } cancelAction: {
                    self.parent?.dismiss(nil)
                }
            }
        }
        .fixedSize()
        .scenePadding()
    }
    
    
    // MARK: Private Methods
    
    /// Submits the current input.
    @MainActor private func submit() {
        
        guard
            self.completionHandler(self.lineRange)
        else { return NSSound.beep() }
        
        self.parent?.dismiss(nil)
    }
}



// MARK: - Preview

#Preview {
    GoToLineView(lineRange: FuzzyRange(location: 1, length: 1)) { _ in true }
}
