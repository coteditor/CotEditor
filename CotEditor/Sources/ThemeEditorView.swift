//
//  ThemeEditorView.swift
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
    @Published var invisibles: Color
    @Published var insertionPoint: Color
    @Published var usesInsertionPointSystemSetting: Bool
    @Published var background: Color
    @Published var lineHighlight: Color
    @Published var selection: Color
    @Published var usesSelectionSystemSetting: Bool
    
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
    
    @Published var metadata: Theme.Metadata
    
    
    init(_ theme: Theme) {
        
        self.name = theme.name
        
        self.text = Color(nsColor: theme.text.color)
        self.invisibles = Color(nsColor: theme.invisibles.color)
        self.insertionPoint = Color(nsColor: theme.insertionPoint.color)
        self.usesInsertionPointSystemSetting = theme.insertionPoint.usesSystemSetting
        self.background = Color(nsColor: theme.background.color)
        self.lineHighlight = Color(nsColor: theme.lineHighlight.color)
        self.selection = Color(nsColor: theme.selection.color)
        self.usesSelectionSystemSetting = theme.selection.usesSystemSetting
        
        self.keywords = Color(nsColor: theme.keywords.color)
        self.commands = Color(nsColor: theme.commands.color)
        self.types = Color(nsColor: theme.types.color)
        self.attributes = Color(nsColor: theme.attributes.color)
        self.variables = Color(nsColor: theme.variables.color)
        self.values = Color(nsColor: theme.values.color)
        self.numbers = Color(nsColor: theme.numbers.color)
        self.strings = Color(nsColor: theme.strings.color)
        self.characters = Color(nsColor: theme.characters.color)
        self.comments = Color(nsColor: theme.comments.color)
        
        self.metadata = theme.metadata ?? .init()
    }
    
    
    var theme: Theme {
        
        var theme = Theme(name: self.name)
        theme.text.color = NSColor(self.text)
        theme.invisibles.color = NSColor(self.invisibles)
        theme.insertionPoint.color = NSColor(self.insertionPoint)
        theme.insertionPoint.usesSystemSetting = self.usesInsertionPointSystemSetting
        theme.background.color = NSColor(self.background)
        theme.lineHighlight.color = NSColor(self.lineHighlight)
        theme.selection.color = NSColor(self.selection)
        theme.selection.usesSystemSetting = self.usesSelectionSystemSetting
        
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
        
        theme.metadata = self.metadata.isEmpty ? nil : self.metadata
        
        return theme
    }
}



struct ThemeEditorView: View {
    
    @StateObject private var theme: ThemeObject
    @State private var isBundled: Bool
    
    private let didUpdateHandler: (Theme) -> Void
    
    @State private var isMetadataPresenting = false
    @State private var needsNotify = false
    
    
    // MARK: View
    
    init(_ theme: Theme, isBundled: Bool, didUpdateHandler: @escaping (Theme) -> Void) {
        
        self._theme = .init(wrappedValue: ThemeObject(theme))
        self.isBundled = isBundled
        self.didUpdateHandler = didUpdateHandler
    }
    
    
    var body: some View {
        
        Grid(alignment: .trailingFirstTextBaseline, verticalSpacing: 4) {
            GridRow {
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker("Text:", selection: $theme.text, supportsOpacity: false)
                    ColorPicker("Invisibles:", selection: $theme.invisibles, supportsOpacity: false)
                    if #available(macOS 14, *) {
                        SystemColorPicker("Cursor:", selection: $theme.insertionPoint, usesSystemSetting: $theme.usesInsertionPointSystemSetting, systemColor: Color(nsColor: .textInsertionPointColor))
                    } else {
                        ColorPicker("Cursor:", selection: $theme.insertionPoint, supportsOpacity: false)
                    }
                }
                
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker("Background:", selection: $theme.background, supportsOpacity: false)
                    ColorPicker("Current Line:", selection: $theme.lineHighlight, supportsOpacity: false)
                    SystemColorPicker("Selection:", selection: $theme.selection, usesSystemSetting: $theme.usesSelectionSystemSetting, systemColor: Color(nsColor: .selectedTextBackgroundColor))
                }
            }
            
            GridRow {
                Text("Syntax")
                    .fontWeight(.bold)
                    .gridCellColumns(2)
                    .gridCellAnchor(.leading)
            }
            
            GridRow {
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker("Keywords:", selection: $theme.keywords, supportsOpacity: false)
                    ColorPicker("Commands:", selection: $theme.commands, supportsOpacity: false)
                    ColorPicker("Types:", selection: $theme.types, supportsOpacity: false)
                    ColorPicker("Attributes:", selection: $theme.attributes, supportsOpacity: false)
                    ColorPicker("Variables:", selection: $theme.variables, supportsOpacity: false)
                }
                
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
                    ThemeMetadataView(metadata: $theme.metadata, isEditable: !self.isBundled)
                }
                .buttonStyle(.borderless)
            }
        }
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


