//
//  ThemeDetailView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-09-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2023 1024jp
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
import AppKit.NSColor

@MainActor private final class ThemeObject: ObservableObject {
    
    private let name: String?
    
    @Published var text: Color
    @Published var insertionPoint: Color
    @Published var invisibles: Color
    @Published var background: Color
    @Published var lineHighlight: Color
    @Published var selection: Color
    @Published var usesSystemSetting: Bool
    
    @Published var keywords: Color
    @Published var commands: Color
    @Published var types: Color
    @Published var attributes: Color
    @Published var variables: Color
    @Published var values: Color
    @Published var numbers: Color
    @Published var strings: Color
    @Published var characters: Color
    @Published var comments: Color
    
    @Published var author: String
    @Published var distributionURL: String
    @Published var license: String
    @Published var description: String
    
    
    init(_ theme: Theme) {
        
        self.name = theme.name
        
        self._text = .init(initialValue: Color(nsColor: theme.text.color))
        self._insertionPoint = .init(initialValue: Color(nsColor: theme.insertionPoint.color))
        self._invisibles = .init(initialValue: Color(nsColor: theme.invisibles.color))
        self._background = .init(initialValue: Color(nsColor: theme.background.color))
        self._lineHighlight = .init(initialValue: Color(nsColor: theme.lineHighlight.color))
        self._selection = .init(initialValue: Color(nsColor: theme.selection.color))
        self._usesSystemSetting = .init(initialValue: theme.selection.usesSystemSetting)
        
        self._keywords = .init(initialValue: Color(nsColor: theme.keywords.color))
        self._commands = .init(initialValue: Color(nsColor: theme.commands.color))
        self._types = .init(initialValue: Color(nsColor: theme.types.color))
        self._attributes = .init(initialValue: Color(nsColor: theme.attributes.color))
        self._variables = .init(initialValue: Color(nsColor: theme.variables.color))
        self._values = .init(initialValue: Color(nsColor: theme.values.color))
        self._numbers = .init(initialValue: Color(nsColor: theme.numbers.color))
        self._strings = .init(initialValue: Color(nsColor: theme.strings.color))
        self._characters = .init(initialValue: Color(nsColor: theme.characters.color))
        self._comments = .init(initialValue: Color(nsColor: theme.comments.color))
        
        self._author = .init(initialValue: theme.metadata?.author ?? "")
        self._distributionURL = .init(initialValue: theme.metadata?.distributionURL ?? "")
        self._license = .init(initialValue: theme.metadata?.license ?? "")
        self._description = .init(initialValue: theme.metadata?.description ?? "")
    }
    
    
    var theme: Theme {
        
        var theme = Theme(name: self.name)
        theme.text.color = NSColor(self.text)
        theme.insertionPoint.color = NSColor(self.insertionPoint)
        theme.invisibles.color = NSColor(self.invisibles)
        theme.background.color = NSColor(self.background)
        theme.lineHighlight.color = NSColor(self.lineHighlight)
        theme.selection.color = NSColor(self.selection)
        theme.selection.usesSystemSetting = self.usesSystemSetting
        
        theme.keywords.color = NSColor(self.keywords)
        theme.commands.color = NSColor(self.commands)
        theme.types.color = NSColor(self.types)
        theme.attributes.color = NSColor(self.attributes)
        theme.variables.color = NSColor(self.variables)
        theme.values.color = NSColor(self.values)
        theme.numbers.color = NSColor(self.numbers)
        theme.strings.color = NSColor(self.strings)
        theme.characters.color = NSColor(self.characters)
        theme.comments.color = NSColor(self.comments)
        
        if ![self.author, self.distributionURL, self.license, self.description].allSatisfy(\.isEmpty) {
            theme.metadata = .init(author: self.author,
                                   distributionURL: self.distributionURL,
                                   license: self.license,
                                   description: self.description)
        }
        
        return theme
    }
}



struct ThemeDetailView: View {
    
    @StateObject private var theme: ThemeObject
    @State private var isBundled: Bool
    
    private let didUpdateHandler: (Theme) -> Void
    
    @State private var isMetadataPresenting = false
    @State private var needsNotify = false
    @State private var columnWidth: CGFloat?
    
    
    // MARK: View
    
