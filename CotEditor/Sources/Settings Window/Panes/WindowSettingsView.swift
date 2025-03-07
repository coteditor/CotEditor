//
//  WindowSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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
import Defaults

struct WindowSettingsView: View {
    
    @Namespace private var accessibility
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    @AppStorage(.windowTabbing) private var windowTabbing
    @AppStorage(.windowWidth) private var windowWidth
    @AppStorage(.windowHeight) private var windowHeight
    
    @AppStorage(.showLineNumbers) private var showLineNumbers
    @AppStorage(.showLineNumberSeparator) private var showLineNumberSeparator
    @AppStorage(.showInvisibles) private var showInvisibles
    @AppStorage(.showInvisibleNewLine) private var showInvisibleNewLine
    @AppStorage(.showInvisibleTab) private var showInvisibleTab
    @AppStorage(.showInvisibleSpace) private var showInvisibleSpace
    @AppStorage(.showInvisibleWhitespaces) private var showInvisibleWhitespaces
    @AppStorage(.showInvisibleControl) private var showInvisibleControl
    @AppStorage(.showIndentGuides) private var showIndentGuides
    @AppStorage(.showPageGuide) private var showPageGuide
    @AppStorage(.pageGuideColumn) private var pageGuideColumn
    @AppStorage(.highlightCurrentLine) private var highlightCurrentLine
    
    @AppStorage(.wrapLines) private var wrapLines
    @AppStorage(.enablesHangingIndent) private var enablesHangingIndent
    @AppStorage(.hangingIndentWidth) private var hangingIndentWidth
    @AppStorage(.writingDirection) private var writingDirection
    @AppStorage(.overscrollRate) private var overscrollRate
    
