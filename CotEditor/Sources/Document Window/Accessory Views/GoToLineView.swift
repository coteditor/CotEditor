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
//  © 2016-2026 1024jp
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
import StringUtils

struct GoToLineView: View {
    
    var completionHandler: (_ lineRange: FuzzyRange) -> Bool
    
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var lineRange: FuzzyRange?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack {
            TextField(.init("Line Number", table: "GoToLine"), value: $lineRange, format: .fuzzyRange)
                .monospacedDigit()
                .onSubmit(self.submit)
            
            SubmitButtonGroup(.init("Go", table: "GoToLine", comment: "button label"), helpAnchor: "howto_jump", action: self.submit)
                .padding(.top)
        }
        .fixedSize()
    }
    
    
    // MARK: Private Methods
    
    /// Submits the current input.
    private func submit() {
        
        guard
            let lineRange,
            self.completionHandler(lineRange)
        else { return NSSound.beep() }
        
        self.dismiss()
    }
}


// MARK: - Preview

#Preview {
    GoToLineView { _ in true }
        .scenePadding()
}
