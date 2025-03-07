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
    
    @Environment(\.dismissWindow) private var dismiss
    
    @State private var versionString: String = "\(NewFeature.version.major).\(NewFeature.version.minor)"
    @State private var isPrerelease: Bool = false
    
    
    var body: some View {
        
        VStack(spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                Text("What’s New in CotEditor \(self.versionString)", tableName: "WhatsNew", comment: "%@ is version number")
                    .font(.title)
                    .fontWeight(.medium)
                    .accessibilityHeading(.h1)
                
                if self.isPrerelease {
                    Text("Beta", tableName: "WhatsNew", comment: "label for when the app is a prerelease version")
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .kerning(0.5)
                        .padding(.horizontal, 5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke())
                        .foregroundStyle(.tint)
                }
            }
            
            VStack(alignment: .leading, spacing: 20) {
                ForEach(NewFeature.allCases, id: \.self) { feature in
                    HStack {
                        feature.image
                            .font(.system(size: 36, weight: .thin))
                            .foregroundStyle(.tint)
                            .frame(width: 60, alignment: .center)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.label)
                                .font(.system(size: 14, weight: .semibold))
                                .accessibilityHeading(.h2)
                            
                            Text(feature.description)
                                .font(.body.leading(.tight))
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
            
            Button {
                NSHelpManager.shared.openHelpAnchor("releasenotes", inBook: Bundle.main.helpBookName)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("Complete release notes", tableName: "WhatsNew")
                    Image(systemName: "chevron.forward")
                        .imageScale(.small)
                }
            }
            .buttonStyle(.link)
            .foregroundStyle(.tint)
            
            Button {
                self.dismiss()
            } label: {
                Text("Continue", tableName: "WhatsNew")
                    .frame(minWidth: 120)
            }
            .controlSize(.large)
            .keyboardShortcut(.cancelAction)
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            if let version = Bundle.main.version, version < NewFeature.version {
                self.isPrerelease = true
            }
        }
        .padding()
        .scenePadding()
        .frame(width: 580)
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
    
    static let version = Version(5, 1, 0)
    static let buildNumber = 703
    
    case uniqueFolder
    case readOnly
    case tag
}
    

private extension NewFeature {
    
    var image: Image {
        
        switch self {
            case .uniqueFolder:
                Image(systemName: "macwindow.on.rectangle")
            case .readOnly:
                Image(systemName: "pencil.slash")
            case .tag:
                Image(systemName: "circlebadge.2")
        }
    }
    
    
    var label: String {
        
        switch self {
            case .uniqueFolder:
                String(localized: "NewFeature.uniqueFolder.label",
                       defaultValue: "Easier to Distinguish Documents", table: "WhatsNew")
            case .readOnly:
                String(localized: "NewFeature.readOnly.label",
                       defaultValue: "Read-Only Mode", table: "WhatsNew")
            case .tag:
                String(localized: "NewFeature.tag.label",
                       defaultValue: "Finder Tags", table: "WhatsNew")
        }
    }
    
    
    var description: String {
        
        switch self {
            case .uniqueFolder:
                String(localized: "NewFeature.uniqueFolder.description",
                       defaultValue: "A parent folder name appears in the window title for documents with the same filename.", table: "WhatsNew")
            case .readOnly:
                String(localized: "NewFeature.readOnly.description",
                       defaultValue: "Prevent accidental editing by making documents read-only.", table: "WhatsNew")
            case .tag:
                String(localized: "NewFeature.tag.description",
                       defaultValue: "The document inspector and the file browser now display Finder tags.", table: "WhatsNew")
        }
    }
    
    
    var helpAnchor: String? {
        
        switch self {
            case .readOnly:
                "howto_readonly"
            default:
                nil
        }
    }
    
    
    @MainActor @ViewBuilder var supplementalView: some View {
        
        switch self {
            default:
                EmptyView()
        }
    }
}


// MARK: - Private

private extension ButtonStyle where Self == CapsuleButtonStyle {
    
    static var capsule: Self  { Self() }
}


private struct CapsuleButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        
        configuration.label
            .foregroundStyle(.tint)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .padding(.vertical, 2)
            .padding(.horizontal, 9)
            .background(.fill.tertiary, in: Capsule())
    }
}


// MARK: - Preview

#Preview {
    WhatsNewView()
}