    @AppStorage(.showStatusBarLines) private var showStatusBarLines
    @AppStorage(.showStatusBarChars) private var showStatusBarChars
    @AppStorage(.showStatusBarWords) private var showStatusBarWords
    @AppStorage(.showStatusBarLocation) private var showStatusBarLocation
    @AppStorage(.showStatusBarLine) private var showStatusBarLine
    @AppStorage(.showStatusBarColumn) private var showStatusBarColumn
    
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 8) {
            GridRow(alignment: .lastTextBaseline) {
                Text("Open documents in tabs:", tableName: "WindowSettings",
                     comment: "Omit “documents” if label becomes too long.")
                    .accessibilityLabeledPair(role: .label, id: "windowTabbing", in: self.accessibility)
                
                Picker(selection: $windowTabbing) {
                    (Text("Respect System Setting", tableName: "WindowSettings") +
                     Text(" (\(NSWindow.userTabbingPreference.label))").foregroundStyle(.secondary)).tag(-1)
                    
                    Divider()
                    
                    ForEach([NSWindow.UserTabbingPreference.manual, .inFullScreen, .always], id: \.self) {
                        Text($0.label).tag($0.rawValue)
                    }
                } label: {
                    EmptyView()
                }
                .fixedSize()
                .accessibilityLabeledPair(role: .content, id: "windowTabbing", in: self.accessibility)
            }
            
            GridRow {
                Text("Window size:", tableName: "WindowSettings")
                    .accessibilityLabeledPair(role: .label, id: "windowSize", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        VStack(spacing: 1) {
                            TextField(value: $windowWidth, format: .number, prompt: Text("Auto", tableName: "WindowSettings", comment: "placeholder for window size field"), label: EmptyView.init)
                                .monospacedDigit()
                                .multilineTextAlignment(self.layoutDirection == .rightToLeft ? .leading : .trailing)
                                .frame(width: 64)
                                .accessibilityLabeledPair(role: .content, id: "windowWidth", in: self.accessibility)
                            Text("Width", tableName: "WindowSettings")
                                .controlSize(.small)
                                .accessibilityLabeledPair(role: .label, id: "windowWidth", in: self.accessibility)
                        }
                        Text("px", tableName: "WindowSettings", comment: "length unit following an input field")
                            .accessibilityLabel(String(localized: "pixels", table: "WindowSettings", comment: "accessibility label for “px”"))
                    }
                    .accessibilityElement(children: .contain)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        VStack(spacing: 1) {
                            TextField(value: $windowHeight, format: .number, prompt: Text("Auto", tableName: "WindowSettings", comment: "placeholder for window size field"), label: EmptyView.init)
                                .monospacedDigit()
                                .multilineTextAlignment(self.layoutDirection == .rightToLeft ? .leading : .trailing)
                                .frame(width: 64)
                                .accessibilityLabeledPair(role: .label, id: "windowHeight", in: self.accessibility)
                            Text("Height", tableName: "WindowSettings")
                                .controlSize(.small)
                                .accessibilityLabeledPair(role: .content, id: "windowHeight", in: self.accessibility)
                        }
                        Text("px", tableName: "WindowSettings", comment: "length unit following an input field")
                            .accessibilityLabel(String(localized: "pixels", table: "WindowSettings", comment: "accessibility label for “px”"))
                    }
                    .accessibilityElement(children: .contain)
                }
                .accessibilityLabeledPair(role: .content, id: "windowSize", in: self.accessibility)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            GridRow {
                Text("Show:", tableName: "WindowSettings")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(String(localized: "Line numbers", table: "WindowSettings"), isOn: $showLineNumbers)
                    Toggle(String(localized: "Draw separator", table: "WindowSettings"), isOn: $showLineNumberSeparator)
                        .disabled(!self.showLineNumbers)
                        .padding(.leading, 20)
                    
                    Toggle(String(localized: "Invisible characters", table: "WindowSettings"), isOn: $showInvisibles)
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                        GridRow {
                            Toggle(String(localized: "Line ending", table: "WindowSettings", comment: "invisible character type"), isOn: $showInvisibleNewLine)
                            Toggle(String(localized: "Tab", table: "WindowSettings", comment: "invisible character type"), isOn: $showInvisibleTab)
                            Toggle(String(localized: "Space", table: "WindowSettings", comment: "invisible character type"), isOn: $showInvisibleSpace)
                        }
                        GridRow {
                            Toggle(String(localized: "Other whitespaces", table: "WindowSettings", comment: "invisible character type"), isOn: $showInvisibleWhitespaces)
                            Toggle(String(localized: "Other control characters", table: "WindowSettings", comment: "invisible character type"), isOn: $showInvisibleControl)
                                .gridCellColumns(2)
                        }
                    }
                    .padding(.leading, 20)
                    .fixedSize()
                    
                    Toggle(String(localized: "Indent guides", table: "WindowSettings"), isOn: $showIndentGuides)
                    HStack(alignment: .firstTextBaseline) {
                        Toggle(String(localized: "Page guide at column:", table: "WindowSettings"), isOn: $showPageGuide)
                        StepperNumberField(value: $pageGuideColumn, default: UserDefaults.standard[initial: .pageGuideColumn], in: 1...999)
                            .accessibilityLabel(String(localized: "Page guide at column:", table: "WindowSettings"))
                            .disabled(!self.showPageGuide)
                    }
                }
            }
            
            GridRow {
                Text("Current line:", tableName: "WindowSettings")
                    .gridColumnAlignment(.trailing)
                
                Toggle(String(localized: "Change background color", table: "WindowSettings"), isOn: $highlightCurrentLine)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            GridRow {
                Text("Line wrapping:", tableName: "WindowSettings")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(String(localized: "Wrap lines to editor width", table: "WindowSettings"), isOn: $wrapLines)
                    HStack(alignment: .firstTextBaseline) {
                        Toggle(String(localized: "Indent wrapped lines by", table: "WindowSettings"), isOn: $enablesHangingIndent)
                        StepperNumberField(value: $hangingIndentWidth, default: UserDefaults.standard[initial: .hangingIndentWidth], in: 0...99)
                            .disabled(!self.enablesHangingIndent)
                            .accessibilityLabel(String(localized: "wrapped line indent spaces", table: "WindowSettings", comment: "accessibility label"))
                        Text("spaces", tableName: "WindowSettings", comment: "unit for indentation")
                    }
                }
            }
            
            GridRow {
                Text("Writing direction:", tableName: "WindowSettings")
                    .accessibilityLabeledPair(role: .label, id: "writingDirection", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                Picker(selection: $writingDirection) {
                    ForEach(WritingDirection.allCases, id: \.self) {
                        Text($0.label)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
                .labelsHidden()
                .accessibilityLabeledPair(role: .content, id: "writingDirection", in: self.accessibility)
            }
            
            GridRow {
                Text("Overscroll:", tableName: "WindowSettings")
                    .accessibilityLabeledPair(role: .label, id: "overscrollRate", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                Stepper(value: $overscrollRate, in: 0...1, step: 0.1, format: .percent.precision(.fractionLength(0)), label: EmptyView.init)
                    .monospacedDigit()
                    .multilineTextAlignment(self.layoutDirection == .rightToLeft ? .leading : .trailing)
                    .accessibilityLabeledPair(role: .content, id: "overscrollRate", in: self.accessibility)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            GridRow {
                Text("Status bar shows:", tableName: "WindowSettings")
                    .accessibilityLabeledPair(role: .label, id: "sideBarShows", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                HStack(alignment: .firstTextBaseline, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(String(localized: "Line count", table: "WindowSettings"), isOn: $showStatusBarLines)
                        Toggle(String(localized: "Character count", table: "WindowSettings"), isOn: $showStatusBarChars)
                        Toggle(String(localized: "Word count", table: "WindowSettings"), isOn: $showStatusBarWords)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(String(localized: "Location", table: "WindowSettings"), isOn: $showStatusBarLocation)
                        Toggle(String(localized: "Current line", table: "WindowSettings"), isOn: $showStatusBarLine)
                        Toggle(String(localized: "Current column", table: "WindowSettings"), isOn: $showStatusBarColumn)
                    }
                }
                .accessibilityLabeledPair(role: .content, id: "sideBarShows", in: self.accessibility)
            }
            .fixedSize()
            
            HStack {
                Spacer()
                HelpLink(anchor: "settings_window")
            }.padding(.top, -8)
        }
        .padding(.top, 14)
        .scenePadding([.horizontal, .bottom])
        .frame(minWidth: 600)
    }
}


private extension NSWindow.UserTabbingPreference {
    
    var label: String {
        
        switch self {
            case .manual:
                String(localized: "Never",
                       table: "WindowSettings",
                       comment: "window tabbing option")
            case .always:
                String(localized: "Always",
                       table: "WindowSettings",
                       comment: "window tabbing option")
            case .inFullScreen:
                String(localized: "Automatically",
                       table: "WindowSettings",
                       comment: "window tabbing option")
            @unknown default:
                fatalError()
        }
    }
}


private extension WritingDirection {
    
    var label: String {
        
        switch self {
            case .leftToRight:
                String(localized: "WritingDirection.leftToRight.label",
                       defaultValue: "Left to right",
                       table: "WindowSettings",
                       comment: "writing direction option")
            case .rightToLeft:
                String(localized: "WritingDirection.rightToLeft.label",
                       defaultValue: "Right to left",
                       table: "WindowSettings",
                       comment: "writing direction option")
            case .vertical:
                String(localized: "WritingDirection.vertical.label",
                       defaultValue: "Vertical",
                       table: "WindowSettings",
                       comment: "writing direction option")
        }
    }
}


// MARK: - Preview

#Preview {
    WindowSettingsView()
}
