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
//  © 2022-2024 1024jp
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

private final class ThemeObject: ObservableObject {
    
    private let name: String?
    let isBundled: Bool
    
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
    
    
    init(_ theme: Theme, isBundled: Bool) {
        
        self.name = theme.name
        self.isBundled = isBundled
        
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
        theme.text.color = NSColor(self.text).componentBased
        theme.invisibles.color = NSColor(self.invisibles).componentBased
        theme.insertionPoint.color = NSColor(self.insertionPoint).componentBased
        theme.insertionPoint.usesSystemSetting = self.usesInsertionPointSystemSetting
        theme.background.color = NSColor(self.background).componentBased
        theme.lineHighlight.color = NSColor(self.lineHighlight).componentBased
        theme.selection.color = NSColor(self.selection).componentBased
        theme.selection.usesSystemSetting = self.usesSelectionSystemSetting
        
        theme.keywords.color = NSColor(self.keywords).componentBased
        theme.commands.color = NSColor(self.commands).componentBased
        theme.types.color = NSColor(self.types).componentBased
        theme.attributes.color = NSColor(self.attributes).componentBased
        theme.variables.color = NSColor(self.variables).componentBased
        theme.values.color = NSColor(self.values).componentBased
        theme.numbers.color = NSColor(self.numbers).componentBased
        theme.strings.color = NSColor(self.strings).componentBased
        theme.characters.color = NSColor(self.characters).componentBased
        theme.comments.color = NSColor(self.comments).componentBased
        
        theme.metadata = self.metadata.isEmpty ? nil : self.metadata
        
        return theme
    }
}



struct ThemeEditorView: View {
    
    @StateObject private var theme: ThemeObject
    
    private let didUpdateHandler: (Theme) -> Void
    
    @State private var isMetadataPresenting = false
    @State private var needsNotify = false
    
    
    // MARK: View
    
