//
//  FormatSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2025 1024jp
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
import FileEncoding
import LineEnding

struct FormatSettingsView: View {
    
    @Namespace private var accessibility
    
    @AppStorage(.lineEndCharCode) private var lineEnding
    
    @AppStorage(.encoding) private var encoding
    @AppStorage(.saveUTF8BOM) private var saveUTF8BOM
    @AppStorage(.referToEncodingTag) private var referToEncodingTag
    
    @AppStorage(.syntax) private var syntax
    
    @State private var encodingManager: EncodingManager = .shared
    @State private var syntaxNames: [String] = []
    
    
    private var fileEncoding: Binding<FileEncoding> {
        
        Binding(
            get: {
                FileEncoding(encoding: String.Encoding(rawValue: UInt(self.encoding)),
                             withUTF8BOM: self.saveUTF8BOM)
            },
            set: {
                self.encoding = Int($0.encoding.rawValue)
                self.saveUTF8BOM = $0.withUTF8BOM
            })
    }
    
    @State private var isEncodingListPresented = false
    
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                Text("Default line endings:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "lineEnding", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                Picker(selection: $lineEnding) {
                    ForEach(LineEnding.allCases.filter(\.isBasic), id: \.self) {
                        Text(verbatim: "\($0.description) (\($0.label))")
                            .tag($0.index)
                    }
                } label: {
                    EmptyView()
                }
                .fixedSize()
                .accessibilityLabeledPair(role: .content, id: "lineEnding", in: self.accessibility)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            GridRow {
                Text("Default encoding:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "fileEncoding", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                Picker(selection: self.fileEncoding) {
                    ForEach(Array(self.encodingManager.fileEncodings.enumerated()), id: \.offset) { (_, encoding) in
                        if let encoding {
                            Text(encoding.localizedName)
                                .tag(encoding)
                        } else {
                            Divider()
                        }
                    }
                } label: {
                    EmptyView()
                }
                .frame(maxWidth: 260)
                .accessibilityLabeledPair(role: .content, id: "fileEncoding", in: self.accessibility)
            }
            
            GridRow {
                Text("Priority of encodings:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "encodingPriority", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                VStack {
                    VStack(alignment: .leading) {
                        Button(String(localized: "Edit List…", table: "FormatSettings")) {
                            self.isEncodingListPresented.toggle()
                        }
                        .sheet(isPresented: $isEncodingListPresented, content: EncodingListView.init)
                        
                        Toggle(String(localized: "Refer to encoding declaration in document", table: "FormatSettings"), isOn: $referToEncodingTag)
                    }
                }
                .accessibilityLabeledPair(role: .content, id: "encodingPriority", in: self.accessibility)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            GridRow {
                Text("Default syntax:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "syntax", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                Picker(selection: $syntax) {
                    Text(String(localized: "SyntaxName.none", defaultValue: "None"))
                        .tag(SyntaxName.none)
                    
                    Divider()
                    
                    if !(self.syntaxNames + [SyntaxName.none]).contains(self.syntax) {
                        Text(self.syntax).tag(self.syntax)
                            .help(String(localized: "This syntax does not exist",
                                         table: "FormatSettings", comment: "tooltip"))
                            .foregroundStyle(.secondary)
                    }
                    
                    ForEach(self.syntaxNames, id: \.self) {
                        Text($0).tag($0)
                    }
                } label: {
                    EmptyView()
                }
                .frame(maxWidth: 260)
                .accessibilityLabeledPair(role: .content, id: "syntax", in: self.accessibility)
            }
            
            GridRow(alignment: .top) {
                Text("Available syntaxes:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "availableSyntaxes", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                SyntaxListView()
                    .background()
                    .border(.separator)
                    .frame(width: 260)
                    .accessibilityLabeledPair(role: .content, id: "availableSyntaxes", in: self.accessibility)
            }
            
            HStack {
                Spacer()
                HelpLink(anchor: "settings_format")
            }
        }
        .onReceive(SyntaxManager.shared.$settingNames) { settingNames in
            self.syntaxNames = settingNames
        }
        .padding(.top, 14)
        .scenePadding([.horizontal, .bottom])
        .frame(width: 600)
    }
}


private struct SyntaxListView: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = NSViewController
    
    
    func makeNSViewController(context: Context) -> NSViewController {
        
        NSStoryboard(name: "SyntaxListView", bundle: nil).instantiateInitialController()!
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        
    }
}


// MARK: - Preview

#Preview {
    FormatSettingsView()
}
