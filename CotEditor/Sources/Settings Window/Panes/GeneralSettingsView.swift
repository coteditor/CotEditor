//
//  GeneralSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-25.
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

struct GeneralSettingsView: View {
    
#if SPARKLE
    var showsUpdaterSettings = true
#else
    var showsUpdaterSettings = false
#endif
    
    @Namespace private var accessibility
    
    @AppStorage(.quitAlwaysKeepsWindows) private var quitAlwaysKeepsWindows: Bool
    @AppStorage(.noDocumentOnLaunchOption) private var noDocumentOnLaunchOption: NoDocumentOnLaunchOption
    
    @AppStorage(.enablesAutosaveInPlace) private var enablesAutosaveInPlace: Bool
    @AppStorage(.documentConflictOption) private var documentConflictOption: DocumentConflictOption
    
    @State private var initialEnablesAutosaveInPlace: Bool = false
    
    @State private var isAutosaveChangeConfirmationPresented = false
    @State private var isWarningsSettingPresented = false
    
    @State private var commandLineToolStatus: CommandLineToolManager.Status = .none
    @State private var commandLineToolURL: URL?
    
    
    // MARK: View
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 14) {
            GridRow {
                Text("On startup:", tableName: "GeneralSettings")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(String(localized: "Reopen windows from last session", table: "GeneralSettings"), isOn: $quitAlwaysKeepsWindows)
                    
                    Text("When nothing else is open:", tableName: "GeneralSettings")
                        .accessibilityLabeledPair(role: .label, id: "noDocumentOnLaunchOption", in: self.accessibility)
                    Picker(selection: $noDocumentOnLaunchOption) {
                        ForEach(NoDocumentOnLaunchOption.allCases, id: \.self) {
                            Text($0.label)
                        }
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()
                    .accessibilityLabeledPair(role: .content, id: "noDocumentOnLaunchOption", in: self.accessibility)
                    .padding(.leading, 20)
                }
            }
            
            GridRow {
                Text("Document save:", tableName: "GeneralSettings")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading, spacing: 0) {
                    Toggle(String(localized: "Enable Auto Save with Versions", table: "GeneralSettings"), isOn: $enablesAutosaveInPlace)
                        .onChange(of: self.enablesAutosaveInPlace) { (_, newValue) in
                            if newValue != self.initialEnablesAutosaveInPlace {
                                self.isAutosaveChangeConfirmationPresented = true
                            }
                        }
                        .onAppear {
                            self.initialEnablesAutosaveInPlace = self.enablesAutosaveInPlace
                        }
                        .confirmationDialog(String(localized: "The change will be applied first on the next launch.", table: "GeneralSettings"), isPresented: $isAutosaveChangeConfirmationPresented) {
                            Button(String(localized: "Restart Now", table: "GeneralSettings", comment: "button label")) {
                                (NSApp.delegate as? AppDelegate)?.needsRelaunch = true
                                NSApp.terminate(self)
                            }
                            Button(String(localized: "Later", table: "GeneralSettings", comment: "button label")) {
                                // do nothing
                            }
                            Button("Cancel", role: .cancel) {
                                self.enablesAutosaveInPlace.toggle()
                            }
                        } message: {
                            Text("Do you want to restart CotEditor now?", tableName: "GeneralSettings")
                        }
                    
                    Text("A system feature that automatically overwrites your files while editing. Even if turned off, CotEditor covertly creates a backup in case it unexpectedly quits.", tableName: "GeneralSettings")
                        .foregroundStyle(.secondary)
                        .controlSize(.small)
                        .lineLimit(10)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 20)
                }
            }
            
            
            GridRow {
                Text("When document is changed by another application:", tableName: "GeneralSettings")
                    .accessibilityLabeledPair(role: .label, id: "documentConflictOption", in: self.accessibility)
                    .gridCellColumns(2)
            }.padding(.bottom, -8)
            
            GridRow {
                Color.clear
                    .frame(width: 1, height: 1)
                    .gridCellUnsizedAxes([.vertical, .vertical])
                    .accessibilityHidden(true)
                
                Picker(selection: $documentConflictOption) {
                    ForEach(DocumentConflictOption.allCases, id: \.self) {
                        Text($0.label)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .accessibilityLabeledPair(role: .content, id: "documentConflictOption", in: self.accessibility)
            }
            
            
            GridRow {
                Text("Dialog warnings:", tableName: "GeneralSettings")
                    .gridColumnAlignment(.trailing)
                    .accessibilityLabeledPair(role: .label, id: "dialogWarnings", in: self.accessibility)
                
                Button(String(localized: "Manage Warnings…", table: "GeneralSettings")) {
                    self.isWarningsSettingPresented.toggle()
                }
                .accessibilityLabeledPair(role: .content, id: "dialogWarnings", in: self.accessibility)
                .sheet(isPresented: $isWarningsSettingPresented, content: WarningsSettingView.init)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            GridRow {
                Text("Command-line tool:", tableName: "GeneralSettings")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Button(String(localized: "Learn More…", table: "GeneralSettings")) {
                            NSHelpManager.shared.openHelpAnchor("about_cot", inBook: nil)
                        }
                        if self.commandLineToolStatus.installed,
                           let url = self.commandLineToolURL
                        {
                            Label {
                                Text("installed at \(url, format: .url.scheme(.never))", tableName: "GeneralSettings")
                            } icon: {
                                Image(status: self.commandLineToolStatus.imageStatus)
                                    .help(self.commandLineToolStatus.message ?? "")
                            }.foregroundStyle(.secondary)
                        }
                    }
                    Text("With the `cot` command-line tool, you can launch CotEditor and let it open files from the command line.", tableName: "GeneralSettings")
                        .foregroundStyle(.secondary)
                        .controlSize(.small)
                        .lineLimit(10)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            if self.showsUpdaterSettings {
                Divider()
                    .padding(.vertical, 6)
                UpdaterView()
            }
            
            HStack {
                Spacer()
                HelpLink(anchor: "settings_general")
            }
        }
        .onAppear {
            self.commandLineToolStatus = CommandLineToolManager.shared.validateSymlink()
            self.commandLineToolURL = CommandLineToolManager.shared.linkURL
        }
        .padding(.top, 14)
        .scenePadding([.horizontal, .bottom])
        .frame(minWidth: 600, idealWidth: 600)
    }
}


