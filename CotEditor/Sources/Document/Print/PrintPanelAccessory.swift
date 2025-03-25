//
//  PrintPanelAccessory.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-08-13.
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
import Combine

final class PrintSettingsModel: NSObject, PrintAccessoryModel {
    
    @Published @objc dynamic var fontSize: Double = 12.0
    @Published @objc dynamic var theme: String = ThemeName.blackAndWhite
    @Published @objc dynamic var printsBackground: Bool = true
    @Published @objc dynamic var printsLineNumbers: Bool = true
    @Published @objc dynamic var printsInvisibles: Bool = true
    
    @Published @objc dynamic var printsHeaderAndFooter: Bool = true
    
    @Published @objc dynamic var primaryHeaderContent: PrintInfoType = .documentName
    @Published @objc dynamic var primaryHeaderAlignment: AlignmentType = .left
    @Published @objc dynamic var secondaryHeaderContent: PrintInfoType = .printDate
    @Published @objc dynamic var secondaryHeaderAlignment: AlignmentType = .right
    
    @Published @objc dynamic var primaryFooterContent: PrintInfoType = .pageNumber
    @Published @objc dynamic var primaryFooterAlignment: AlignmentType = .center
    @Published @objc dynamic var secondaryFooterContent: PrintInfoType = .none
    @Published @objc dynamic var secondaryFooterAlignment: AlignmentType = .right
    
    
    // MARK: PrintAccessoryModel Methods
    
    static let printAccessoryValueKeyPaths = [
        
        #keyPath(fontSize),
        #keyPath(theme),
        #keyPath(printsBackground),
        #keyPath(printsLineNumbers),
        #keyPath(printsInvisibles),
        #keyPath(printsHeaderAndFooter),
        #keyPath(primaryHeaderContent),
        #keyPath(primaryHeaderAlignment),
        #keyPath(secondaryHeaderContent),
        #keyPath(secondaryHeaderAlignment),
        #keyPath(primaryFooterContent),
        #keyPath(primaryFooterAlignment),
        #keyPath(secondaryFooterContent),
        #keyPath(secondaryFooterAlignment),
    ]
    
    
    static func label(for keyPath: String) -> String {
        
        switch keyPath {
            case #keyPath(fontSize): String(localized: "Font Size", table: "PrintPanelAccessory")
            case #keyPath(theme): String(localized: "Color", table: "PrintPanelAccessory")
            case #keyPath(printsBackground): String(localized: "Prints Background", table: "PrintPanelAccessory")
            case #keyPath(printsLineNumbers): String(localized: "Line Number", table: "PrintPanelAccessory")
            case #keyPath(printsInvisibles): String(localized: "Invisibles", table: "PrintPanelAccessory")
            default: ""
        }
    }
    
    
    func valueDescription(for keyPath: String) -> String? {
        
        switch keyPath {
            case #keyPath(fontSize):
                String(localized: "\(Double(self.fontSize).formatted(.number.precision(.fractionLength(0...1)))) pt", table: "PrintPanelAccessory")
                
            case #keyPath(theme):
                self.theme
                
            case #keyPath(printsBackground):
                self.printsBackground ? String(localized: "On", table: "PrintPanelAccessory") : nil
                
            case #keyPath(printsLineNumbers):
                self.printsLineNumbers ? String(localized: "On", table: "PrintPanelAccessory") : nil
                
            case #keyPath(printsInvisibles):
                self.printsInvisibles ? String(localized: "On", table: "PrintPanelAccessory") : nil
                
            default:
                ""
        }
    }
}


struct PrintPanelAccessory: View {
    