private struct SystemColorPicker: View {
    
    let label: LocalizedStringKey
    @Binding var selection: Color
    @Binding var usesSystemSetting: Bool
    var systemColor: Color
    
    
    init(_ label: LocalizedStringKey, selection: Binding<Color>, usesSystemSetting: Binding<Bool>, systemColor: Color) {
        
        self.label = label
        self._selection = selection
        self._usesSystemSetting = usesSystemSetting
        self.systemColor = systemColor
    }
    
    
    var body: some View {
        
        ColorPicker(self.label,
                    selection: self.usesSystemSetting ? .constant(self.systemColor) : $selection,
                    supportsOpacity: false)
        .disabled(self.usesSystemSetting)
        Toggle("Use system color", isOn: $usesSystemSetting)
            .controlSize(.small)
    }
}


private struct ThemeMetadataView: View {
    
    @Binding var metadata: Theme.Metadata
    let isEditable: Bool
    
    
    // MARK: View
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 4) {
            GridRow {
                self.itemView("Author:", text: $metadata.author.bound)
            }
            GridRow {
                self.itemView("URL:", text: $metadata.distributionURL.bound)
                LinkButton(url: self.metadata.distributionURL.bound)
            }
            GridRow {
                self.itemView("License:", text: $metadata.license.bound)
            }
            GridRow {
                self.itemView("Description:", text: $metadata.description.bound, lineLimit: 2...5)
            }
        }
        .controlSize(.small)
        .padding(10)
        .frame(width: 300)
    }
    
    
    @ViewBuilder private func itemView(_ title: LocalizedStringKey, text: Binding<String>, lineLimit: ClosedRange<Int> = 1...1) -> some View {
        
        Text(title)
            .fontWeight(.bold)
            .gridColumnAlignment(.trailing)
        
        if self.isEditable {
            TextField(title, text: text, prompt: Text("Not defined"), axis: .vertical)
                .lineLimit(lineLimit)
                .textFieldStyle(.plain)
        } else {
            Text(text.wrappedValue)
                .foregroundColor(.label)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


private extension Theme.Metadata {
    
    var isEmpty: Bool {
        
        [self.author, self.distributionURL, self.license, self.description]
            .compactMap({ $0 }).isEmpty
    }
}



// MARK: - Preview

#Preview {
    ThemeEditorView(ThemeManager.shared.setting(name: "Anura")!, isBundled: false) { _ in }
        .frame(width: 360, height: 280)
}

#Preview("Metadata (editable)") {
    ThemeMetadataView(metadata: .constant(.init(
        author: "Clarus",
        distributionURL: "https://coteditor.com"
    )), isEditable: true)
}

#Preview("Metadata (fixed)") {
    ThemeMetadataView(metadata: .constant(.init(
        author: "Claus"
    )), isEditable: false)
}
