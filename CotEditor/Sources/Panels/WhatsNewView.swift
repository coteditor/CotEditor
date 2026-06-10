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
import AppKit
import SemanticVersioning

struct WhatsNewView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Namespace private var namespace
    @FocusState private var isContinueButtonFocused: Bool
    
    @State private var isPrerelease: Bool = false
    
    
    var body: some View {
        
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text("What’s New in CotEditor \(NewFeature.version, format: .version(part: .minor))", tableName: "WhatsNew", comment: "%@ is version number")
                        .fontWeight(.bold)
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
                .padding(.vertical, 8)
                
                ForEach(NewFeature.allCases, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 20) {
                        feature.image
                            .font(.system(size: 28))
                            .foregroundStyle(.tint)
                            .symbolColorRenderingMode(.gradient)
                            .frame(width: 40, alignment: .center)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.label)
                                .font(.system(size: 14, weight: .semibold))
                                .accessibilityHeading(.h2)
                            
                            HStack(alignment: .bottom) {
                                Text(feature.description)
                                    .font(.body)
                                    .lineSpacing(1.2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundStyle(.secondary)
                                
                                if let anchor = feature.helpAnchor {
                                    Spacer(minLength: 0)
                                    HelpLink(anchor: anchor)
                                        .controlSize(.small)
                                }
                            }
                            
                            feature.supplementalView
                        }
                    }
                }
            }
            .padding(30)
            
            HStack {
                Button {
                    NSHelpManager.shared.openHelpAnchor("releasenotes", inBook: Bundle.main.helpBookName)
                } label: {
                    Text("Release Notes", tableName: "WhatsNew")
                        .frame(minWidth: 100)
                }
                .glassEffect()
                
                Spacer()
                Button {
                    self.dismiss()
                } label: {
                    Text("Continue", tableName: "WhatsNew")
                        .frame(minWidth: 100)
                }
                .focused($isContinueButtonFocused)  // workaround: .prefersDefaultFocus(in:) doesn't work (2026-01, macOS 26).
                .prefersDefaultFocus(true, in: self.namespace)
                .keyboardShortcut(.defaultAction)
                .glassEffect()
            }
            .controlSize(.extraLarge)
        }
        .onAppear {
            self.isContinueButtonFocused = true
            if let version = Bundle.main.version, version < NewFeature.version {
                self.isPrerelease = true
            }
        }
        .focusScope(self.namespace)
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
    
    static let version = Version(7, 1, 0)
    static let buildNumber = 830
    
    case folderFind
    case folderNavigationHistory
    case macOS27
    case documentName
}


private extension NewFeature {
    
    var image: Image {
        
        switch self {
            case .folderFind:
                Image(.folderBadgeMagnifyingglass)
            case .folderNavigationHistory:
                Image(systemName: "chevron.left.chevron.right")
            case .macOS27:
                Image(systemName: "finder")
            case .documentName:
                Image(systemName: "rectangle.and.pencil.and.ellipsis")
        }
    }
    
    
    var label: String {
        
        switch self {
            case .folderFind:
                String(localized: "NewFeature.folderFind.label",
                       defaultValue: "Folder search",
                       table: "WhatsNew")
            case .folderNavigationHistory:
                String(localized: "NewFeature.folderNavigationHistory.label",
                       defaultValue: "Folder navigation history",
                       table: "WhatsNew")
            case .macOS27:
                String(localized: "NewFeature.macOS27.label",
                       defaultValue: "macOS 27 Golden Gate support",
                       table: "WhatsNew")
            case .documentName:
                String(localized: "NewFeature.documentName.label",
                       defaultValue: "Document name suggestion",
                       table: "WhatsNew")
        }
    }
    
    
    var description: String {
        
        switch self {
            case .folderFind:
                String(localized: "NewFeature.folderFind.description",
                       defaultValue: "n/a",
                       table: "WhatsNew")
            case .folderNavigationHistory:
                String(localized: "NewFeature.folderNavigationHistory.description",
                       defaultValue: "n/a",
                       table: "WhatsNew")
            case .macOS27:
                String(localized: "NewFeature.macOS27.description",
                       defaultValue: "n/a",
                       table: "WhatsNew")
            case .documentName:
                String(localized: "NewFeature.documentName.description",
                       defaultValue: "n/a",
                       table: "WhatsNew")
        }
    }
    
    
    var helpAnchor: String? {
        
        switch self {
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


// MARK: - Preview

#Preview {
    WhatsNewView()
}
