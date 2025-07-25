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
    
    private var versionString: String = "\(NewFeature.version.major).\(NewFeature.version.minor)"
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
    
    static let version = Version(6, 0, 0)
    static let buildNumber = 720
    
    case liquidGlass
}
    

private extension NewFeature {
    
    var image: Image {
        
        switch self {
            case .liquidGlass:
                Image(systemName: "sparkles")
        }
    }
    
    
    var label: String {
        
        switch self {
            case .liquidGlass:
                String(localized: "NewFeature.liquidGlass.label",
                       defaultValue: "Liquid Glass Look", table: "WhatsNew")
        }
    }
    
    
    var description: String {
        
        switch self {
            case .liquidGlass:
                String(localized: "NewFeature.liquidGlass.description",
                       defaultValue: "Experience the refreshed interface with the new Liquid Glass style in macOS 26 Tahoe.", table: "WhatsNew")
        }
    }
    
    
    var helpAnchor: String? {
        
        switch self {
            default:
                nil
        }
    }
    
    
    @ViewBuilder var supplementalView: some View {
        
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
