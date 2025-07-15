//
//  PatternSortView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-01-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2025 1024jp
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
import LineSort

struct PatternSortView: View {
    
    enum SortKey: CaseIterable {
        
        case entire
        case column
        case regularExpression
    }
    
    
    weak var parent: NSHostingController<Self>?
    
    private var sampleLine: String
    private var sampleFontName: String?
    private var completionHandler: (_ pattern: any SortPattern, _ options: SortOptions) -> Void
    
    @State private var sortKey: SortKey = .column
    @State private var columnSortPattern = CSVSortPattern()
    @State private var regularExpressionSortPattern = RegularExpressionSortPattern()
    @State private var options = SortOptions()
    
    @State private var attributedSampleLine: AttributedString
    @State private var error: SortPatternError?
    
    
    // MARK: View
    
    /// Initializes view with given values.
    ///
    /// - Parameters:
    ///   - sampleLine: A line of target text to display as sample.
    ///   - sampleFontName: The name of the editor font for the sample line display.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init(sampleLine: String, sampleFontName: String? = nil, completionHandler: @escaping (_ pattern: any SortPattern, _ options: SortOptions) -> Void) {
        
        self.sampleLine = sampleLine
        self.sampleFontName = sampleFontName
        self.completionHandler = completionHandler
        
        self.attributedSampleLine = AttributedString(sampleLine)
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Section(String(localized: "Sample:", table: "PatternSort")) {
                GroupBox {
                    Text(self.attributedSampleLine)
                        .font(.custom(self.sampleFontName ?? "", size: 0))
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .help(String(localized: "Sample line to check which part in a line will be used for sort comparison.", table: "PatternSort", comment: "tooltip"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.padding(.bottom)
            }
            
            Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 14) {
                GridRow {
                    Text("Sort key:", tableName: "PatternSort")
                        .gridColumnAlignment(.trailing)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Picker(selection: $sortKey) {
                            ForEach(SortKey.allCases, id: \.self) {
                                Text($0.label)
                            }
                        } label: {
                            EmptyView()
                        }
                        .pickerStyle(.radioGroup)
                        .horizontalRadioGroupLayout()
                        .labelsHidden()
                        .fixedSize()
                        .onChange(of: self.sortKey) { self.validate() }
                        
                        switch self.sortKey {
                            case .entire:
                                EmptyView()
                            case .column:
                                ColumnSortPatternView(pattern: $columnSortPattern)
                                    .onChange(of: self.columnSortPattern) { self.validate() }
                            case .regularExpression:
                                RegularExpressionSortPatternView(pattern: $regularExpressionSortPattern, error: $error)
                                    .onChange(of: self.regularExpressionSortPattern) { self.validate() }
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                
                GridRow {
                    Text("Sort option:", tableName: "PatternSort")
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(String(localized: "Ignore case", table: "PatternSort"),
                               isOn: $options.ignoresCase)
                        Toggle(String(localized: "Respect language rules", table: "PatternSort"),
                               isOn: $options.isLocalized)
                        Toggle(String(localized: "Treat numbers as numeric value", table: "PatternSort"),
                               isOn: $options.numeric)
                        Toggle(String(localized: "Keep the first line at the top", table: "PatternSort"),
                               isOn: $options.keepsFirstLine)
                        Toggle(String(localized: "In descending order", table: "PatternSort"),
                               isOn: $options.descending)
                    }
                }
                .fixedSize()
                .accessibilityElement(children: .contain)
            }
            
            HStack {
                HelpLink(anchor: "howto_pattern_sort")
                Spacer()
                SubmitButtonGroup(String(localized: "Sort", table: "PatternSort", comment: "button label")) {
                    self.submit()
                } cancelAction: {
                    self.parent?.dismiss(nil)
                }.disabled(self.error != nil)
            }
            .padding(.top, 8)
        }
        .onAppear {
            self.validate()
        }
        .fixedSize(horizontal: false, vertical: true)
        .scenePadding()
        .frame(minWidth: 500)
    }
    
    
    // MARK: Private Methods
    
    /// The sort pattern currently selected.
    private var sortPattern: any SortPattern {
        
        switch self.sortKey {
            case .entire: return EntireLineSortPattern()
            case .column: return self.columnSortPattern
            case .regularExpression: return self.regularExpressionSortPattern
        }
    }
    
    
    /// Submits the current input.
    private func submit() {
        
        guard
            self.parent?.endEditing() == true
        else { return NSSound.beep() }
        
        let pattern = self.sortPattern
        
        if let pattern = pattern as? RegularExpressionSortPattern {
            UserDefaults.standard[.regexPatternSortHistory].appendUnique(pattern.searchPattern, maximum: 10)
        }
        
        self.completionHandler(pattern, self.options)
        self.parent?.dismiss(nil)
    }
    
    
    /// Validates the current sort pattern and applies the result to the view.
    ///
    /// - Returns: Whether the sort pattern is valid.
    @discardableResult
    private func validate() -> Bool {
        
        self.attributedSampleLine.backgroundColor = nil
        
        do {
            try self.sortPattern.validate()
        } catch {
            self.error = error
            return false
        }
        self.error = nil
        
        if let range = self.sortPattern.range(for: self.sampleLine),
           let attrRange = Range<AttributedString.Index>(range, in: self.attributedSampleLine)
        {
            self.attributedSampleLine[attrRange].backgroundColor = .accentColor.opacity(0.3)
        }
        
        return true
    }
}


struct ColumnSortPatternView: View {
    
