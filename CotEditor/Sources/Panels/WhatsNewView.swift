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
import ControlUI
import SemanticVersioning

struct WhatsNewView: View {
    
    @Environment(\.dismissWindow) private var dismiss
    
    @State private var versionString: String = "\(NewFeature.version.major).\(NewFeature.version.minor)"
    @State private var isPrerelease: Bool = false
    
    
    var body: some View {
        
        VStack(spacing: 16) {
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
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(NewFeature.allCases, id: \.self) { feature in
                    HStack {
                        feature.image
                            .font(.system(size: 44, weight: .thin))
                            .foregroundStyle(.tint)
                            .frame(width: 60, alignment: .center)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading) {
                            Text(feature.label)
                                .font(.title3)
                                .fontWeight(.medium)
                                .accessibilityHeading(.h2)
                            
                            Text(feature.description)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(0.75)
                            
                            feature.supplementalView
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


private enum NewFeature: CaseIterable {
    
    static let version = Version(5, 0, 0)
    
    case folderNavigation
    case macOSSupport
    case writingTools
    case donation
    
#if SPARKLE
    private static let isInAppPurchaseAvailable = false
#else
    private static let isInAppPurchaseAvailable = true
#endif
    
    var image: Image {
        
        switch self {
            case .folderNavigation:
                Image(systemName: "folder")
            case .macOSSupport:
                Image(systemName: "sparkles")
            case .writingTools:
                if #available(macOS 15, *) {
                    Image(systemName: "apple.intelligence")
                } else {
                    Image(systemName: "bubble.and.pencil")
                }
            case .donation:
                Image(.bagCoffee)
        }
    }
    
    
    var label: String {
        
        switch self {
            case .folderNavigation:
                String(localized: "NewFeature.folderNavigation.label",
                       defaultValue: "Folder Navigation", table: "WhatsNew")
            case .macOSSupport:
                String(localized: "NewFeature.macOSSupport.label",
                       defaultValue: "macOS 15 Sequoia Support", table: "WhatsNew")
            case .writingTools:
                String(localized: "NewFeature.writingTools.label",
                       defaultValue: "Apple Intelligence Ready", table: "WhatsNew")
            case .donation:
                String(localized: "NewFeature.donation.label",
                       defaultValue: "Donation", table: "WhatsNew")
        }
    }
    
    
    var description: String {
        
        switch self {
            case .folderNavigation:
                String(localized: "NewFeature.folderNavigation.description",
                       defaultValue: "Open a folder in CotEditor to navigate its contents in the new sidebar.", table: "WhatsNew")
            case .macOSSupport:
                String(localized: "NewFeature.macOSSupport.description",
                       defaultValue: "Work perfectly with new macOS 15.", table: "WhatsNew")
            case .writingTools:
                String(localized: "NewFeature.writingTools.description",
                       defaultValue: "The upcoming Writing Tools powered by Apple Intelligence will work properly.", table: "WhatsNew")
            case .donation:
                String(localized: "NewFeature.donation.description",
                       defaultValue: "Support the CotEditor project by offering coffee to the developer.", table: "WhatsNew")
        }
    }
    
    
    @MainActor @ViewBuilder var supplementalView: some View {
        
        switch self {
            case .donation:
                if Self.isInAppPurchaseAvailable {
                    Button(String(localized: "Open Donation Settings", table: "WhatsNew")) {
                        SettingsWindowController.shared.openPane(.donation)
                    }
                    .buttonStyle(.capsule)
                } else {
                    Text("(Available only in the App Store version)", tableName: "WhatsNew")
                        .foregroundStyle(.secondary)
                        .controlSize(.small)
                        .fixedSize()
                }
                
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