    @ObservedObject var model: PrintSettingsModel
    
    
    var body: some View {
        
        Form {
            LabeledContent(String(localized: "Font Size", table: "PrintPanelAccessory")) {
                Stepper(String(localized: "Font Size", table: "PrintPanelAccessory"), value: $model.fontSize, in: 1...100, format: .number.precision(.fractionLength(0...1)))
                    .monospacedDigit()
                    .labelsHidden()
                Text("pt", tableName: "PrintPanelAccessory")
                    .foregroundColor(.primary)
            }
            
            Picker(String(localized: "Color", table: "PrintPanelAccessory"), selection: $model.theme) {
                Text(ThemeName.blackAndWhite)
                    .tag(ThemeName.blackAndWhite)
                Section(String(localized: "Theme", table: "PrintPanelAccessory")) {
                    ForEach(ThemeManager.shared.settingNames, id: \.self) { name in
                        Text(name)
                            .tag(name)
                    }
                }
            }
            
            Toggle(String(localized: "Print Backgrounds", table: "PrintPanelAccessory"),
                   isOn: $model.printsBackground)
                .padding(.leading)
            
            Toggle(String(localized: "Print Line Numbers", table: "PrintPanelAccessory"),
                   isOn: $model.printsLineNumbers)
            
            Toggle(String(localized: "Print Invisibles", table: "PrintPanelAccessory"),
                   isOn: $model.printsInvisibles)
            
            Toggle(String(localized: "Print Headers and Footers", table: "PrintPanelAccessory"),
                   isOn: $model.printsHeaderAndFooter.animation())
            
            if self.model.printsHeaderAndFooter {
                LabeledContent(String(localized: "Header", table: "PrintPanelAccessory")) {
                    VStack(alignment: .trailing) {
                        HeaderFooterItemView(content: $model.primaryHeaderContent,
                                             alignment: $model.primaryHeaderAlignment)
                        HeaderFooterItemView(content: $model.secondaryHeaderContent,
                                             alignment: $model.secondaryHeaderAlignment)
                    }.labelsHidden()
                }.padding(.leading)
                
                LabeledContent(String(localized: "Footer", table: "PrintPanelAccessory")) {
                    VStack(alignment: .trailing) {
                        HeaderFooterItemView(content: $model.primaryFooterContent,
                                             alignment: $model.primaryFooterAlignment)
                        HeaderFooterItemView(content: $model.secondaryFooterContent,
                                             alignment: $model.secondaryFooterAlignment)
                    }.labelsHidden()
                }.padding(.leading)
            }
        }
        .formStyle(.grouped)
    }
}


private struct HeaderFooterItemView: View {
    
    @Binding var content: PrintInfoType
    @Binding var alignment: AlignmentType
    
    
    var body: some View {
        
        HStack {
            Picker(String(localized: "Content", table: "PrintPanelAccessory"), selection: $content) {
                ForEach(PrintInfoType.allCases, id: \.self) { type in
                    Text(type.label)
                    
                    if type == .none {
                        Divider()
                    }
                }
            }
            .pickerStyle(.menu)
            
            Picker(String(localized: "Alignment", table: "PrintPanelAccessory"), selection: $alignment) {
                ForEach(AlignmentType.allCases, id: \.self) { type in
                    Image(systemName: type.symbolName)
                        .accessibilityLabel(type.label)
                        .help(type.label)
                }
            }
            .disabled(self.content == .none)
            .pickerStyle(.segmented)
        }
    }
}


// MARK: Private Extensions

private extension PrintInfoType {
    
    var label: String {
        
        switch self {
            case .none:
                String(localized: "PrintInfoType.none.label",
                       defaultValue: "None",
                       table: "PrintPanelAccessory")
            case .syntaxName:
                String(localized: "PrintInfoType.syntaxName.label",
                       defaultValue: "Syntax Name",
                       table: "PrintPanelAccessory")
            case .documentName:
                String(localized: "PrintInfoType.documentName.label",
                       defaultValue: "Document Name",
                       table: "PrintPanelAccessory")
            case .filePath:
                String(localized: "PrintInfoType.filePath.label",
                       defaultValue: "File Path",
                       table: "PrintPanelAccessory")
            case .printDate:
                String(localized: "PrintInfoType.printDate.label",
                       defaultValue: "Print Date",
                       table: "PrintPanelAccessory")
            case .lastModifiedDate:
                String(localized: "PrintInfoType.lastModifiedDate.label",
                       defaultValue: "Last Modified Date",
                       table: "PrintPanelAccessory")
            case .pageNumber:
                String(localized: "PrintInfoType.pageNumber.label",
                       defaultValue: "Page Number",
                       table: "PrintPanelAccessory")
        }
    }
}


private extension AlignmentType {
    
    var label: String {
        
        switch self {
            case .left:
                String(localized: "AlignmentType.left.label",
                       defaultValue: "Align Left",
                       table: "PrintPanelAccessory")
            case .center:
                String(localized: "AlignmentType.center.label",
                       defaultValue: "Center",
                       table: "PrintPanelAccessory")
            case .right:
                String(localized: "AlignmentType.right.label",
                       defaultValue: "Align Right",
                       table: "PrintPanelAccessory")
        }
    }
    
    
    var symbolName: String {
        
        switch self {
            case .left: "arrow.left.to.line"
            case .center: "arrow.right.and.line.vertical.and.arrow.left"
            case .right: "arrow.right.to.line"
        }
    }
}


// MARK: - Preview

#Preview {
    PrintPanelAccessory(model: .init())
        .formStyle(.grouped)
        .frame(width: 400)
}
