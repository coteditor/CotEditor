//
//  CustomSurroundStringView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2023 1024jp
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

struct CustomSurroundStringView: View {
    
    weak var parent: NSHostingController<Self>?
    
    @AppStorage("beginCustomSurroundString") private var defaultBeginString: String?
    @AppStorage("endCustomSurroundString") private var defaultEndString: String?
    
    @State private var pair: Pair<String> = .init("", "")
    private let completionHandler: (_ pair: Pair<String>) -> Void
    
    
    // MARK: View
    
    /// Initialize view from a storyboard with given values.
    ///
    /// - Parameters:
    ///   - pair: A pair of strings to fill as default value.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init(pair: Pair<String>?, completionHandler: @escaping (_ pair: Pair<String>) -> Void) {
        
        self.completionHandler = completionHandler
        
        if let pair = pair {
            self.pair = pair
        } else if let begin = self.defaultBeginString, let end = self.defaultEndString {
            self.pair = Pair(begin, end)
        }
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Surround with:")
                .fontWeight(.semibold)
            
            HStack(alignment: .firstTextBaseline) {
                Text("Begin:")
                TextField("", text: $pair.begin)
                    .onSubmit(self.submit)
                    .frame(width: 48)
                    .padding(.trailing)
                
                Text("End:")
                TextField("", text: $pair.end, prompt: Text(verbatim: self.pair.begin))
                    .onSubmit(self.submit)
                    .frame(width: 48)
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
        
        self.parent?.commitEditing()
        
        guard !self.pair.begin.isEmpty else { return NSSound.beep() }
        
        // use beginString also for end delimiter if endString is empty
        let endString = self.pair.end.isEmpty ? self.pair.begin : self.pair.end
        
        self.completionHandler(Pair(self.pair.begin, endString))
        
        /// store the last used string pair
        self.defaultBeginString = self.pair.begin
        self.defaultEndString = self.pair.end
        
        self.parent?.dismiss(nil)
    }
}



// MARK: - Preview

struct CustomSurroundStringView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        CustomSurroundStringView(pair: nil) { _ in }
    }
}
