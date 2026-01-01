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
//  © 2023-2026 1024jp
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
import Syntax

struct SyntaxEditView: View {
    
    typealias SaveAction = (_ syntax: Syntax, _ name: String) throws -> Void
    
    enum Mode: Identifiable {
        
        case new
        case edit(SettingState)
        
        
        var id: String? {
            
            switch self {
                case .new: nil
                case .edit(let state): state.name
            }
        }
    }
    
    
    enum Pane {
        
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
        
        
        static let highlights: [Self] = [.keywords, .commands, .types, .attributes, .variables, .values, .numbers, .strings, .characters, .comments]
        static let others: [Self] = [.outline, .completion, .fileMapping]
        static let syntaxData: [Self] = [.syntaxInfo, .validation]
    }
    
    
    @State var syntax: SyntaxObject
    var originalName: String?
    var isBundled: Bool = false
    var saveAction: SaveAction
    
    
    private var manager: SyntaxManager
    
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var message: String?
    
    @State private var pane: Pane = .keywords
    @State private var errors: [SyntaxObject.Error] = []
    @State private var error: (any Error)?
    
    @FocusState private var isNameFieldFocused: Bool
    
    
    init(mode: Mode, syntax: Syntax? = nil, manager: SyntaxManager, saveAction: @escaping SaveAction) {
        
        switch mode {
            case .new:
                break
            case .edit(let state):
                self.originalName = state.name
                self.isBundled = state.isBundled
        }
        self.syntax = SyntaxObject(value: syntax)
        self.manager = manager
        self.saveAction = saveAction
    }
    
    
    var body: some View {
        
        NavigationSplitView(columnVisibility: .constant(.all)) {
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
                    if self.isBundled {
                        Text(self.name)
                            .fontWeight(.medium)
                            .help(String(localized: "Built-in syntaxes can’t be renamed.", table: "SyntaxEditor",
                                         comment: "tooltip for name field for bundled syntax"))
                    } else {
                        TextField(text: $name, label: EmptyView.init)
                            .focused($isNameFieldFocused)
                            .fontWeight(.medium)
                            .frame(minWidth: 80, maxWidth: 160)
                            .onChange(of: self.name) { _, newValue in
                                self.validate(name: newValue)
                            }
                    }
                    
                    if let message {
                        Label(message, systemImage: "arrow.backward")
                            .symbolVariant(.circle.fill)
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
                        Button(String(localized: "Action.restoreDefaults.label", defaultValue: "Restore Defaults"), action: self.restore)
                            .fixedSize()
                    }
                    Spacer()
                    SubmitButtonGroup(action: self.submit) {
                        self.dismiss()
                    }
                }.scenePadding(.horizontal)
            }.scenePadding(.vertical)
        }
        .onAppear {
            self.name = self.originalName ?? ""
        }
        .onChange(of: self.pane) {
            self.errors = self.syntax.validate()
        }
        .alert(error: $error)
        .frame(minWidth: 400, idealWidth: 680, minHeight: 525, idealHeight: 525)
        .presentationSizing(.fitted)
    }
    
    
    @ViewBuilder private var detailView: some View {
        
        switch self.pane {
            case .keywords:
                SyntaxHighlightEditView(items: $syntax.highlights.keywords)
            case .commands:
                SyntaxHighlightEditView(items: $syntax.highlights.commands)
            case .types:
                SyntaxHighlightEditView(items: $syntax.highlights.types)
            case .attributes:
                SyntaxHighlightEditView(items: $syntax.highlights.attributes)
            case .variables:
                SyntaxHighlightEditView(items: $syntax.highlights.variables)
            case .values:
                SyntaxHighlightEditView(items: $syntax.highlights.values)
            case .numbers:
                SyntaxHighlightEditView(items: $syntax.highlights.numbers)
            case .strings:
                SyntaxHighlightEditView(items: $syntax.highlights.strings)
            case .characters:
                SyntaxHighlightEditView(items: $syntax.highlights.characters)
            case .comments:
                SyntaxCommentEditView(comment: $syntax.commentDelimiters, highlights: $syntax.highlights.comments)
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
    private func submit() {
        
        // end editing
        self.isNameFieldFocused = false
        
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
        
        self.dismiss()
    }
    
    
    /// Restores the current settings in editor to the user default.
    private func restore() {
        
        guard
            self.isBundled,
            let syntax = self.manager.bundledSetting(name: self.name)
        else { return }
        
        self.syntax.update(with: syntax)
        self.errors = self.syntax.validate()
    }
    
    
    /// Validates the passed-in syntax name.
    ///
    /// - Parameter name: The syntax name to test.
    /// - Returns: `true` if the syntax name is valid.
    @discardableResult private func validate(name: String) -> Bool {
        
        if self.isBundled { return true }  // cannot edit syntax name
        
        do {
            try self.manager.validate(settingName: name, originalName: self.originalName)
        } catch {
            self.message = error.localizedDescription
            return false
        }
        
        self.message = nil
        return true
    }
}


extension SyntaxEditView.Pane {
    
    /// The localized label.
    var label: String {
        
        switch self {
            case .keywords:
                SyntaxType.keywords.label
            case .commands:
                SyntaxType.commands.label
            case .types:
                SyntaxType.types.label
            case .attributes:
                SyntaxType.attributes.label
            case .variables:
                SyntaxType.variables.label
            case .values:
                SyntaxType.values.label
            case .numbers:
                SyntaxType.numbers.label
            case .strings:
                SyntaxType.strings.label
            case .characters:
                SyntaxType.characters.label
            case .comments:
                SyntaxType.comments.label
                
            case .outline:
                String(localized: "Syntax.key.outlines.label",
                       defaultValue: "Outline",
                       table: "SyntaxEditor",
                       comment: "syntax definition type")
            case .completion:
                String(localized: "Syntax.key.completions.label",
                       defaultValue: "Completion",
                       table: "SyntaxEditor",
                       comment: "syntax definition type")
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
}


// MARK: - Preview

#Preview {
    SyntaxEditView(mode: .new, manager: .shared) { _, _ in }
}
