//
//  SyntaxValidationView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-09-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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

struct SyntaxValidationView: View {
    
    let validator: SyntaxValidator
    
    @State private var errors: [SyntaxValidator.Error] = []
    @State private var selection: Int?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            MessageView(count: self.errors.count)
            List(Array(self.errors.enumerated()), id: \.offset, selection: $selection) { (_, error) in
                ErrorView(error: error)
            }
        }
        .onReceive(self.validator.$errors) { errors in
            self.errors = errors
        }
        .onAppear {
            self.validator.validate()
        }
        .padding(8)
    }
    
    
    // MARK: Subviews
    
    private struct MessageView: View {
        
        var count: Int
        
        
        var body: some View {
            
            Label {
                Text(self.message)
            } icon: {
                Image(status: (self.count == 0) ? .available : .unavailable)
            }
        }
        
        
        private var message: String {
            
            (self.count == 0)
                ? String(localized: "No error found.", table: "Count",
                         comment: "message in the validation pane in the syntax editor")
                : String(localized: "\(self.count) errors found.", table: "Count",
                         comment: "message in the validation pane in the syntax editor")
        }
    }
    
    
    private struct ErrorView: View {
        
        var error: SyntaxValidator.Error
        
        
        var body: some View {
            
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(self.error.localizedType):")
                            .fontWeight(.semibold)
                        Text(self.error.string)
                            .help(self.error.string)
                            .lineLimit(1)
                        if let role = self.error.localizedRole {
                            Text("(\(role))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let failureReason = self.error.failureReason {
                        Text(failureReason)
                            .controlSize(.small)
                    }
                }
                .textSelection(.enabled)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.multicolor)
            }
        }
    }
}



// MARK: - Preview

#Preview {
    let dictionary: [String: [[String: Any]]] = [
        "keywords": [["beginString": "abc"],
                     ["beginString": "abc"]],
        "commands": [["beginString": "Lorem ipsum dolor sit amet, consectetur[",
                      "regularExpression": true]],
    ]
    let syntax = NSMutableDictionary(dictionary: dictionary)
    
    return SyntaxValidationView(validator: .init(syntax: syntax))
        .frame(width: 400)
}

#Preview("No Error") {
    SyntaxValidationView(validator: .init(syntax: [:]))
        .frame(width: 400)
}
