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
//  © 2024-2025 1024jp
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
import AppKit
import SemanticVersioning

struct WhatsNewView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPrerelease: Bool = false
    
    
    var body: some View {
        
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text("What’s New in CotEditor \(NewFeature.version, format: .version(part: .minor))", tableName: "WhatsNew", comment: "%@ is version number")
                        .fontWeight(.semibold)
                        .accessibilityHeading(.h1)
                    
                    if self.isPrerelease {
                        Text("Beta", tableName: "WhatsNew", comment: "label for when the app is a prerelease version")
                            .fontDesign(.rounded)
                            .kerning(0.5)
                            .padding(.horizontal, 4)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke())
                            .foregroundStyle(.tint)
                    }
                }
                .font(.system(size: 18))
                
                ForEach(NewFeature.allCases, id: \.self) { feature in
                    HStack {
                        feature.image
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(.tint)
                            .modifier { content in
                                if #available(macOS 26, *) {
                                    content
                                        .symbolColorRenderingMode(.gradient)
                                } else {
                                    content
                                }
                            }
                            .frame(width: 60, alignment: .center)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.label)
                                .font(.system(size: 14, weight: .semibold))
                                .accessibilityHeading(.h2)
                            
                            Text(feature.description)
                                .font(.body)
                                .lineSpacing(1.2)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundStyle(.secondary)
                            
                            feature.supplementalView
                        }
                        
                        if let anchor = feature.helpAnchor {
                            Spacer()
                            VStack {
                                Spacer()
                                HelpLink(anchor: anchor)
                                    .controlSize(.small)
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.vertical)
            
            HStack {
                Button {
                    NSHelpManager.shared.openHelpAnchor("releasenotes", inBook: Bundle.main.helpBookName)
                } label: {
                    Text("Release Notes", tableName: "WhatsNew")
                        .frame(minWidth: 120)
                }
                Spacer()
                Button {
                    self.dismiss()
                } label: {
                    Text("Continue", tableName: "WhatsNew")
                        .frame(minWidth: 120)
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
        .onAppear {
            if let version = Bundle.main.version, version < NewFeature.version {
                self.isPrerelease = true
            }
        }
        .scenePadding()
        .frame(width: 480)
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


enum NewFeature: CaseIterable {
    
    static let version = Version(6, 2, 0)
    static let buildNumber = 772
    
    case settingPorting
    case alias
    case userGuide
}
    

private extension NewFeature {
    
    var image: Image {
        
        switch self {
            case .settingPorting:
                Image(systemName: "truck.box")
            case .alias:
                Image(systemName: "arrowshape.turn.up.forward.fill")
            case .userGuide:
                Image(systemName: "book.closed")
        }
    }
    
    
    var label: String {
        
        switch self {
            case .settingPorting:
                String(localized: "NewFeature.settingPorting.label",
                       defaultValue: "Assist your migration", table: "WhatsNew")
            case .alias:
                String(localized: "NewFeature.alias.label",
                       defaultValue: "Easier access to aliases", table: "WhatsNew")
            case .userGuide:
                String(localized: "NewFeature.userGuide.label",
                       defaultValue: "Your built-in guide, newly polished", table: "WhatsNew")
        }
    }
    
    
    var description: String {
        
        switch self {
            case .settingPorting:
                String(localized: "NewFeature.settingPorting.description",
                       defaultValue: "Export and import all your CotEditor settings, custom syntaxes, themes, and multiple replacement definitions from the File menu to easily move your environment to another Mac.", table: "WhatsNew")
            case .alias:
                String(localized: "NewFeature.alias.description",
                       defaultValue: "The original documents behind aliases and symlinks can now be opened directly in the current window from the file browser.", table: "WhatsNew")
            case .userGuide:
                String(localized: "NewFeature.userGuide.description",
                       defaultValue: "The built-in user guide now offers clearer explanations, richer content, and a refreshed layout aligned with the latest macOS.", table: "WhatsNew")
        }
    }
    
    
    var helpAnchor: String? {
        
        switch self {
            case .settingPorting:
                "howto_port_settings"
            default:
                nil
        }
    }
    
    
    @ViewBuilder var supplementalView: some View {
        
        switch self {
            case .alias:
                Text(String(localized: "NewFeature.alias.supplement",
                            defaultValue: "*If the original is a folder, it will open in a new window.", table: "WhatsNew"))
                .foregroundStyle(.secondary)
                .controlSize(.small)
                .padding(.top, 2)
            default:
                EmptyView()
        }
    }
}


// MARK: - Preview

#Preview {
    WhatsNewView()
}