    init(_ theme: Theme, isBundled: Bool, didUpdateHandler: @escaping (Theme) -> Void) {
        
        self._theme = .init(wrappedValue: ThemeObject(theme, isBundled: isBundled))
        self.didUpdateHandler = didUpdateHandler
    }
    
    
    var body: some View {
        
        Grid(alignment: .trailingFirstTextBaseline, verticalSpacing: 4) {
            GridRow {
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "Text:", table: "ThemeEditor"),
                                selection: $theme.text, supportsOpacity: false)
                    ColorPicker(String(localized: "Invisibles:", table: "ThemeEditor"),
                                selection: $theme.invisibles)
                    if #available(macOS 14, *) {
                        SystemColorPicker(String(localized: "Cursor:", table: "ThemeEditor"),
                                          selection: $theme.insertionPoint,
                                          usesSystemSetting: $theme.usesInsertionPointSystemSetting,
                                          systemColor: Color(nsColor: .textInsertionPointColor))
                    } else {
                        ColorPicker(String(localized: "Cursor:", table: "ThemeEditor"),
                                    selection: $theme.insertionPoint)
                    }
                }
                
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "Background:", table: "ThemeEditor"),
                                selection: $theme.background, supportsOpacity: false)
                    ColorPicker(String(localized: "Current Line:", table: "ThemeEditor"),
                                selection: $theme.lineHighlight, supportsOpacity: false)
                    SystemColorPicker(String(localized: "Selection:", table: "ThemeEditor"),
                                      selection: $theme.selection,
                                      usesSystemSetting: $theme.usesSelectionSystemSetting,
                                      systemColor: Color(nsColor: .selectedTextBackgroundColor),
                                      supportsOpacity: false)
                }
            }
            
            GridRow {
                Text("Syntax", tableName: "ThemeEditor")
                    .fontWeight(.bold)
                    .gridCellColumns(2)
                    .gridCellAnchor(.leading)
            }
            
            GridRow {
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "Keywords:", table: "ThemeEditor"),
                                selection: $theme.keywords)
                    ColorPicker(String(localized: "Commands:", table: "ThemeEditor"),
                                selection: $theme.commands)
                    ColorPicker(String(localized: "Types:", table: "ThemeEditor"),
                                selection: $theme.types)
                    ColorPicker(String(localized: "Attributes:", table: "ThemeEditor"),
                                selection: $theme.attributes)
                    ColorPicker(String(localized: "Variables:", table: "ThemeEditor"),
                                selection: $theme.variables)
                }
                
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "Values:", table: "ThemeEditor"),
                                selection: $theme.values)
                    ColorPicker(String(localized: "Numbers:", table: "ThemeEditor"),
                                selection: $theme.numbers)
                    ColorPicker(String(localized: "Strings:", table: "ThemeEditor"),
                                selection: $theme.strings)
                    ColorPicker(String(localized: "Characters:", table: "ThemeEditor"),
                                selection: $theme.characters)
                    ColorPicker(String(localized: "Comments:", table: "ThemeEditor"),
                                selection: $theme.comments)
                }
            }
            
            HStack {
                Spacer()
                Button {
                    self.isMetadataPresenting.toggle()
                } label: {
                    Image(systemName: "info")
                        .symbolVariant(.circle)
                }
                .accessibilityLabel(String(localized: "Show theme file information", table: "ThemeEditor"))
                .help(String(localized: "Show theme file information", table: "ThemeEditor", comment: "tooltip"))
                .popover(isPresented: self.$isMetadataPresenting, arrowEdge: .trailing) {
                    ThemeMetadataView(metadata: $theme.metadata, isEditable: !self.theme.isBundled)
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
    
    let label: String
    @Binding var selection: Color
    @Binding var usesSystemSetting: Bool
    var systemColor: Color
    var supportsOpacity: Bool
    
    
    init(_ label: String, selection: Binding<Color>, usesSystemSetting: Binding<Bool>, systemColor: Color, supportsOpacity: Bool = true) {
        
        self.label = label
        self._selection = selection
        self._usesSystemSetting = usesSystemSetting
        self.systemColor = systemColor
        self.supportsOpacity = supportsOpacity
    }
    
    
    var body: some View {
        
        ColorPicker(self.label,
                    selection: self.usesSystemSetting ? .constant(self.systemColor) : $selection,
                    supportsOpacity: self.supportsOpacity)
        .disabled(self.usesSystemSetting)
        Toggle(String(localized: "Use system color", table: "ThemeEditor", comment: "toggle button label"), isOn: $usesSystemSetting)
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
                self.itemView(String(localized: "Author:", table: "ThemeEditor"),
                              text: $metadata.author ?? "")
            }
            GridRow {
                self.itemView(String(localized: "URL:", table: "ThemeEditor"),
                              text: $metadata.distributionURL ?? "")
                LinkButton(url: self.metadata.distributionURL ?? "")
            }
            GridRow {
                self.itemView(String(localized: "License:", table: "ThemeEditor"),
                              text: $metadata.license ?? "")
            }
            GridRow {
                self.itemView(String(localized: "Description:", table: "ThemeEditor"),
                              text: $metadata.description ?? "", lineLimit: 2...5)
            }
        }
        .padding(10)
        .controlSize(.small)
        .frame(width: 300, alignment: .leading)
    }
    
    
    @ViewBuilder private func itemView(_ title: String, text: Binding<String>, lineLimit: ClosedRange<Int> = 1...1) -> some View {
        
        Text(title)
            .fontWeight(.bold)
            .gridColumnAlignment(.trailing)
        
        if self.isEditable {
            TextField(title, text: text, prompt: Text("Not defined", tableName: "ThemeEditor", comment: "placeholder"), axis: .vertical)
                .lineLimit(lineLimit)
                .textFieldStyle(.plain)
        } else {
            Text(text.wrappedValue)
                .foregroundColor(.label)
                .textSelection(.enabled)
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

@available(macOS 14, *)
#Preview(traits: .fixedLayout(width: 360, height: 280)) {
    ThemeEditorView(ThemeManager.shared.setting(name: "Anura")!, isBundled: false) { _ in }
}

#Preview("Metadata (editable)") {
    @State var metadata = Theme.Metadata(
        author: "Clarus",
        distributionURL: "https://coteditor.com"
    )
    
    return ThemeMetadataView(metadata: $metadata, isEditable: true)
}

#Preview("Metadata (fixed)") {
    @State var metadata = Theme.Metadata(
        author: "Claus"
    )
    
    return ThemeMetadataView(metadata: $metadata, isEditable: false)
}
