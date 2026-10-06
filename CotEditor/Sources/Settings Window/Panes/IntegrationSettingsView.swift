//
//  IntegrationSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-03.
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
import Defaults
import RMate

struct IntegrationSettingsView: View {
    
    @AppStorage(.enablesRemoteEditing) private var enablesRemoteEditing: Bool
    @AppStorage(.remoteEditingPort) private var remoteEditingPort: Int
    
    @State private var commandLineToolStatus: CommandLineToolManager.Status = .none
    @State private var commandLineToolURL: URL?
    

    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 18) {
            GridRow {
                Text("Command-line tool:", tableName: "IntegrationSettings")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Button(.init("Learn More…", table: "IntegrationSettings", comment: "verb; button")) {
                            NSHelpManager.shared.openHelpAnchor("about_cot", inBook: nil)
                        }
                        if self.commandLineToolStatus.installed,
                           let url = self.commandLineToolURL
                        {
                            Label {
                                Text("installed at \(url, format: .url.scheme(.never))", tableName: "IntegrationSettings")
                            } icon: {
                                StatusImage(status: self.commandLineToolStatus.imageStatus)
                                    .imageScale(.small)
                                    .help(self.commandLineToolStatus.message ?? "")
                                    .accessibilityHint(self.commandLineToolStatus.message ?? "")
                            }
                            .foregroundStyle(.secondary)
                            .labelIconToTitleSpacing(6)
                        }
                    }
                    Text("With the `cot` command-line tool, you can launch CotEditor and let it open files from the command line.", tableName: "IntegrationSettings")
                        .foregroundStyle(.secondary)
                        .controlSize(.small)
                        .lineLimit(10)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            GridRow {
                Text("Remote editing:", tableName: "IntegrationSettings")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading) {
                    Toggle(.init("Accept rmate connections", table: "IntegrationSettings", comment: "verb; checkbox; rmate is a remote connection protocol"), isOn: $enablesRemoteEditing)
                    
                    HStack {
                        Text("Port:", tableName: "IntegrationSettings")
                            .foregroundStyle(self.enablesRemoteEditing ? .primary : .tertiary)
                            .accessibilityHidden(true)
                        TextField(.init("Port:", table: "IntegrationSettings"),
                                  value: $remoteEditingPort, format: .number.grouping(.never),
                                  prompt: Text(RMateServer.defaultPort, format: .number.grouping(.never)))
                        .disabled(!self.enablesRemoteEditing)
                        .labelsVisibility(.hidden)
                        .frame(width: 80)
                        
                        if let message = RemoteEditingController.shared.errorMessage {
                            Label(message, systemImage: "exclamationmark.triangle")
                                .symbolVariant(.fill)
                                .symbolRenderingMode(.multicolor)
                                .controlSize(.small)
                        }
                    }
                    .frame(minHeight: 28)
                    .padding(.leading, 20)
                    
                    let description = AttributedString(localized: "Allow remote files to be opened in CotEditor using the `rmate` protocol.",
                                                       table: "IntegrationSettings")
                        .replacingAttributes(AttributeContainer.inlinePresentationIntent(.code),
                                             with: AttributeContainer
                            .inlinePresentationIntent(.code)
                            .link(URL(string: "help:anchor=howto_edit_remote%20bookID=com.coteditor.CotEditor.help")!))
                    Text(description)
                        .foregroundStyle(.secondary)
                        .tint(.accentColor)
                        .controlSize(.small)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 20)
                }
            }
            
            HStack {
                Spacer()
                HelpLink(anchor: "settings_integration")
            }
        }
        .onAppear {
            let manager = CommandLineToolManager()
            self.commandLineToolStatus = manager.validateSymlink()
            self.commandLineToolURL = manager.linkURL
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}


private extension CommandLineToolManager.Status {
    
    var imageStatus: StatusImage.Status {
        
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
                       table: "IntegrationSettings")
            case .invalidTarget:
                String(localized: "CommandLineToolManager.Status.invalidTarget.message",
                       defaultValue: "The current `cot` symbolic link may target an invalid path.", table: "IntegrationSettings")
        }
    }
}


// MARK: - Preview

#Preview {
    IntegrationSettingsView()
        .scenePadding()
}
