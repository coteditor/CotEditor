//
//  WhatsNewView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2026 1024jp
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

struct WhatsNewView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Namespace private var namespace
    
    @State private var prerelease: Version.Prerelease?
    
    
    var body: some View {
        
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text("What’s New in CotEditor \(NewFeature.version, format: .version(part: .minor))", tableName: "WhatsNew", comment: "%@ is version number")
                        .fontWeight(.bold)
                        .accessibilityHeading(.h1)
                    
                    if let prerelease = self.prerelease {
                        Text(prerelease.label)
                            .fontDesign(.rounded)
                            .kerning(0.5)
                            .padding(.horizontal, 4)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke())
                            .foregroundStyle(.tint)
                    }
                }
                .font(.system(size: 18))
                .padding(.vertical, 8)
                
                ForEach(NewFeature.allCases, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 20) {
                        feature.image
                            .font(.system(size: 28))
                            .foregroundStyle(.tint)
                            .symbolColorRenderingMode(.gradient)
                            .frame(width: 40, alignment: .center)
                            .accessibilityHidden(true)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.label)
                                .font(.system(size: 14, weight: .semibold))
                                .accessibilityHeading(.h2)
                            
                            HStack(alignment: .bottom) {
                                Text(feature.description)
                                    .font(.body)
                                    .lineSpacing(1.2)
                                    .foregroundStyle(.secondary)
                                
                                if let anchor = feature.helpAnchor {
                                    Spacer(minLength: 0)
                                    HelpLink(anchor: anchor)
                                        .controlSize(.small)
                                }
                            }
                            
                            feature.supplementalView
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(30)
            
            HStack {
                Button {
                    NSHelpManager.shared.openHelpAnchor("releasenotes", inBook: Bundle.main.helpBookName)
                } label: {
                    Text("Release Notes", tableName: "WhatsNew")
                        .frame(minWidth: 110)
                }
                .glassEffect()
                
                Spacer()
                Button {
                    self.dismiss()
                } label: {
                    Text("Continue", tableName: "WhatsNew", comment: "verb; button")
                        .frame(minWidth: 110)
                }
                .prefersDefaultFocus(in: self.namespace)
                .keyboardShortcut(.defaultAction)
                .glassEffect()
            }
            .controlSize(.extraLarge)
        }
        .onAppear {
            if let version = Bundle.main.version, version < NewFeature.version {
                self.prerelease = version.prerelease
            }
        }
        .focusScope(self.namespace)
        .scenePadding()
        .frame(width: 460)
        .background {
            Image(systemName: "gearshape.2")
                .font(.system(size: 750, weight: .ultraLight))
                .rotationEffect(.degrees(180))
                .opacity(0.025)
                .background()
                .accessibilityHidden(true)
        }
    }
}


private extension Version.Prerelease {
    
    var label: String {
        
        switch self {
            case .alpha:
                String(localized: "Version.Prerelease.alpha.label", defaultValue: "Alpha", table: "WhatsNew")
            case .beta:
                String(localized: "Version.Prerelease.beta.label", defaultValue: "Beta", table: "WhatsNew")
            case .rc:
                String(localized: "Version.Prerelease.rc.label", defaultValue: "RC", table: "WhatsNew")
            case .other(let string):
                string
        }
    }
}


enum NewFeature: CaseIterable {
    
    static let version = Version(7, 2, 0)
    static let buildNumber = 856
    
    case remoteEditing
    case copySettingsIniCloud
    case textKeyBinding
}


private extension NewFeature {
    
    var image: Image {
        
        switch self {
            case .remoteEditing:
                Image(systemName: "server.rack")
            case .copySettingsIniCloud:
                Image(systemName: "icloud.and.arrow.up")
            case .textKeyBinding:
                Image(systemName: "keyboard")
        }
    }
    
    
    var label: LocalizedStringResource {
        
        switch self {
            case .remoteEditing:
                .init("NewFeature.remoteEditing.label",
                      defaultValue: "Edit remote files right on your Mac",
                      table: "WhatsNew")
            case .copySettingsIniCloud:
                .init("NewFeature.copySettingsIniCloud.label",
                      defaultValue: "Your settings, one import away",
                      table: "WhatsNew")
            case .textKeyBinding:
                .init("NewFeature.textKeyBinding.label",
                      defaultValue: "Your keys, your rules",
                      table: "WhatsNew")
        }
    }
    
    
    var description: LocalizedStringResource {
        
        switch self {
            case .remoteEditing:
                .init("NewFeature.remoteEditing.description",
                      defaultValue: "Open files on a remote computer using `rmate` over SSH, and save your changes straight back.",
                      table: "WhatsNew")
            case .copySettingsIniCloud:
                .init("NewFeature.copySettingsIniCloud.description",
                      defaultValue: "Keep an up-to-date copy of your settings in iCloud to import on your other Macs anytime.",
                      table: "WhatsNew")
            case .textKeyBinding:
                .init("NewFeature.textKeyBinding.description",
                      defaultValue: "Customize shortcuts for moving the insertion point, selecting, and deleting text, so your fingers feel right at home.",
                      table: "WhatsNew")
        }
    }
    
    
    var helpAnchor: String? {
        
        switch self {
            case .remoteEditing:
                "howto_edit_remote"
            case .copySettingsIniCloud:
                "howto_store_settings_in_icloud"
            case .textKeyBinding:
                "settings_shortcuts"
        }
    }
    
    
    @MainActor @ContentBuilder var supplementalView: some View {
        
        switch self {
            default:
                EmptyView()
        }
    }
}


// MARK: - Preview

#Preview {
    WhatsNewView()
}
