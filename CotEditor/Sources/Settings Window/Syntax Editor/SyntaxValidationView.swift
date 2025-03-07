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
    
    var errors: [SyntaxObject.Error]
    
    @State private var selection: Int?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            MessageView(count: self.errors.count)
            
            if !self.errors.isEmpty {
                List(Array(self.errors.enumerated()), id: \.offset, selection: $selection) { (_, error) in
                    ErrorView(error: error)
                }
                .border(.separator)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                ? String(localized: "No error found.", table: "SyntaxEditor",
                         comment: "message in the Validation pane")
                : String(localized: "\(self.count) errors found.", table: "SyntaxEditor",
                         comment: "message in the Validation pane")
        }
    }
    
    
    private struct ErrorView: View {
        
        var error: SyntaxObject.Error
        
        
        var body: some View {
            
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(self.error.type.label):", tableName: "SyntaxEditor")
                            .fontWeight(.medium)
                        Text(self.error.string)
                            .help(self.error.string)
                            .lineLimit(1)
                    }
                    Text(self.error.localizedDescription)
                        .controlSize(.small)
                        .foregroundStyle(.secondary)
                }
                .textSelection(.enabled)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.multicolor)
            }.padding(.vertical, 2)
        }
    }
}


private extension SyntaxObject.Error {
    
    var localizedDescription: String {
        
        switch self.code {
            case .duplicated:
                String(localized: "The same word is registered multiple times.",
                       table: "SyntaxEditor")
            case .regularExpression:
                String(localized: "Invalid regular expression.",
                       table: "SyntaxEditor")
            case .blockComment:
                String(localized: "Block comment needs both begin and end delimiters.",
                       table: "SyntaxEditor")
        }
    }
}


// MARK: - Preview

#Preview {
    let errors: [SyntaxObject.Error] = [
        .init(.duplicated, type: \.values, string: "bb"),
        .init(.regularExpression, type: \.outlines, string: "[]"),
        .init(.blockComment, type: \.comments, string: "bb"),
    ]
    
    return SyntaxValidationView(errors: errors)
        .frame(width: 400)
        .padding()
}

#Preview("No Error") {
    SyntaxValidationView(errors: [])
        .frame(width: 400)
        .padding()
}
