//
//  SettingsPortViews.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2025-2026 1024jp
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
import SemanticVersioning

struct ExportSettingsView: View {
    
    typealias Types = PortableSettingsDocument.SettingTypes
    
    var includedTypes: [Types: [String]]
    
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var types: Types = .all
    @State private var isFileExporterPresented = false
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Export Settings", tableName: "SettingsPorting")
                    .font(.system(size: 14, weight: .semibold))
                Text("Export selected settings as an archive to allow importing into other computers.", tableName: "SettingsPorting")
            }
            .padding(.bottom, 12)
            
            PortableTypesView(types: $types, includedTypes: self.includedTypes)
            
            HStack {
                HelpLink(anchor: "howto_port_settings")
                Spacer()
                
                SubmitButtonGroup(String(localized: "Action.export.label", defaultValue: "Export…")) {
                    self.isFileExporterPresented = true
                } cancelAction: {
                    self.dismiss()
                }
                .disabled(self.types.isEmpty)
            }
            .padding(.top)
        }
        .fileExporter(isPresented: $isFileExporterPresented, document: try? PortableSettingsDocument(including: self.types), contentTypes: [.cotSettings], defaultFilename: nil) { _ in
            self.dismiss()
        } onCancellation: {
            self.dismiss()
        }
        .scenePadding()
        .frame(width: 380)
    }
}


struct ImportSettingsView: View {
    
    typealias Types = PortableSettingsDocument.SettingTypes
    
    var name: String
    var document: PortableSettingsDocument
    
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var types: Types = .all
    @State private var documentError: PortableSettingsDocument.Error?
    @State private var error: (any Error)?
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text(self.name)
                .font(.system(size: 14, weight: .semibold))
            
            if let documentError {
                DocumentErrorView(error: documentError)
                    .padding(.bottom, 8)
            }
            
            Text("Select the items to import:", tableName: "SettingsPorting")
            PortableTypesView(types: $types, includedTypes: self.document.bundledSettings)
            
            HStack {
                HelpLink(anchor: "howto_port_settings")
                Spacer()
                
                SubmitButtonGroup(String(localized: "Action.import.label", defaultValue: "Import…")) {
                    do {
                        try self.document.applySettings(types: self.types)
                    } catch {
                        self.error = error
                        return
                    }
                    self.dismiss()
                } cancelAction: {
                    self.dismiss()
                }
                .disabled(self.types.isEmpty)
            }
            .padding(.top)
        }
        .onAppear {
            self.documentError = nil
            do throws(PortableSettingsDocument.Error) {
                try self.document.checkVersion()
            } catch {
                self.documentError = error
            }
        }
        .alert(error: $error)
        .scenePadding()
        .frame(width: 380)
    }
    
    
    private struct DocumentErrorView: View {
        
        var error: PortableSettingsDocument.Error
        
        
        var body: some View {
            
            Label {
                if let recoverySuggestion = self.error.recoverySuggestion {
                    Text(self.error.localizedDescription + " " + recoverySuggestion)
                } else {
                    Text(self.error.localizedDescription)
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
            .symbolRenderingMode(.multicolor)
            .fixedSize(horizontal: false, vertical: true)
            .controlSize(.small)
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 7)
                .fill(.yellow.opacity(0.05))
                .stroke(.yellow)
            )
        }
    }
}


private struct PortableTypesView: View {
    
    typealias Types = PortableSettingsDocument.SettingTypes
    
    @Binding var types: Types
    
    var includedTypes: [Types: [String]]
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $types.bind(.settings)) {
                Text(String(localized: "SettingTypes.settings.label", defaultValue: "Settings", table: "SettingsPorting"))
                Text(String(localized: "SettingTypes.settings.description", defaultValue: "All settings in the Settings window", table: "SettingsPorting"))
            }
            
            if let names = self.includedTypes[.themes], !names.isEmpty {
                Toggle(isOn: $types.bind(.themes)) {
                    Text(String(localized: "SettingTypes.themes.label", defaultValue: "Themes", table: "SettingsPorting"))
                    Text("\(names.count) custom themes", tableName: "SettingsPorting")
                }
            }
            
            if let names = self.includedTypes[.syntaxes], !names.isEmpty {
                Toggle(isOn: $types.bind(.syntaxes)) {
                    Text(String(localized: "SettingTypes.syntaxes.label", defaultValue: "Syntaxes", table: "SettingsPorting"))
                    Text("\(names.count) custom syntaxes", tableName: "SettingsPorting")
                }
            }
            
            if let names = self.includedTypes[.replacements], !names.isEmpty {
                Toggle(isOn: $types.bind(.replacements)) {
                    Text(String(localized: "SettingTypes.replacements.label", defaultValue: "Multiple Replace Definitions", table: "SettingsPorting"))
                    Text("\(names.count) definitions", tableName: "SettingsPorting",
                         comment: "unit for multiple replace settings")
                }
            }
        }
        .monospacedDigit()
    }
}


extension PortableSettingsDocument.Error: LocalizedError {
    
    var localizedDescription: String {
        
        switch self {
            case .versionMismatch(let version):
                String(localized: "Error.versionMismatch.description",
                       defaultValue: "This settings archive was created by a different version of CotEditor (\(version, format: .version)).",
                       table: "SettingsPorting")
        }
    }
    
    var recoverySuggestion: String? {
        
        switch self {
            case .versionMismatch:
                String(localized: "Error.versionMismatch.recoverySuggestion",
                       defaultValue: "You can still import these items, but some settings may be incompatible.",
                       table: "SettingsPorting")
        }
    }
}


// MARK: - Preview

#Preview("Export Settings") {
    ExportSettingsView(includedTypes: PortableSettingsDocument.exportableSettings)
}

#Preview("Import Settings") {
    var document = try! PortableSettingsDocument(including: .all)
    document.info.version = Version(6, 0, 0)
    
    return ImportSettingsView(name: "Untitled", document: document)
}
