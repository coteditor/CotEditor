//
//  SyntaxLexicalRulesEditView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import Syntax

struct SyntaxLexicalRulesEditView: View {
    
    @Binding var rules: Syntax.LexicalRules
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Form {
                Picker(String(localized: "Delimiter escape style:", table: "SyntaxEditor"), selection: $rules.delimiterEscapeRule) {
                    ForEach(DelimiterEscapeRule.allCases, id: \.self) { rule in
                        Text(rule.label)
                    }
                }
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
                .fixedSize()
            }
            
            Spacer()
            
            HStack {
                Spacer()
                HelpLink(anchor: "syntax_lexicalrules_settings")
            }
        }
    }
}


private extension DelimiterEscapeRule {
    
    var label: String {
        
        switch self {
            case .backslash:
                String(localized: "DelimiterEscapeRule.backslash.label",
                       defaultValue: "Backslash",
                       table: "SyntaxEditor")
            case .none:
                String(localized: "DelimiterEscapeRule.none.label",
                       defaultValue: "None",
                       table: "SyntaxEditor")
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var rules: Syntax.LexicalRules = .default
    
    SyntaxLexicalRulesEditView(rules: $rules)
        .padding()
}
