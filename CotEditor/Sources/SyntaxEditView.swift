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
        
        
        static let terms: [Self] = [.keywords, .commands, .types, .attributes, .variables, .numbers, .strings, .characters, .comments]
        static let others: [Self] = [.outline, .completion, .fileMapping]
        static let syntaxData: [Self] = [.syntaxInfo, .validation]
    }
    
    
    @ObservedObject var syntax: SyntaxDefinition = .init()
    var originalName: String?
    var isBundled: Bool = false
    let saveAction: (_ syntax: SyntaxDefinition, _ name: String) throws -> Void
    
    weak var parent: NSHostingController<Self>?

    @State private var name: String = ""
    @State private var message: String?
    
    @State private var pane: Pane = .keywords
    @State private var errors: [SyntaxDefinition.Error] = []
    @State private var error: (any Error)?
    
    @FocusState private var isNameFieldFocused: Bool
    
    
    var body: some View {
        
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $pane) {
                Section(String(localized: "Highlight", table: "SyntaxEdit", comment: "section header in sidebar")) {
                    ForEach(Pane.terms, id: \.self) { pane in
                        Text(pane.label)
                    }
                }
                Section(String(localized: "Features", table: "SyntaxEdit", comment: "section header in sidebar")) {
                    ForEach(Pane.others, id: \.self) { pane in
                        Text(pane.label)
                    }
                }
                Section(String(localized: "Definition", table: "SyntaxEdit", comment: "section header in sidebar")) {
                    ForEach(Pane.syntaxData, id: \.self) { pane in
                        Text(pane.label)
                    }
                }
            }.navigationSplitViewColumnWidth(160)
            
        } detail: {
            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    if self.isBundled {
                        Text(self.name)
                            .fontWeight(.medium)
                            .help(String(localized: "Bundled syntaxes can’t be renamed.", table: "SyntaxEdit", comment: "tooltip for name field for bundled syntax"))
                    } else {
                        TextField(text: $name, label: EmptyView.init)
                            .focused($isNameFieldFocused)
                            .fontWeight(.medium)
                            .frame(maxWidth: 160)
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
                    Picker(String(localized: "Kind:", table: "SyntaxEdit"), selection: $syntax.kind) {
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
        .frame(idealWidth: 680, minHeight: 500, idealHeight: 500)
    }
    
    
    @ViewBuilder private var detailView: some View {
        
        switch self.pane {
            case .keywords:
                SyntaxTermEditView(terms: $syntax.keywords)
            case .commands:
                SyntaxTermEditView(terms: $syntax.commands)
            case .types:
                SyntaxTermEditView(terms: $syntax.types)
            case .attributes:
                SyntaxTermEditView(terms: $syntax.attributes)
            case .variables:
                SyntaxTermEditView(terms: $syntax.variables)
            case .values:
                SyntaxTermEditView(terms: $syntax.values)
            case .numbers:
                SyntaxTermEditView(terms: $syntax.numbers)
            case .strings:
                SyntaxTermEditView(terms: $syntax.strings)
            case .characters:
                SyntaxTermEditView(terms: $syntax.characters)
            case .comments:
                SyntaxCommentEditView(comment: $syntax.commentDelimiters, terms: $syntax.comments)
            case .outline:
                SyntaxOutlineEditView(outlines: $syntax.outlines)
            case .completion:
                SyntaxCompletionEditView(completions: $syntax.completions)
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
            try self.saveAction(self.syntax, self.name)
        } catch {
            self.error = error
            return
        }
        
        self.parent?.dismiss(nil)
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


private extension Syntax.Kind {
    
    var label: String {
        
        switch self {
            case .general:
                String(localized: "Syntax.Kind.general.label",
                       defaultValue: "General",
                       table: "SyntaxEdit",
                       comment: "syntax kind")
            case .code:
                String(localized: "Syntax.Kind.code.label",
                       defaultValue: "Code",
                       table: "SyntaxEdit",
                       comment: "syntax kind")
        }
    }
}


private extension SyntaxEditView.Pane {
    
    var label: String {
        
        switch self {
            case .keywords:
                String(localized: "SyntaxEditView.Pane.keywords.label",
                       defaultValue: "Keywords",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .commands:
                String(localized: "SyntaxEditView.Pane.commands.label",
                       defaultValue: "Commands",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .types:
                String(localized: "SyntaxEditView.Pane.types.label",
                       defaultValue: "Types",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .attributes:
                String(localized: "SyntaxEditView.Pane.attributes.label",
                       defaultValue: "Attributes",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .variables:
                String(localized: "SyntaxEditView.Pane.variables.label",
                       defaultValue: "Variables",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .values:
                String(localized: "SyntaxEditView.Pane.values.label",
                       defaultValue: "Values",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .numbers:
                String(localized: "SyntaxEditView.Pane.numbers.label",
                       defaultValue: "Numbers",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .strings:
                String(localized: "SyntaxEditView.Pane.strings.label",
                       defaultValue: "Strings",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .characters:
                String(localized: "SyntaxEditView.Pane.characters.label",
                       defaultValue: "Characters",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .comments:
                String(localized: "SyntaxEditView.Pane.comments.label",
                       defaultValue: "Comments",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
                
            case .outline:
                String(localized: "SyntaxEditView.Pane.outline.label",
                       defaultValue: "Outline",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .completion:
                String(localized: "SyntaxEditView.Pane.completion.label",
                       defaultValue: "Completion List",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .fileMapping:
                String(localized: "SyntaxEditView.Pane.fileMapping.label",
                       defaultValue: "File Mapping",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
                
            case .syntaxInfo:
                String(localized: "SyntaxEditView.Pane.syntaxInfo.label",
                       defaultValue: "Information",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
            case .validation:
                String(localized: "SyntaxEditView.Pane.validation.label",
                       defaultValue: "Validation",
                       table: "SyntaxEdit",
                       comment: "menu item in sidebar")
        }
    }
}



// MARK: - Preview

#Preview {
    SyntaxEditView(originalName: "Dogs") { _, _ in }
}
