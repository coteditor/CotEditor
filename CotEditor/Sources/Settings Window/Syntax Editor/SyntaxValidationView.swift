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
//  © 2014-2026 1024jp
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
import Syntax

struct SyntaxValidationView: View {
    
    var errors: [Syntax.Error]
    
    @State private var selection: Int?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            MessageView(count: self.errors.count)
            
            if !self.errors.isEmpty {
                List(Array(self.errors.enumerated()), id: \.offset, selection: $selection) { _, error in
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
                StatusImage(status: (self.count == 0) ? .available : .unavailable)
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
        
        var error: Syntax.Error
        
        
        var body: some View {
            
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(self.error.scope.label):", tableName: "SyntaxEditor")
                            .fontWeight(.medium)
                        Text(self.error.value)
                            .help(self.error.value)
                            .lineLimit(1)
                    }
                    Text(self.error.code.localizedDescription)
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


extension Syntax.Error.Code {
    
    var localizedDescription: String {
        
        switch self {
            case .duplicated:
                String(localized: "Syntax.Error.Code.duplicated",
                       defaultValue: "The same word is registered multiple times.",
                       table: "SyntaxEditor")
            case .regularExpression:
                String(localized: "Syntax.Error.Code.regularExpression",
                       defaultValue: "Invalid regular expression.",
                       table: "SyntaxEditor")
            case .blockComment:
                String(localized: "Syntax.Error.Code.blockComment",
                       defaultValue: "Block comment needs both begin and end delimiters.",
                       table: "SyntaxEditor")
            case .nestableBlockComment:
                String(localized: "Syntax.Error.Code.nestableBlockComment",
                       defaultValue: "Nestable block comment must use different begin and end delimiters.",
                       table: "SyntaxEditor")
        }
    }
}


private extension Syntax.Error.Scope {
    
    var label: String {
        
        switch self {
            case .highlight(let syntaxType):
                syntaxType.label
            case .outline:
                SyntaxEditView.Pane.outline.label
            case .blockComment:
                SyntaxEditView.Pane.comments.label
        }
    }
}


// MARK: - Preview

#Preview {
    let errors: [Syntax.Error] = [
        .init(.duplicated, scope: .highlight(.values), value: "bb"),
        .init(.regularExpression, scope: .outline, value: "[]"),
        .init(.blockComment, scope: .blockComment, value: "bb"),
        .init(.nestableBlockComment, scope: .blockComment, value: "/*"),
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
