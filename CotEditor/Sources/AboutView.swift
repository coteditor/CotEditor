//
//  AboutView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-03-15.
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
import AppKit.NSApplication

struct AboutView: View {
    
    var body: some View {
        
        HStack {
            VStack(spacing: 6) {
                Image(nsImage: NSApp.applicationIconImage)
                Text(Bundle.main.bundleName)
                    .font(.title)
                Text("Version \(Bundle.main.shortVersion) (\(Bundle.main.bundleVersion))",
                     tableName: "About",
                     comment: "%1$@ is version number and %2$@ is build number")
                .textSelection(.enabled)
                
                Link(String("coteditor.com"),
                     destination: URL(string: "https://coteditor.com")!)
                .foregroundStyle(.tint)
                
                Text(Bundle.main.copyright)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .fixedSize()
            .scenePadding([.leading, .vertical])
            .padding(.trailing)
            .frame(minWidth: 200)
            
            ScrollView(.vertical) {
                CreditsView()
            }
            .ignoresSafeArea()
            .background()
        }
        .accessibilityLabel(String(localized: "About \(Bundle.main.bundleName)", table: "About", comment: "accessibility label (%@ is app name)"))
        .controlSize(.small)
        .frame(width: 540, height: 300)
    }
}


// MARK: -

private struct Credits: Decodable {
    
    struct Contributor: Decodable {
        
        var name: String
        var url: String?
    }
    
    var project: [Contributor] = []
    var original: Contributor?
    var localization: [String: [Contributor]] = [:]
}


private struct CreditsView: View {
    
    @State private var credits: Credits = .init()
    
    
    var body: some View {
        
        VStack(spacing: 6) {
            SectionView(String(localized: "The CotEditor Project", table: "About", comment: "section heading")) {
                ForEach(self.credits.project, id: \.name) {
                    ContributorView(contributor: $0)
                }
            }
            
            SectionView(String(localized: "Localization", table: "About", comment: "section heading")) {
                Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 4) {
                    ForEach(self.credits.localization.sorted(\.key), id: \.key) { item in
                        GridRow {
                            Text(Locale.current.localizedString(forIdentifier: item.key)!)
                                .foregroundStyle(.secondary)
                                .gridColumnAlignment(.trailing)
                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(item.value, id: \.name) {
                                    ContributorView(contributor: $0)
                                }
                            }
                        }
                    }
                }
            }
            
            SectionView(String(localized: "Special Thanks", table: "About", comment: "section heading")) {
                Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 4) {
                    GridRow {
                        Text("original developer", tableName: "About")
                            .foregroundStyle(.secondary)
                            .gridColumnAlignment(.trailing)
                        if let original = self.credits.original {
                            ContributorView(contributor: original)
                        }
                    }
                    Text("and all great contributors", tableName: "About",
                         comment: "last line of the Special Thanks section")
                }
            }
            
            Text("CotEditor is an open source program\nlicensed under the Apache License, Version 2.0.", tableName: "About")
            Link(String("https://github.com/coteditor"),
                 destination: URL(string: "https://github.com/coteditor")!)
            .foregroundStyle(.tint)
        }
        .task {
            guard
                let url = Bundle.main.url(forResource: "Credits", withExtension: "json"),
                let data = try? Data(contentsOf: url),
                let credits = try? JSONDecoder().decode(Credits.self, from: data)
            else { return assertionFailure() }
            self.credits = credits
        }
        .multilineTextAlignment(.center)
        .lineSpacing(2)
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    
    private struct SectionView<Content: View>: View {
        
        var label: String
        var content: () -> Content
        
        
        init(_ label: String, content: @escaping () -> Content) {
            
            self.label = label
            self.content = content
        }
        
        
        var body: some View {
            
            Section {
                self.content()
                    .padding(.bottom, 14)
            } header: {
                Text(self.label)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            
        }
    }
    
    
    private struct ContributorView: View {
        
        var contributor: Credits.Contributor
        
        
        var body: some View {
            
            HStack(spacing: 2) {
                Text(self.contributor.name)
                    .textSelection(.enabled)
                LinkButton(url: self.contributor.url ?? "")
                    .foregroundStyle(.tint)
            }
        }
    }
}



// MARK: - Preview

#Preview {
    AboutView()
}
