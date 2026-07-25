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
//  © 2017-2026 1024jp
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
    
    
    private enum AppStorageKey {
        
        static let beginString = "beginCustomSurroundString"
        static let endString = "endCustomSurroundString"
    }
    
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.resetFocus) private var resetFocus
    
    @AppStorage(AppStorageKey.beginString) private var defaultBeginString: String?
    @AppStorage(AppStorageKey.endString) private var defaultEndString: String?
    
    @FocusState private var focus: Focus?
    @Namespace private var namespace
    
    @State private var pair: Pair<String>
    private var completionHandler: (_ pair: Pair<String>) -> Void
    
    
    // MARK: View
    
    /// Initializes view with given values.
    ///
    /// - Parameters:
    ///   - pair: A pair of strings to fill as default values.
    ///   - completionHandler: The callback method to perform when the command is accepted.
    init(pair: Pair<String>?, completionHandler: @escaping (_ pair: Pair<String>) -> Void) {
        
        self.completionHandler = completionHandler
        
        self.pair = if let pair {
            pair
        } else if let begin = UserDefaults.standard.string(forKey: AppStorageKey.beginString) {
            Pair(begin, UserDefaults.standard.string(forKey: AppStorageKey.endString) ?? "")
        } else {
            Pair("", "")
        }
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Surround with:", tableName: "CustomSurround")
                .fontWeight(.semibold)
            
            HStack(alignment: .firstTextBaseline) {
                LabeledContent(.init("Begin:", table: "CustomSurround")) {
                    TextField(text: $pair.begin, label: EmptyView.init)
                        .frame(width: 48)
                }
                .focused($focus, equals: .beginField)
                .padding(.trailing)
                
                LabeledContent(.init("End:", table: "CustomSurround")) {
                    TextField(text: $pair.end, prompt: Text(self.pair.begin), label: EmptyView.init)
                        .frame(width: 48)
                }
                .focused($focus, equals: .endField)
            }
            .onSubmit(self.submit)
            
            SubmitButtonGroup(action: self.submit)
                .padding(.top)
        }
        .onAppear {
            self.focus = .beginField
        }
        .fixedSize()
    }
    
    
    // MARK: Private Methods
    
    /// Submits the current input.
    private func submit() {
        
        self.resetFocus(in: self.namespace)
        
        guard !self.pair.begin.isEmpty else { return NSSound.beep() }
        
        // use beginString also for end delimiter if endString is empty
        let endString = self.pair.end.isEmpty ? self.pair.begin : self.pair.end
        
        self.completionHandler(Pair(self.pair.begin, endString))
        
        // store the last used string pair
        self.defaultBeginString = self.pair.begin
        self.defaultEndString = self.pair.end
        
        self.dismiss()
    }
}


// MARK: - Preview

#Preview {
    CustomSurroundView(pair: nil) { _ in }
        .scenePadding()
}
