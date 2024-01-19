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
//  © 2018-2023 1024jp
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

struct PatternSortView: View {
    
    enum SortKey: CaseIterable {
        
        case entire
        case column
        case regularExpression
    }
    
    
    weak var parent: NSHostingController<Self>?
    
    private let sampleLine: String
    private let sampleFontName: String?
    private let completionHandler: (_ pattern: any SortPattern, _ options: SortOptions) -> Void
    
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
        
        self._attributedSampleLine = State(initialValue: AttributedString(sampleLine))
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Section("Sample:") {
                GroupBox {
                    Text(self.attributedSampleLine)
                        .font(.custom(self.sampleFontName ?? "", size: 0))
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .help("Sample line to check which part in a line will be used for sort comparison.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.padding(.bottom)
            }
            
            Grid(alignment: .leadingFirstTextBaseline) {
                GridRow {
                    Text("Sort key:")
                        .gridColumnAlignment(.trailing)
                    
                    VStack(alignment: .leading) {
                        Picker(selection: $sortKey) {
                            Text("Entire line").tag(SortKey.entire)
                            Text("Column").tag(SortKey.column)
                            Text("Regular expression").tag(SortKey.regularExpression)
                        } label: {
                            EmptyView()
                        }
                        .pickerStyle(.radioGroup)
                        .horizontalRadioGroupLayout()
                        .labelsHidden()
                        .fixedSize()
                        .onChange(of: self.sortKey) { _ in self.validate() }
                        
                        switch self.sortKey {
                            case .entire:
                                EmptyView()
                            case .column:
                                ColumnSortPatternView(pattern: $columnSortPattern)
                                    .onChange(of: self.columnSortPattern) { _ in self.validate() }
                            case .regularExpression:
                                RegularExpressionSortPatternView(pattern: $regularExpressionSortPattern, error: $error)
                                    .onChange(of: self.regularExpressionSortPattern) { _ in self.validate() }
                        }
                    }
                }
                
                GridRow {
                    Text("Sort option:")
                    
                    VStack(alignment: .leading, spacing: 6) {  // 6 is natural AppKit spacing
                        Toggle("Ignore case", isOn: self.$options.ignoresCase)
                        Toggle("Respect language rules", isOn: self.$options.isLocalized)
                        Toggle("Treat numbers as numeric value", isOn: self.$options.numeric)
                        Toggle("Keep the first line at the top", isOn: self.$options.keepsFirstLine)
                        Toggle("In descending order", isOn: self.$options.descending)
                    }
                }
                .fixedSize()
            }
            
            HStack {
                HelpButton(anchor: "howto_pattern_sort")
                Spacer()
                SubmitButtonGroup("Sort") {
                    self.submit()
                } cancelAction: {
                    self.parent?.dismiss(nil)
                }.disabled(self.error != nil)
            }
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
    @MainActor private func submit() {
        
        guard
            self.parent?.commitEditing() == true
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
        } catch let error as SortPatternError {
            self.error = error
            return false
        } catch {
            fatalError()
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
        
        HStack {
            LabeledContent("Delimiter:") {
                TextField(text: $pattern.delimiter, prompt: Text(verbatim: ","), label: EmptyView.init)
                    .frame(width: 32)
            }.padding(.trailing)
            
            LabeledContent("Position:") {
                StepperNumberField(value: $pattern.column, default: 1, in: 1...(.max))
            }
        }.fixedSize()
    }
}



struct RegularExpressionSortPatternView: View {
    
    @Binding var pattern: RegularExpressionSortPattern
    @Binding var error: SortPatternError?
    
    private let formatter = RegularExpressionFormatter()
    
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                Text("Pattern:")
                VStack(alignment: .leading) {
                    ZStack(alignment: .leadingFirstTextBaseline) {
                        RegexTextField(text: $pattern.searchPattern, prompt: "Regular Expression")
                            .leadingInset(18)
                        Menu {
                            let patterns = UserDefaults.standard[.regexPatternSortHistory]
                            
                            Section("Recents") {
                                ForEach(patterns, id: \.self) { pattern in
                                    Button(pattern) {
                                        self.pattern.searchPattern = pattern
                                    }
                                }
                            }
                            
                            if !patterns.isEmpty {
                                Button("Clear Recents", role: .destructive, action: self.clearRecents)
                            }
                        } label: {
                            EmptyView()
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 16)
                        .padding(.leading, 4)
                    }
                    
                    HStack {
                        Toggle("Ignore case", isOn: $pattern.ignoresCase)
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
            }
        }
        
        HStack {
            Toggle("Use captured group:", isOn: $pattern.usesCaptureGroup)
            StepperNumberField(value: $pattern.group, default: 1,
                               in: 0...self.pattern.numberOfCaptureGroups)
                .disabled(!self.pattern.usesCaptureGroup)
        }.fixedSize()
    }
    
    
    /// Clears the regular expression pattern history.
    private func clearRecents() {
        
        UserDefaults.standard[.regexPatternSortHistory].removeAll()
    }
}



// MARK: - Preview

#Preview {
    PatternSortView(sampleLine: "Dog, 🐕, 1", sampleFontName: "Menlo") { (_, _) in }
}
