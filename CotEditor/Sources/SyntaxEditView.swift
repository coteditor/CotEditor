//
//  SyntaxEditView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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

struct SyntaxEditView: View {
    
    typealias SaveAction = (_ syntax: Syntax, _ name: String) throws -> Void
    
    fileprivate enum Pane {
        
        case keywords
        case commands
        case types
        case attributes
        case variables
        case values
        case numbers
        case strings
        case characters
        case comments
        
        case outline
        case completion
        case fileMapping
        
        case syntaxInfo
        case validation
        
        
        static let highlights: [Self] = [.keywords, .commands, .types, .attributes, .variables, .numbers, .strings, .characters, .comments]
        static let others: [Self] = [.outline, .completion, .fileMapping]
        static let syntaxData: [Self] = [.syntaxInfo, .validation]
    }
    
    
    @StateObject var syntax: SyntaxObject
    var originalName: String?
    var isBundled: Bool = false
    let saveAction: SaveAction
    
    weak var parent: NSHostingController<Self>?
    
    
    @MainActor private static var viewSize = CGSize(width: 680, height: 500)
    
    @State private var name: String = ""
    @State private var message: String?
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var pane: Pane = .keywords
    @State private var errors: [SyntaxObject.Error] = []
    @State private var error: (any Error)?
    
    @FocusState private var isNameFieldFocused: Bool
    
    
    init(syntax: Syntax? = nil, originalName: String? = nil, isBundled: Bool = false, saveAction: @escaping SaveAction) {
        
        self._syntax = StateObject(wrappedValue: SyntaxObject(value: syntax))
        self.originalName = originalName
        self.isBundled = isBundled
        self.saveAction = saveAction
    }
    
    
    var body: some View {
        
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $pane) {
                Section(String(localized: "Highlighting", table: "SyntaxEditor", comment: "section header in sidebar")) {
                    ForEach(Pane.highlights, id: \.self) { pane in
                        Text(pane.label)
                    }
                }
                Section(String(localized: "Features", table: "SyntaxEditor", comment: "section header in sidebar")) {
                    ForEach(Pane.others, id: \.self) { pane in
                        Text(pane.label)
                    }
                }
                Section(String(localized: "Definition File", table: "SyntaxEditor", comment: "section header in sidebar")) {
                    ForEach(Pane.syntaxData, id: \.self) { pane in
                        Text(pane.label)
                    }
                }
            }.environment(\.sidebarRowSize, .medium)
            
        } detail: {
            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    if self.columnVisibility == .detailOnly {
                        Button {
                            withAnimation {
                                self.columnVisibility = .all
                            }
                        } label: {
                            Image(systemName: "sidebar.leading")
                                .accessibilityLabel(String(localized: "Show Sidebar", table: "SyntaxEditor"))
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    if self.isBundled {
                        Text(self.name)
                            .fontWeight(.medium)
                            .help(String(localized: "Bundled syntaxes can’t be renamed.", table: "SyntaxEditor", comment: "tooltip for name field for bundled syntax"))
                    } else {
                        TextField(text: $name, label: EmptyView.init)
                            .focused($isNameFieldFocused)
                            .fontWeight(.medium)
                            .frame(minWidth: 80, maxWidth: 160)
                            .onChange(of: self.name) { newValue in
                                self.validate(name: newValue)
                            }
                    }
                    
                    if let message {
                        Label(message, systemImage: "arrow.backward")
                            .symbolVariant(.circle)
                            .symbolVariant(.fill)
                            .foregroundStyle(.secondary)
                            .controlSize(.small)
                    }
                    
                    Spacer()
                    Picker(String(localized: "Kind:", table: "SyntaxEditor"), selection: $syntax.kind) {
                        ForEach(Syntax.Kind.allCases, id: \.self) {
                            Text($0.label)
                        }
                    }.fixedSize()
                }.scenePadding(.horizontal)
                
                Divider()
                
                self.detailView
                    .scenePadding(.horizontal)
                
                Divider()
                
                HStack {
                    if self.isBundled {
                        Button(String(localized: "Restore Defaults", table: "SyntaxEditor")) {
                            self.restore()
                        }.fixedSize()
                    }
                    Spacer()
                    SubmitButtonGroup(action: self.submit) {
                        self.parent?.dismiss(nil)
                    }
                }.scenePadding(.horizontal)
            }.scenePadding(.vertical)
        }
        .onAppear {
            self.name = self.originalName ?? ""
        }
        .onChange(of: self.pane) { _ in
            self.errors = self.syntax.validate()
        }
        .alert(error: $error)
        .background {  // store last view size
            GeometryReader { geometry in
                Color.clear.onChange(of: geometry.size) { Self.viewSize = $0 }
            }
        }
        .frame(idealWidth: Self.viewSize.width, minHeight: 500, idealHeight: Self.viewSize.height)
    }
    
    
    @ViewBuilder private var detailView: some View {
        
        switch self.pane {
            case .keywords:
                SyntaxHighlightEditView(items: $syntax.keywords)
            case .commands:
                SyntaxHighlightEditView(items: $syntax.commands)
            case .types:
                SyntaxHighlightEditView(items: $syntax.types)
            case .attributes:
                SyntaxHighlightEditView(items: $syntax.attributes)
            case .variables:
                SyntaxHighlightEditView(items: $syntax.variables)
            case .values:
                SyntaxHighlightEditView(items: $syntax.values)
            case .numbers:
                SyntaxHighlightEditView(items: $syntax.numbers)
            case .strings:
                SyntaxHighlightEditView(items: $syntax.strings)
            case .characters:
                SyntaxHighlightEditView(items: $syntax.characters)
            case .comments:
                SyntaxCommentEditView(comment: $syntax.commentDelimiters, highlights: $syntax.comments)
            case .outline:
                SyntaxOutlineEditView(items: $syntax.outlines)
            case .completion:
                SyntaxCompletionEditView(items: $syntax.completions)
            case .fileMapping:
                SyntaxFileMappingEditView(extensions: $syntax.extensions, filenames: $syntax.filenames, interpreters: $syntax.interpreters)
            case .syntaxInfo:
                SyntaxMetadataEditView(metadata: $syntax.metadata)
            case .validation:
                SyntaxValidationView(errors: self.errors)
        }
    }
    
    
    // MARK: Private Methods
    
    /// Submits the syntax if it is valid.
    @MainActor private func submit() {
        
        // syntax name validation
        self.name = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard self.validate(name: self.name) else {
            self.isNameFieldFocused = true
            NSSound.beep()
            return
        }
        
        self.errors = self.syntax.validate()
        if !self.errors.isEmpty {
            self.pane = .validation
            NSSound.beep()
            return
        }
        
        do {
            try self.saveAction(self.syntax.value, self.name)
        } catch {
            self.error = error
            return
        }
        
        self.parent?.dismiss(nil)
    }
    
    
    /// Restores the current settings in editor to the user default.
    @MainActor private func restore() {
        
        guard
            self.isBundled,
            let syntax = SyntaxManager.shared.bundledSetting(name: self.name)
        else { return }
        
        self.syntax.update(with: syntax)
        self.errors = self.syntax.validate()
    }
    
    
    /// Validates the passed-in syntax name.
    ///
    /// - Parameter name: The syntax name to test.
    /// - Returns: `true` if the syntax name is valid.
    @discardableResult
    private func validate(name: String) -> Bool {
        
        if self.isBundled { return true }  // cannot edit syntax name
        
        do {
            try SyntaxManager.shared.validate(settingName: name, originalName: self.originalName)
        } catch {
            self.message = error.localizedDescription
            return false
        }
        
        self.message = nil
        return true
    }
}


