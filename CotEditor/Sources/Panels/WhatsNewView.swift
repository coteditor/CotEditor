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
                        .fontWeight(isLiquidGlass ? .bold : .semibold)
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
                    HStack(alignment: .top) {
                        feature.image
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(.tint)
                            .modifier { content in
                                if #available(macOS 26, *) {
                                    content
                                        .symbolColorRenderingMode(.gradient)
                                } else {
                                    content
                                }
                            }
                            .frame(width: 52, alignment: .center)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 4) {
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
            .padding(30)
            
            HStack {
                Button {
                    NSHelpManager.shared.openHelpAnchor("releasenotes", inBook: Bundle.main.helpBookName)
                } label: {
                    Text("Release Notes", tableName: "WhatsNew")
                        .frame(minWidth: 120)
                }
                .modifier { content in
                    if #available(macOS 26, *) {
                        content
                            .glassEffect()
                    } else {
                        content
                    }
                }
                
                Spacer()
                Button {
                    self.dismiss()
                } label: {
                    Text("Continue", tableName: "WhatsNew")
                        .frame(minWidth: 120)
                }
                .focused($isContinueButtonFocused)  // workaround: .prefersDefaultFocus(in:) doesn't work (2026-01, macOS 26).
                .prefersDefaultFocus(true, in: self.namespace)
                .keyboardShortcut(.defaultAction)
                .modifier { content in
                    if #available(macOS 26, *) {
                        content
                            .glassEffect()
                    } else {
                        content
                    }
                }
            }
            .controlSize(isLiquidGlass ? .extraLarge : .large)
        }
        .onAppear {
            self.isContinueButtonFocused = true
            if let version = Bundle.main.version, version < NewFeature.version {
                self.isPrerelease = true
            }
        }
        .onExitCommand {  // close window with the Esc key
            self.dismiss()
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
    
    static let version = Version(7, 0, 0)
    static let buildNumber = 801
    
    case syntax
    case treeSitter
    case outline
}
    

private extension NewFeature {
    
    var image: Image {
        
        switch self {
            case .syntax:
                Image(systemName: "curlybraces")
            case .treeSitter:
                Image(systemName: "tree")
            case .outline:
                Image(systemName: "list.bullet.indent")
        }
    }
    
    
    var label: String {
        
        switch self {
            case .syntax:
                String(localized: "NewFeature.syntax.label",
                       defaultValue: "Smarter syntax, sharper editing",
                       table: "WhatsNew")
            case .treeSitter:
                String(localized: "NewFeature.treeSitter.label",
                       defaultValue: "Powered by tree-sitter, where it matters most",
                       table: "WhatsNew")
            case .outline:
                String(localized: "NewFeature.outline.label",
                       defaultValue: "Outline with depth",
                       table: "WhatsNew")
        }
    }
    
    
    var description: String {
        
        switch self {
            case .syntax:
                String(localized: "NewFeature.syntax.description",
                       defaultValue: "More accurate highlighting, smarter commenting, and improved indentation behavior — powered by a redesigned syntax engine and definition format.",
                       table: "WhatsNew")
            case .treeSitter:
                String(localized: "NewFeature.treeSitter.description",
                       defaultValue: "Several built-in syntaxes now use tree-sitter — a modern, structure-based parser — enabling deeper and more reliable language awareness.",
                       table: "WhatsNew")
            case .outline:
                String(localized: "NewFeature.outline.description",
                       defaultValue: "Icons make structure easier to scan, and tree-sitter–based syntaxes now support collapsible outlines that reflect hierarchy.",
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
            case .syntax:
                let count = SyntaxManager.shared.migratedSyntaxCount
                if count > 0 {
                    MigrationReportView(count: count)
                        .padding(.top, 6)
                }
            default:
                EmptyView()
        }
    }
}


private struct MigrationReportView: View {
    
    var count: Int
    
    @State private var isVisible: Bool = false
    
    
    var body: some View {
        
        Label {
            Text(self.message)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(self.isVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.2).delay(0.1), value: self.isVisible)
        } icon: {
            Image(systemName: "checkmark")
                .symbolRenderingMode(.hierarchical)
                .symbolVariant(.circle)
                .modifier { content in
                    if #available(macOS 26, *) {
                        content
                            .symbolEffect(.drawOn, isActive: !self.isVisible)
                    } else {
                        content
                            .symbolEffect(.bounce, value: self.isVisible)
                    }
                }
                .imageScale(.large)
                .foregroundStyle(.accent)
        }
        .task {
            try? await Task.sleep(for: .seconds(0.5))
            self.isVisible = true
        }
    }
    
    
    private var message: String {
        
        String(localized: "NewFeature.syntax.supplementalView.message",
               defaultValue: "Migrated \(self.count) custom syntaxes to the new format.",
               table: "WhatsNew",
               comment: "%lld is the number of syntaxes")
    }
}


// MARK: - Preview

#Preview {
    WhatsNewView()
}
