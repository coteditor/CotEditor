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
    typealias NameValidationAction = (_ name: String) throws -> Void
    
    
    enum Pane {
        
        case fileMapping
        case delimiters
        case outline
        case completion
        
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
        
        case syntaxInfo
        case validation
        
        case builtIn
        
        
        static let features: [Self] = [.fileMapping, .delimiters, .outline, .completion]
        static let highlights: [Self] = [.keywords, .commands, .types, .attributes, .variables, .values, .numbers, .strings, .characters, .comments]
        static let syntaxData: [Self] = [.syntaxInfo, .validation]
    }
    
    
    @Environment(\.dismiss) private var dismiss
    
    private var isBundled: Bool = false
    private var customizableFeatures: ParserFeatures = .all
    private var saveAction: SaveAction
    private var validationAction: NameValidationAction

    @State private var syntax: SyntaxObject
    @State private var name: String = ""
    @State private var message: String?
    
    @State private var pane: Pane = .fileMapping
    @State private var errors: [Syntax.Error] = []
    @State private var error: (any Error)?
    
    @FocusState private var isNameFieldFocused: Bool
    
    
    init(syntax: Syntax? = nil, name: String? = nil, isBundled: Bool = false, customizableFeatures: ParserFeatures = .all, saveAction: @escaping SaveAction, validationAction: @escaping NameValidationAction = { _ in }) {
        
        self.syntax = SyntaxObject(value: syntax)
        self.name = name ?? ""
        self.isBundled = isBundled
        self.customizableFeatures = customizableFeatures
        self.saveAction = saveAction
        self.validationAction = validationAction
    }
    
    
    var body: some View {
        
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $pane) {
                Section(String(localized: "Features", table: "SyntaxEditor", comment: "section header in sidebar")) {
                    ForEach(Pane.features, id: \.self) { pane in
                        Text(pane.label)
                    }
                }
                Section(String(localized: "Highlighting", table: "SyntaxEditor", comment: "section header in sidebar")) {
                    if self.customizableFeatures.contains(.highlight) {
                        ForEach(Pane.highlights, id: \.self) { pane in
                            Text(pane.label)
                        }
                    } else {
                        Text(Pane.builtIn.label)
                            .id(Pane.builtIn)
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
                            .fontWeight(.semibold)
                            .help(String(localized: "Built-in syntaxes can’t be renamed.", table: "SyntaxEditor",
                                         comment: "tooltip for name field for bundled syntax"))
                    } else {
                        TextField(String(localized: "Syntax name", table: "SyntaxEditor"), text: $name)
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
                    Spacer()
                    SubmitButtonGroup(action: self.submit) {
                        self.dismiss()
                    }
                }.scenePadding(.horizontal)
            }.scenePadding(.vertical)
        }
        .onChange(of: self.pane) {
            self.errors = self.syntax.value.validate()
        }
        .alert(error: $error)
        .frame(minWidth: 400, idealWidth: 740, minHeight: 525, idealHeight: 525)
        .presentationSizing(.fitted)
    }
    
    
    @ViewBuilder private var detailView: some View {
        
        switch self.pane {
            case .fileMapping:
                SyntaxFileMappingEditView(extensions: $syntax.extensions, filenames: $syntax.filenames, interpreters: $syntax.interpreters)
            case .delimiters:
                SyntaxDelimitersEditView(
                    inlineComments: $syntax.inlineComments,
                    blockComments: $syntax.blockComments,
                    lexicalRules: $syntax.lexicalRules,
                    canCustomizeHighlight: self.customizableFeatures.contains(.highlight)
                )
            case .outline:
                if self.customizableFeatures.contains(.outline) {
                    SyntaxOutlineEditView(items: $syntax.outlines)
                } else {
                    SyntaxBuiltInView()
                }
            case .completion:
                SyntaxCompletionEditView(items: $syntax.completions,
                                         canCustomizeHighlight: self.customizableFeatures.contains(.highlight))
                
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
                SyntaxHighlightEditView(items: $syntax.highlights.comments)
                
            case .syntaxInfo:
                SyntaxMetadataEditView(metadata: $syntax.metadata)
            case .validation:
                SyntaxValidationView(errors: self.errors)
                
            case .builtIn:
                SyntaxBuiltInView()
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
        
        let syntax = self.syntax.value.sanitized
        
        // syntax validation
        self.errors = syntax.validate()
        if !self.errors.isEmpty {
            self.pane = .validation
            NSSound.beep()
            return
        }
        
        do {
            try self.saveAction(syntax, self.name)
        } catch {
            self.error = error
            return
        }
        
        self.dismiss()
    }
    
    
    /// Validates the passed-in syntax name.
    ///
    /// - Parameter name: The syntax name to test.
    /// - Returns: `true` if the syntax name is valid.
    @discardableResult private func validate(name: String) -> Bool {
        
        if self.isBundled { return true }  // cannot edit syntax name
        
        do {
            try self.validationAction(name)
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
                
            case .fileMapping:
                String(localized: "File Mapping",
                       table: "SyntaxEditor",
                       comment: "menu item in sidebar")
            case .delimiters:
                String(localized: "Delimiters",
                       table: "SyntaxEditor",
                       comment: "syntax definition type")
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
                
            case .syntaxInfo:
                String(localized: "Information",
                       table: "SyntaxEditor",
                       comment: "menu item in sidebar")
            case .validation:
                String(localized: "Validation",
                       table: "SyntaxEditor",
                       comment: "menu item in sidebar")
                
            case .builtIn:
                String(localized: "Built-in",
                       table: "SyntaxEditor",
                       comment: "menu item in sidebar")
        }
    }
}


// MARK: - Preview

#Preview {
    SyntaxEditView { _, _ in }
}