private struct UpdaterView: View {
    
    @AppStorage("SUEnableAutomaticChecks") private var enableAutomaticUpdateChecks: Bool = true
    @AppStorage(.checksUpdatesForBeta) private var checksUpdatesForBeta: Bool
    
    
    var body: some View {
        
        GridRow {
            Text("Software update:", tableName: "GeneralSettings")
                .gridColumnAlignment(.trailing)
            
            VStack(alignment: .leading, spacing: 6) {
                Toggle(String(localized: "Check for updates automatically", table: "GeneralSettings"), isOn: $enableAutomaticUpdateChecks)
                
                VStack(alignment: .leading, spacing: 2) {
                    Toggle(String(localized: "Update to prereleases when available", table: "GeneralSettings"), isOn: $checksUpdatesForBeta)
                    
                    if Bundle.main.version!.isPrerelease {
                        Text("Regardless of this setting, new prereleases are always included while using a prerelease.", tableName: "GeneralSettings")
                            .foregroundStyle(.secondary)
                            .controlSize(.small)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 20)
                    }
                }
            }
        }
    }
}


private struct WarningsSettingView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(.suppressesInconsistentLineEndingAlert) private var suppressesInconsistentLineEndingAlert: Bool
    
    
    var body: some View {
        
        VStack {
            Form {
                Text("Suppress following warnings:", tableName: "GeneralSettings")
                Toggle(String(localized: "Inconsistent line endings", table: "GeneralSettings"), isOn: $suppressesInconsistentLineEndingAlert)
            }
            
            HStack {
                HelpLink(anchor: "howto_manage_warnings")
                Spacer()
                Button(String(localized: "Done", table: "GeneralSettings", comment: "button label")) {
                    self.dismiss()
                }.keyboardShortcut(.defaultAction)
            }.padding(.top)
        }
        .fixedSize()
        .scenePadding()
    }
}


private extension CommandLineToolManager.Status {
    
    var imageStatus: Image.Status {
        
        switch self {
            case .none: .none
            case .validTarget: .available
            case .differentTarget: .partiallyAvailable
            case .invalidTarget: .unavailable
        }
    }
    
    
    var message: String? {
        
        switch self {
            case .none, .validTarget:
                nil
            case .differentTarget:
                String(localized: "CommandLineToolManager.Status.differentTarget.message",
                       defaultValue: "The current `cot` symbolic link doesn’t target the running CotEditor.",
                       table: "GeneralSettings")
            case .invalidTarget:
                String(localized: "CommandLineToolManager.Status.invalidTarget.message",
                       defaultValue: "The current `cot` symbolic link may target an invalid path.", table: "GeneralSettings")
        }
    }
}


private extension NoDocumentOnLaunchOption {
    
    var label: String {
        
        switch self {
            case .untitledDocument:
                String(localized: "NoDocumentOnLaunchOption.untitledDocument.label",
                       defaultValue: "Create New Document",
                       table: "GeneralSettings")
            case .openPanel:
                String(localized: "NoDocumentOnLaunchOption.openPanel.label",
                       defaultValue: "Show Open Dialog",
                       table: "GeneralSettings")
            case .none:
                String(localized: "NoDocumentOnLaunchOption.none.label",
                       defaultValue: "Do Nothing",
                       table: "GeneralSettings")
        }
    }
}


private extension DocumentConflictOption {
    
    var label: String {
        
        switch self {
            case .ignore:
                String(localized: "DocumentConflictOption.ignore.label",
                       defaultValue: "Keep CotEditor’s edition",
                       table: "GeneralSettings")
            case .notify:
                String(localized: "DocumentConflictOption.notify.label",
                       defaultValue: "Ask how to resolve",
                       table: "GeneralSettings")
            case .revert:
                String(localized: "DocumentConflictOption.revert.label",
                       defaultValue: "Update to modified edition",
                       table: "GeneralSettings")
        }
    }
}


// MARK: - Preview

#Preview {
    GeneralSettingsView(showsUpdaterSettings: false)
}

#Preview("with Sparkle") {
    GeneralSettingsView(showsUpdaterSettings: true)
}