    init(_ theme: Theme, isBundled: Bool, didUpdateHandler: @escaping (Theme) -> Void) {
        
        self._theme = .init(wrappedValue: ThemeObject(theme))
        self.isBundled = isBundled
        self.didUpdateHandler = didUpdateHandler
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker("Text:", selection: $theme.text, supportsOpacity: false)
                    ColorPicker("Cursor:", selection: $theme.insertionPoint, supportsOpacity: false)
                    ColorPicker("Invisibles:", selection: $theme.invisibles, supportsOpacity: false)
                }
                .background(WidthGetter(key: WidthKey.self))
                .frame(width: self.columnWidth, alignment: .trailing)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker("Background:", selection: $theme.background, supportsOpacity: false)
                    ColorPicker("Current Line:", selection: $theme.lineHighlight, supportsOpacity: false)
                    ColorPicker("Selection:", selection: self.theme.usesSystemSetting ? .constant(Color(nsColor: .selectedTextBackgroundColor)) : $theme.selection, supportsOpacity: false)
                        .disabled(self.theme.usesSystemSetting)
                    Toggle("Use system color", isOn: $theme.usesSystemSetting)
                        .controlSize(.small)
                }
            }
            
            Text("Syntax")
                .fontWeight(.bold)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker("Keywords:", selection: $theme.keywords, supportsOpacity: false)
                    ColorPicker("Commands:", selection: $theme.commands, supportsOpacity: false)
                    ColorPicker("Types:", selection: $theme.types, supportsOpacity: false)
                    ColorPicker("Attributes:", selection: $theme.attributes, supportsOpacity: false)
                    ColorPicker("Variables:", selection: $theme.variables, supportsOpacity: false)
                }
                .background(WidthGetter(key: WidthKey.self))
                .frame(width: self.columnWidth, alignment: .trailing)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker("Values:", selection: $theme.values, supportsOpacity: false)
                    ColorPicker("Numbers:", selection: $theme.numbers, supportsOpacity: false)
                    ColorPicker("Strings:", selection: $theme.strings, supportsOpacity: false)
                    ColorPicker("Characters:", selection: $theme.characters, supportsOpacity: false)
                    ColorPicker("Comments:", selection: $theme.comments, supportsOpacity: false)
                }
            }
            HStack {
                Spacer()
                Button {
                    self.isMetadataPresenting.toggle()
                } label: {
                    Image(systemName: "info")
                        .symbolVariant(.circle)
                        .accessibilityLabel("Show theme file information")
                }
                .help("Show theme file information")
                .popover(isPresented: self.$isMetadataPresenting, arrowEdge: .trailing) {
                    ThemeMetadataView(author: $theme.author,
                                      distributionURL: $theme.distributionURL,
                                      license: $theme.license,
                                      description: $theme.description,
                                      isEditable: !self.isBundled)
                }
                .buttonStyle(.borderless)
            }
        }
        .onPreferenceChange(WidthKey.self) { self.columnWidth = $0 }
        // use DispatchQueue.main instead of RunLoop.main to update continuously
        .onReceive(self.theme.objectWillChange .throttle(for: .seconds(0.1), scheduler: DispatchQueue.main, latest: true)) { _ in
            if self.isMetadataPresenting {
                // postpone notification to avoid closing the popover
                self.needsNotify = true
            } else {
                self.didUpdateHandler(self.theme.theme)
            }
        }
        .onChange(of: self.isMetadataPresenting) { newValue in
            guard !newValue, self.needsNotify else { return }
            
            self.didUpdateHandler(self.theme.theme)
            self.needsNotify = false
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}



private struct ThemeMetadataView: View {
    
    @Binding var author: String
    @Binding var distributionURL: String
    @Binding var license: String
    @Binding var description: String
    let isEditable: Bool
    
    @State private var columnWidth: CGFloat?
    
    @Environment(\.openURL) private var openURL
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                self.itemView("Author:", text: $author)
            }
            
            HStack(alignment: .firstTextBaseline) {
                self.itemView("URL:", text: $distributionURL)
                LinkButton(url: self.distributionURL)
            }
            
            HStack(alignment: .firstTextBaseline) {
                self.itemView("License:", text: $license)
            }
            
            HStack(alignment: .firstTextBaseline) {
                self.itemView("Description:", text: $description, lineLimit: ...5)
            }
        }
        .onPreferenceChange(WidthKey.self) { self.columnWidth = $0 }
        .textFieldStyle(.plain)
        .controlSize(.small)
        .padding(10)
        .frame(width: 300)
    }
    
    
    @ViewBuilder private func itemView(_ title: LocalizedStringKey, text: Binding<String>, lineLimit: PartialRangeThrough<Int>? = nil) -> some View {
        
        Text(title)
            .fontWeight(.bold)
            .background(WidthGetter(key: WidthKey.self))
            .frame(width: self.columnWidth, alignment: .trailing)
        
        if self.isEditable {
            if let lineLimit, #available(macOS 13, *) {
                TextField(title, text: text, prompt: Text("Not defined"), axis: .vertical)
                    .lineLimit(lineLimit)
            } else {
                TextField(title, text: text, prompt: Text("Not defined"))
            }
        } else {
            Text(text.wrappedValue)
                .foregroundColor(.label)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}



// MARK: - Preview

struct ThemeDetailView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        ThemeDetailView(ThemeManager.shared.setting(name: "Anura")!, isBundled: false) { _ in }
            .frame(width: 360, height: 280)
        
        ThemeMetadataView(author: .constant("Clarus"),
                          distributionURL: .constant("https://coteditor.com"),
                          license: .constant(""),
                          description: .constant(""),
                          isEditable: true)
        .previewDisplayName("Metadata (editable)")
        
        ThemeMetadataView(author: .constant(""),
                          distributionURL: .constant(""),
                          license: .constant(""),
                          description: .constant(""),
                          isEditable: false)
        .previewDisplayName("Metadata (fixed)")
    }
}
