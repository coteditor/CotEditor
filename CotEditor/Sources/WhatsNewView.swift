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
//  © 2024 1024jp
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

struct WhatsNewView: View {
    
    @Environment(\.dismissWindow) private var dismiss
    
    
    var body: some View {
        
        VStack {
            Text("What’s New in **CotEditor \(NewFeature.version)**", tableName: "WhatsNew", comment: "%@ is version number")
                .font(.title)
                .fontWeight(.medium)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)
            
            HStack(alignment: .top, spacing: 20) {
                ForEach(NewFeature.allCases, id: \.self) { feature in
                    VStack {
                        feature.image
                            .font(.system(size: 56, weight: .thin))
                            .foregroundStyle(.tint)
                            .frame(height: 60)
                        
                        Text(feature.label)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h2)
                            .padding(.vertical, 2)
                        
                        Text(feature.description)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        feature.supplementalView
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                }
            }.padding(.vertical)
            
            Spacer()
            
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
            .padding(.top, 6)
        }
        .scenePadding()
        .frame(width: 640, height: 300)
        .padding(.top, 30)  // for balancing with window titlebar space
        .ignoresSafeArea()
        .background()
    }
}


private struct SectionView<Content: View>: View {
    
    var title: String
    var image: Image
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        
        VStack {
            self.image
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(.tint)
                .frame(height: 64)
            
            Text(self.title)
                .font(.title3)
                .fontWeight(.medium)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
                .padding(.vertical, 2)
            
            self.content()
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


private enum NewFeature: CaseIterable {
    
    static let version = "4.9"
    
    case macOSSupport
    case donation
    
    
    var image: Image {
        
        switch self {
            case .macOSSupport:
                Image(systemName: "sparkles")
            case .donation:
                Image(.bagCoffee)
        }
    }
    
    
    var label: String {
        
        switch self {
            case .macOSSupport:
                String(localized: "NewFeature.macOSSupport.label",
                       defaultValue: "macOS 15 Support", table: "WhatsNew")
            case .donation:
                String(localized: "NewFeature.donation.label",
                       defaultValue: "Donation", table: "WhatsNew")
        }
    }
    
    
    var description: String {
        
        switch self {
            case .macOSSupport:
                String(localized: "NewFeature.macOSSupport.description",
                       defaultValue: "Work perfectly with new macOS 15.", table: "WhatsNew")
            case .donation:
                String(localized: "NewFeature.donation.description",
                       defaultValue: "Support the CotEditor project by offering coffee to the developer.", table: "WhatsNew")
        }
    }
    
    
    @ViewBuilder var supplementalView: some View {
        
        switch self {
            case .donation:
                #if SPARKLE
                Text("(Available only in the App Store version)", tableName: "WhatsNew")
                    .foregroundStyle(.secondary)
                    .controlSize(.small)
                    .fixedSize()
                #else
                Button(String(localized: "Open Donation Settings", table: "WhatsNew")) {
                    Task { @MainActor in
                        SettingsWindowController.shared.openPane(.donation)
                    }
                }
                .buttonStyle(.capsule)
                #endif
            default:
                EmptyView()
        }
    }
}



// MARK: - Preview

#Preview {
    WhatsNewView()
}
