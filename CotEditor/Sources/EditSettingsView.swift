//
//  EditSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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

struct EditSettingsView: View {
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    @AppStorage(.autoExpandTab) private var autoExpandTab
    @AppStorage(.tabWidth) private var tabWidth
    @AppStorage(.detectsIndentStyle) private var detectsIndentStyle
    @AppStorage(.autoIndent) private var autoIndent
    @AppStorage(.indentWithTabKey) private var indentWithTabKey
    
    @AppStorage(.autoTrimsTrailingWhitespace) private var autoTrimsTrailingWhitespace
    @AppStorage(.trimsWhitespaceOnlyLines) private var trimsWhitespaceOnlyLines
    
    @AppStorage(.autoLinkDetection) private var autoLinkDetection
    @AppStorage(.highlightBraces) private var highlightBraces
    @AppStorage(.highlightLtGt) private var highlightLtGt
    @AppStorage(.highlightSelectionInstance) private var highlightSelectionInstance
    @AppStorage(.selectionInstanceHighlightDelay) private var selectionInstanceHighlightDelay
    
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 12) {
            GridRow {
                Text("Indentation:", tableName: "EditSettings")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Picker(String(localized: "Prefer using", table: "EditSettings"), selection: $autoExpandTab) {
                        Text("Spaces", tableName: "EditSettings", comment: "indent style").tag(true)
                        Text("Tabs", tableName: "EditSettings", comment: "indent style").tag(false)
                    }.fixedSize()
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("Indent width:", tableName: "EditSettings")
                        StepperNumberField(value: $tabWidth, default: UserDefaults.standard[initial: .tabWidth], in: 1...99)
                        Text("spaces", tableName: "EditSettings", comment: "unit for indentation")
                    }
                    Toggle(String(localized: "Detect indent style on document opening", table: "EditSettings"), isOn: $detectsIndentStyle)
                    Toggle(String(localized: "Automatically indent while typing", table: "EditSettings"), isOn: $autoIndent)
                    Toggle(String(localized: "Indent selection with Tab key", table: "EditSettings"), isOn: $indentWithTabKey)
                }
            }
            
            GridRow {
                Text("Whitespace:", tableName: "EditSettings")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(String(localized: "Automatically trim trailing whitespace", table: "EditSettings"), isOn: $autoTrimsTrailingWhitespace)
                    Toggle(String(localized: "Including whitespace-only lines", table: "EditSettings"), isOn: $trimsWhitespaceOnlyLines)
                        .disabled(!self.autoTrimsTrailingWhitespace)
                        .padding(.leading, 20)
                }
            }
            
            GridRow {
                Text("Content parse:", tableName: "EditSettings")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(String(localized: "Link URLs in document", table: "EditSettings"), isOn: $autoLinkDetection)
                    Toggle(String(localized: "Highlight matching braces “()” “[]” “{}”", table: "EditSettings"), isOn: $highlightBraces)
                    Toggle(String(localized: "Highlight “<>”", table: "EditSettings"), isOn: $highlightLtGt)
                        .disabled(!self.highlightBraces)
                        .padding(.leading, 20)
                    Toggle(String(localized: "Highlight instances of selected text", table: "EditSettings"), isOn: $highlightSelectionInstance)
                    HStack(alignment: .firstTextBaseline) {
                        Text("Delay:", tableName: "EditSettings")
                        Stepper(value: $selectionInstanceHighlightDelay, in: 0...10, step: 0.25, format: .number.precision(.fractionLength(2)), label: EmptyView.init)
                        .monospacedDigit()
                        .multilineTextAlignment(self.layoutDirection == .rightToLeft ? .leading : .trailing)  // width: 40
                        Text("seconds", tableName: "EditSettings", comment: "init for delay time")
                    }
                    .disabled(!self.highlightSelectionInstance)
                    .foregroundStyle(self.highlightSelectionInstance ? .primary : .tertiary)
                    .controlSize(.small)
                    .padding(.leading, 20)
                }
            }
            
            HStack {
                Spacer()
                HelpButton(anchor: "settings_edit")
            }
        }
        .scenePadding()
        .frame(minWidth: 600)
    }
}



// MARK: - Preview

#Preview {
    EditSettingsView()
}
