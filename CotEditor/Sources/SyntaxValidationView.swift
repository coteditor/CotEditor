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
//  © 2014-2023 1024jp
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
    
    let validator: SyntaxStyleValidator
    
    @State private var errors: [SyntaxStyleValidator.StyleError] = []
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            MessageView(count: self.errors.count)
            List(Array($errors.enumerated()), id: \.offset) { (_, $error) in
                ErrorView(error: $error)
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
        
        @State var count: Int
        
        
        var body: some View {
            
            Label {
                Text(self.message)
            } icon: {
                Image(nsImage: NSImage(named: (self.count == 0) ? NSImage.statusAvailableName : NSImage.statusUnavailableName)!)
            }
        }
        
        
        private var message: LocalizedStringKey {
            
            switch self.count {
                case 0:
                    return "No error found."
                case 1:
                    return "An error found."
                default:
                    return "\(self.count) errors found."
            }
        }
    }
    
    
    private struct ErrorView: View {
        
        @Binding var error: SyntaxStyleValidator.StyleError
        
        
        var body: some View {
            
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(self.error.localizedType):")
                            .fontWeight(.semibold)
                        Text(self.error.string)
                            .foregroundColor(.label)
                            .textSelection(.enabled)
                            .help(self.error.string)
                            .lineLimit(1)
                        if let role = self.error.localizedRole {
                            Text("(\(role))")
                                .foregroundColor(.secondaryLabel)
                        }
                    }
                    if let failureReason = self.error.failureReason {
                        Text(failureReason)
                            .controlSize(.small)
                            .foregroundColor(.label)
                            .textSelection(.enabled)
                    }
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.multicolor)
            }
        }
    }
}



// MARK: - Preview

struct SyntaxValidationView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        let style = NSMutableDictionary(dictionary: [
            "keywords": [["beginString": "abc"],
                         ["beginString": "abc"]],
            "commands": [["beginString": "Lorem ipsum dolor sit amet, consectetur[",
                          "regularExpression": true]],
        ])
        
        SyntaxValidationView(validator: .init(style: style))
            .frame(width: 400)
    }
}