    @Binding var pattern: CSVSortPattern
    
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline) {
            LabeledContent(String(localized: "Delimiter:", table: "PatternSort")) {
                TextField(text: $pattern.delimiter, prompt: Text(verbatim: ","), label: EmptyView.init)
                    .frame(width: 32)
            }.padding(.trailing)
            
            LabeledContent(String(localized: "Position:", table: "PatternSort")) {
                StepperNumberField(value: $pattern.column, default: 1, in: 1...(.max))
            }
        }.fixedSize()
    }
}


struct RegularExpressionSortPatternView: View {
    
    @Binding var pattern: RegularExpressionSortPattern
    @Binding var error: SortPatternError?
    
    
    @Namespace private var accessibility
    
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                Text("Pattern:", tableName: "PatternSort")
                    .accessibilityLabeledPair(role: .label, id: "pattern", in: self.accessibility)
                VStack(alignment: .leading, spacing: 6) {
                    RegexTextField(text: $pattern.searchPattern, prompt: String(localized: "Regular Expression", table: "PatternSort", comment: "placeholder for regular expression pattern field"))
                        .leadingInset(18)
                        .overlay(alignment: .leadingLastTextBaseline) {
                            Menu {
                                let patterns = UserDefaults.standard[.regexPatternSortHistory]
                                
                                Section(String(localized: "Recents", table: "PatternSort", comment: "menu header")) {
                                    ForEach(patterns, id: \.self) { pattern in
                                        Button(pattern) {
                                            self.pattern.searchPattern = pattern
                                        }
                                    }
                                }
                                
                                if !patterns.isEmpty {
                                    Button(String(localized: "Clear Recents", table: "PatternSort"), role: .destructive, action: self.clearRecents)
                                }
                            } label: {
                                EmptyView()
                            }
                            .accessibilityLabel(String(localized: "Recents", table: "PatternSort"))
                            .menuStyle(.button)
                            .buttonStyle(.borderless)
                            .frame(width: 16)
                            .padding(.leading, 4)
                        }
                    
                    HStack(alignment: .firstTextBaseline) {
                        Toggle(String(localized: "Ignore case", table: "PatternSort"),
                               isOn: $pattern.ignoresCase)
                            .fixedSize()
                        Spacer()
                        
                        if let errorMessage = self.error?.errorDescription {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .symbolVariant(.fill)
                                .symbolRenderingMode(.multicolor)
                                .lineLimit(1)
                                .help(errorMessage)
                        }
                    }
                    .controlSize(.small)
                    .frame(minHeight: 8)  // keep height for error message
                }
                .accessibilityLabeledPair(role: .content, id: "pattern", in: self.accessibility)
            }
            .accessibilityElement(children: .contain)
        }
        
        HStack(alignment: .firstTextBaseline) {
            Toggle(String(localized: "Use captured group:", table: "PatternSort"), isOn: $pattern.usesCaptureGroup)
            StepperNumberField(value: $pattern.group, default: 1, in: 0...self.pattern.numberOfCaptureGroups)
                .disabled(!self.pattern.usesCaptureGroup)
                .accessibilityLabel(String(localized: "Use captured group:", table: "PatternSort"))
        }
    }
    
    
    /// Clears the regular expression pattern history.
    private func clearRecents() {
        
        UserDefaults.standard[.regexPatternSortHistory].removeAll()
    }
}


private extension PatternSortView.SortKey {
    
    var label: String {
        
        switch self {
            case .entire:
                String(localized: "Entire line",
                       table: "PatternSort",
                       comment: "pattern sort key option")
            case .column:
                String(localized: "Column",
                       table: "PatternSort",
                       comment: "pattern sort key option")
            case .regularExpression:
                String(localized: "Regular expression",
                       table: "PatternSort",
                       comment: "pattern sort key option")
        }
    }
}


extension SortPatternError: @retroactive LocalizedError {
    
    public var errorDescription: String? {
        
        switch self {
            case .emptyPattern:
                String(localized: "Empty pattern",
                       table: "PatternSort",
                       comment: "error message (“pattern” is a regular expression pattern)")
            case .invalidRegularExpressionPattern:
                String(localized: "Invalid pattern",
                       table: "PatternSort",
                       comment: "error message (“pattern” is a regular expression pattern)")
        }
    }
}


// MARK: - Preview

#Preview {
    PatternSortView(sampleLine: "Dog, 🐕, 1", sampleFontName: "Menlo") { (_, _) in }
}