private extension SyntaxEditView.Pane {
    
    /// The localized label.
    var label: String {
        
        switch self {
            case .keywords:
                (\SyntaxObject.keywords).label
            case .commands:
                (\SyntaxObject.commands).label
            case .types:
                (\SyntaxObject.types).label
            case .attributes:
                (\SyntaxObject.attributes).label
            case .variables:
                (\SyntaxObject.variables).label
            case .values:
                (\SyntaxObject.values).label
            case .numbers:
                (\SyntaxObject.numbers).label
            case .strings:
                (\SyntaxObject.strings).label
            case .characters:
                (\SyntaxObject.characters).label
            case .comments:
                (\SyntaxObject.comments).label
                
            case .outline:
                (\SyntaxObject.outlines).label
            case .completion:
                (\SyntaxObject.completions).label
            case .fileMapping:
                String(localized: "File Mapping",
                       table: "SyntaxEditor",
                       comment: "menu item in sidebar")
                
            case .syntaxInfo:
                String(localized: "Information",
                       table: "SyntaxEditor",
                       comment: "menu item in sidebar")
            case .validation:
                String(localized: "Validation",
                       table: "SyntaxEditor",
                       comment: "menu item in sidebar")
        }
    }
    
    
    private var keyPath: PartialKeyPath<SyntaxObject>? {
        
        switch self {
            case .keywords: \.keywords
            case .commands: \.commands
            case .types: \.types
            case .attributes: \.attributes
            case .variables: \.variables
            case .values: \.variables
            case .numbers: \.numbers
            case .strings: \.strings
            case .characters: \.characters
            case .comments: \.comments
                
            case .outline: \.outlines
            case .completion: \.completions
            default: nil
        }
    }
}


extension PartialKeyPath<SyntaxObject> {
    
    /// The localized label for the root definition keys.
    ///
    /// Not all key paths are localized.
    var label: String {
        
        switch self {
            case \.keywords:
                SyntaxType.keywords.label
            case \.commands:
                SyntaxType.commands.label
            case \.types:
                SyntaxType.types.label
            case \.attributes:
                SyntaxType.attributes.label
            case \.variables:
                SyntaxType.variables.label
            case \.values:
                SyntaxType.values.label
            case \.numbers:
                SyntaxType.numbers.label
            case \.strings:
                SyntaxType.strings.label
            case \.characters:
                SyntaxType.characters.label
            case \.comments, \.commentDelimiters:
                SyntaxType.comments.label
                
            case \.outlines:
                String(localized: "Syntax.key.outlines.label",
                       defaultValue: "Outline",
                       table: "SyntaxEditor",
                       comment: "syntax definition type")
            case \.completions:
                String(localized: "Syntax.key.completions.label",
                       defaultValue: "Completion",
                       table: "SyntaxEditor",
                       comment: "syntax definition type")
                
            default:
                "\(self)"
        }
    }
}



// MARK: - Preview

#Preview {
    SyntaxEditView(originalName: "Dogs") { _, _ in }
}
