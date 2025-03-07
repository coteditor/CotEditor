//
//  CustomSurroundView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2025 1024jp
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

struct CustomSurroundView: View {
    
    private enum Focus {
        
        case beginField
        case endField
    }
    
    
    weak var parent: NSHostingController<Self>?
    
    @AppStorage("beginCustomSurroundString") private var defaultBeginString: String?
    @AppStorage("endCustomSurroundString") private var defaultEndString: String?
    
    @FocusState private var focus: Focus?
    
    @State private var pair: Pair<String> = .init("", "")
    private var completionHandler: (_ pair: Pair<String>) -> Void
    
    
    // MARK: View
    
    /// Initializes view from a storyboard with given values.
    ///
    /// - Parameters:
    ///   - pair: A pair of strings to fill as default value.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init(pair: Pair<String>?, completionHandler: @escaping (_ pair: Pair<String>) -> Void) {
        
        self.completionHandler = completionHandler
        
        if let pair {
            self.pair = pair
        } else if let begin = self.defaultBeginString, let end = self.defaultEndString {
            self.pair = Pair(begin, end)
        }
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Surround with:", tableName: "CustomSurround")
                .fontWeight(.semibold)
            
            HStack(alignment: .firstTextBaseline) {
                LabeledContent(String(localized: "Begin:", table: "CustomSurround")) {
                    TextField(text: $pair.begin, label: EmptyView.init)
                        .frame(width: 48)
                }
                .focused($focus, equals: .beginField)
                .padding(.trailing)
                
                LabeledContent(String(localized: "End:", table: "CustomSurround")) {
                    TextField(text: $pair.end, prompt: Text(verbatim: self.pair.begin), label: EmptyView.init)
                        .frame(width: 48)
                }
                .focused($focus, equals: .endField)
            }
            .onSubmit(self.submit)
            .fixedSize()
            
            HStack {
                Spacer()
                SubmitButtonGroup {
                    self.submit()
                } cancelAction: {
                    self.parent?.dismiss(nil)
                }
            }
            .padding(.top, 8)
        }
        .onAppear {
            self.focus = .beginField
        }
        .fixedSize()
        .scenePadding()
    }
    
    
    // MARK: Private Methods
    
    /// Submits the current input.
    private func submit() {
        
        guard
            self.parent?.endEditing() == true,
            !self.pair.begin.isEmpty
        else { return NSSound.beep() }
        
        // use beginString also for end delimiter if endString is empty
        let endString = self.pair.end.isEmpty ? self.pair.begin : self.pair.end
        
        self.completionHandler(Pair(self.pair.begin, endString))
        
        // store the last used string pair
        self.defaultBeginString = self.pair.begin
        self.defaultEndString = self.pair.end
        
        self.parent?.dismiss(nil)
    }
}


// MARK: - Preview

#Preview {
    CustomSurroundView(pair: nil) { _ in }
}
