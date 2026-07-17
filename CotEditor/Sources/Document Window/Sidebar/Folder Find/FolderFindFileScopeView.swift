//
//  FolderFindFileScopeView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-06-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

public import Foundation
public import FolderFind
import AppKit
import SwiftUI
import StringUtils

struct FolderFindFileScopeView: View {
    
    @State var fileScope: FileScope
    var savedScopes: Binding<[String: FileScope]>?
    var completionHandler: (FileScope) -> Void
    
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var validationError: FileScope.Error?
    @State private var isScopeSaveViewPresented = false
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            self.conjunctionPicker
            
            RuleEditor(fileScope: $fileScope)
            
            if let validationError {
                Label(validationError.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
            }
            
            SubmitButtonGroup(helpAnchor: "howto_find_in_folder", action: self.apply, supplementalButton: {
                if let savedScopes = self.savedScopes,
                   !savedScopes.wrappedValue.values.contains(self.fileScope.normalized)
                {
                    Button(String(localized: "Save as Named Scope…", table: "Document")) {
                        self.beginSavingScope()
                    }
                    .disabled(self.fileScope.normalized.isEmpty)
                }
            })
            .padding(.top)
        }
        .onChange(of: self.fileScope) {
            self.validationError = nil
        }
        .frame(minWidth: 400, idealWidth: 540)
        .sheet(isPresented: $isScopeSaveViewPresented) {
            if let savedScopes = self.savedScopes {
                ScopeSaveView(scopes: savedScopes, scope: self.fileScope.normalized) {
                    self.completionHandler(self.fileScope.normalized)
                    self.dismiss()
                }
                .scenePadding()
                .presentationSizing(.fitted)
            }
        }
    }
    
    
    /// The picker to select the rule conjunction, embedded in the description sentence.
    private var conjunctionPicker: some View {
        
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            let prefix = String(localized: "FileScope.Conjunction.prefix",
                                defaultValue: "Match",
                                table: "Document",
                                comment: "The text preceding the any/all popup in the sentence “Match [any|all] of the following conditions:”; can be empty.")
            if !prefix.isEmpty {
                Text(prefix)
            }
            
            Picker(selection: $fileScope.conjunction) {
                ForEach(FileScope.Conjunction.allCases, id: \.self) {
                    Text($0.label)
                }
            } label: {
                EmptyView()
            }
            .labelsHidden()
            
            Text(String(localized: "FileScope.Conjunction.suffix",
                        defaultValue: "of the following conditions:",
                        table: "Document",
                        comment: "The text following the any/all popup in the sentence “Match [any|all] of the following conditions:”."))
        }
    }
    
    
    /// Applies the current file scope and closes the sheet.
    private func apply() {
        
        let fileScope = self.fileScope.normalized
        
        do {
            try fileScope.validate()
        } catch {
            self.validationError = error
            return
        }
        
        self.completionHandler(fileScope)
        self.dismiss()
    }
    
    
    /// Validates the current file scope and presents the sheet to save it as a named scope.
    private func beginSavingScope() {
        
        let fileScope = self.fileScope.normalized
        
        do {
            try fileScope.validate()
        } catch {
            self.validationError = error
            return
        }
        
        self.isScopeSaveViewPresented = true
    }
}


private struct ScopeSaveView: View {
    
    private enum Focus {
        
        case field
    }
    
    
    @Binding var scopes: [String: FileScope]
    var scope: FileScope
    var completionHandler: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focus: Focus?
    @State private var name = ""
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Form {
                TextField(String(localized: "ScopeSaveView.label", defaultValue: "Save as:", table: "Document"),
                          text: $name,
                          prompt: Text(String(localized: "ScopeSaveView.field.label", defaultValue: "Name", table: "Document")))
                .focused($focus, equals: .field)
                .onSubmit(self.submit)
            }
            
            SubmitButtonGroup(String(localized: "Action.save.label", defaultValue: "Save"), action: self.submit)
                .padding(.top)
        }
        .onAppear {
            self.focus = .field
        }
        .frame(idealWidth: 300)
    }
    
    
    /// Saves the scope under the input name and closes the sheet.
    private func submit() {
        
        let name = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty else { return NSSound.beep() }
        
        self.scopes[name.appendingUniqueNumber(in: self.scopes.keys)] = self.scope
        self.dismiss()
        self.completionHandler()
    }
}


private struct RuleEditor: NSViewRepresentable {
    
    @Binding var fileScope: FileScope
    
    
    func makeNSView(context: Context) -> NSRuleEditor {
        
        let ruleEditor = NSRuleEditor()
        ruleEditor.delegate = context.coordinator
        ruleEditor.nestingMode = .simple
        ruleEditor.canRemoveAllRows = false
        context.coordinator.apply(self.fileScope, to: ruleEditor)
        
        return ruleEditor
    }
    
    
    func updateNSView(_ nsView: NSRuleEditor, context: Context) {
        
        context.coordinator.fileScope = $fileScope
        
        if context.coordinator.fileScope(from: nsView).normalized != self.fileScope.normalized {
            context.coordinator.apply(self.fileScope, to: nsView)
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(fileScope: $fileScope)
    }
    
    
    @MainActor final class Coordinator: NSObject, NSRuleEditorDelegate, NSTextFieldDelegate {
        
        var fileScope: Binding<FileScope>
        
        private weak var ruleEditor: NSRuleEditor?
        private var updatesFileScope = true
        
        
        /// Initializes a rule editor coordinator.
        ///
        /// - Parameter fileScope: The file scope binding to update.
        init(fileScope: Binding<FileScope>) {
            
            self.fileScope = fileScope
        }
        
        
        /// Applies the given file scope to the rule editor.
        ///
        /// - Parameters:
        ///   - fileScope: The file scope to apply.
        ///   - ruleEditor: The rule editor to update.
        func apply(_ fileScope: FileScope, to ruleEditor: NSRuleEditor) {
            
            self.ruleEditor = ruleEditor
            self.updatesFileScope = false
            defer { self.updatesFileScope = true }
            
            if ruleEditor.numberOfRows > 0 {
                ruleEditor.removeRows(at: IndexSet(integersIn: 0..<ruleEditor.numberOfRows), includeSubrows: true)
            }
            
            let rules = fileScope.rules.isEmpty ? [.placeholder] : fileScope.rules
            
            for rule in rules {
                let row = ruleEditor.numberOfRows
                ruleEditor.insertRow(at: row, with: .simple, asSubrowOfRow: -1, animate: false)
                
                ruleEditor.setCriteria([
                    Criterion(.target(rule.target)),
                    Criterion(.comparison(rule.comparison)),
                    Criterion(.value),
                ], andDisplayValues: [
                    rule.target.label,
                    rule.comparison.label,
                    self.createTextField(value: rule.value, comparison: rule.comparison),
                ], forRowAt: row)
            }
        }
        
        
        // MARK: Delegate Methods
        
        func ruleEditor(_ editor: NSRuleEditor, numberOfChildrenForCriterion criterion: Any?, with rowType: NSRuleEditor.RowType) -> Int {
            
            self.children(of: criterion as? Criterion, with: rowType).count
        }
        
        
        func ruleEditor(_ editor: NSRuleEditor, child index: Int, forCriterion criterion: Any?, with rowType: NSRuleEditor.RowType) -> Any {
            
            self.children(of: criterion as? Criterion, with: rowType)[index]
        }
        
        
        func ruleEditor(_ editor: NSRuleEditor, displayValueForCriterion criterion: Any, inRow row: Int) -> Any {
            
            guard let criterion = criterion as? Criterion else { return "" }
            
            return switch criterion.kind {
                case .target(let target):
                    target.label
                case .comparison(let comparison):
                    comparison.label
                case .value:
                    self.textField(in: editor, row: row)
            }
        }
        
        
        func ruleEditorRowsDidChange(_ notification: Notification) {
            
            self.updateFileScope()
        }
        
        
        func controlTextDidChange(_ notification: Notification) {
            
            self.updateFileScope()
        }
        
        
        // MARK: Private Methods
        
        /// Returns the child criteria of the given criterion.
        ///
        /// - Parameters:
        ///   - criterion: The parent criterion, or `nil` for the root.
        ///   - rowType: The row type.
        /// - Returns: The child criteria.
        private func children(of criterion: Criterion?, with rowType: NSRuleEditor.RowType) -> [Criterion] {
            
            guard let criterion else {
                guard rowType == .simple else { return [] }
                return FileScope.Rule.Target.allCases.map { Criterion(.target($0)) }
            }
            
            return switch criterion.kind {
                case .target:
                    FileScope.Rule.Comparison.allCases.map { Criterion(.comparison($0)) }
                case .comparison:
                    [Criterion(.value)]
                case .value:
                    []
            }
        }
        
        
        /// Returns the text field already displayed in the row to reuse it on the row reconfiguration.
        ///
        /// Reusing the display value keeps the user’s input and the field geometry
        /// when another criterion in the same row is changed.
        ///
        /// - Parameters:
        ///   - ruleEditor: The rule editor to inspect.
        ///   - row: The row index.
        /// - Returns: The text field currently displayed in the row, or `nil` if not found.
        private func existingTextField(in ruleEditor: NSRuleEditor, row: Int) -> RegularExpressionTextField? {
            
            guard row < ruleEditor.numberOfRows else { return nil }
            
            return ruleEditor.displayValues(forRow: row)
                .compactMap { $0 as? RegularExpressionTextField }
                .first
        }
        
        
        /// Updates the bound file scope from the rule editor.
        private func updateFileScope() {
            
            guard self.updatesFileScope, let ruleEditor else { return }
            
            self.fileScope.wrappedValue = self.fileScope(from: ruleEditor)
        }
        
        
        /// Returns a file scope from the rule editor.
        ///
        /// The conjunction is not editable in the rule editor and is therefore
        /// taken over from the currently bound file scope.
        ///
        /// - Parameter ruleEditor: The rule editor to read.
        /// - Returns: The current file scope.
        func fileScope(from ruleEditor: NSRuleEditor) -> FileScope {
            
            let rules = ruleEditor.subrowIndexes(forRow: -1)
                .compactMap { self.rule(from: ruleEditor, row: $0) }
            
            return FileScope(conjunction: self.fileScope.wrappedValue.conjunction, rules: rules)
        }
        
        
        /// Returns a rule from the row.
        ///
        /// - Parameters:
        ///   - ruleEditor: The rule editor to read.
        ///   - row: The row index to read.
        /// - Returns: The file scope rule.
        private func rule(from ruleEditor: NSRuleEditor, row: Int) -> FileScope.Rule? {
            
            let criteria = ruleEditor.criteria(forRow: row).compactMap { $0 as? Criterion }
            
            guard
                let target = criteria.compactMap(\.kind.target).first,
                let comparison = criteria.compactMap(\.kind.comparison).first
            else { return nil }
            
            let value = ruleEditor.displayValues(forRow: row)
                .compactMap { ($0 as? NSTextField)?.stringValue }
                .last ?? ""
            
            return FileScope.Rule(target: target, comparison: comparison, value: value)
        }
        
        
        /// Returns a configured text field for the rule value in the row.
        ///
        /// - Parameters:
        ///   - ruleEditor: The rule editor to inspect.
        ///   - row: The row index.
        /// - Returns: The text field.
        private func textField(in ruleEditor: NSRuleEditor, row: Int) -> RegularExpressionTextField {
            
            let comparison = ruleEditor.criteria(forRow: row)
                .compactMap { ($0 as? Criterion)?.kind.comparison }
                .first
            
            let textField = self.existingTextField(in: ruleEditor, row: row)
                ?? self.createTextField(value: "", comparison: comparison)
            textField.isRegexHighlighted = (comparison == .matchesRegularExpression)
            
            return textField
        }
        
        
        /// Creates a text field for a text rule value.
        ///
        /// - Parameters:
        ///   - value: The text field string value.
        ///   - comparison: The comparison kind for the rule, if available.
        /// - Returns: The text field.
        private func createTextField(value: String, comparison: FileScope.Rule.Comparison?) -> RegularExpressionTextField {
            
            let textField = FillingTextField(string: value)
            textField.isRegexHighlighted = (comparison == .matchesRegularExpression)
            textField.delegate = self
            textField.focusRingType = .none
            textField.controlSize = .small
            textField.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            textField.frame.size.width = 180
            
            return textField
        }
    }
}


/// A regular expression text field that stretches itself to fill the remaining width of a rule editor row.
///
/// `NSRuleEditor` lays out display value views only with their requested widths
/// and reimposes those widths on every layout pass; therefore, the field instead
/// intercepts the imposed frames and extends them by itself up to the trailing row buttons.
/// (2026-07, macOS 27 beta 3, FB23616278)
private final class FillingTextField: RegularExpressionTextField {
    
    override var frame: NSRect {
        
        get { super.frame }
        set { super.frame = self.filling(newValue) }
    }
    
    
    override func setFrameSize(_ newSize: NSSize) {
        
        var frame = self.frame
        frame.size = newSize
        
        super.setFrameSize(self.filling(frame).size)
    }
    
    
    /// Extends the given frame to fill the remaining width of the rule editor row.
    ///
    /// - Parameter frame: The proposed frame.
    /// - Returns: The extended frame.
    private func filling(_ frame: NSRect) -> NSRect {
        
        guard let rowView = self.superview else { return frame }
        
        // the add/remove row buttons are the only right-anchored views in a row
        let buttonMinX = rowView.subviews
            .filter { $0 !== self && $0.autoresizingMask.contains(.minXMargin) }
            .map(\.frame.minX)
            .min()
        
        guard let buttonMinX else { return frame }
        
        var frame = frame
        frame.size.width = max(buttonMinX - 6 - frame.minX, 40)  // 6: the standard slice gap
        
        return frame
    }
}


// MARK: - Private Models

private final class Criterion: NSObject {
    
    enum Kind: Hashable {
        
        case target(FileScope.Rule.Target)
        case comparison(FileScope.Rule.Comparison)
        case value
    }
    
    
    let kind: Kind
    
    
    /// Initializes with a kind.
    ///
    /// - Parameter kind: The criterion kind.
    init(_ kind: Kind) {
        
        self.kind = kind
    }
    
    
    override var hash: Int {
        
        self.kind.hashValue
    }
    
    
    override func isEqual(_ object: Any?) -> Bool {
        
        (object as? Criterion)?.kind == self.kind
    }
}


private extension Criterion.Kind {
    
    /// The target value if the criterion represents a rule target.
    var target: FileScope.Rule.Target? {
        
        switch self {
            case .target(let target): target
            default: nil
        }
    }
    
    
    /// The comparison value if the criterion represents a rule comparison.
    var comparison: FileScope.Rule.Comparison? {
        
        switch self {
            case .comparison(let comparison): comparison
            default: nil
        }
    }
}


// MARK: - Private Extensions

private extension FileScope.Rule {
    
    /// The empty rule displayed in the rule editor as a placeholder for an empty scope.
    static let placeholder = Self(target: .filename, comparison: .contains, value: "")
}


private extension FileScope {
    
    /// The file scope without placeholder rules.
    var normalized: Self {
        
        Self(conjunction: self.conjunction, rules: self.rules.filter { $0 != .placeholder })
    }
}


// MARK: - Localization

private extension FileScope.Conjunction {
    
    /// The localized label.
    var label: String {
        
        switch self {
            case .any:
                String(localized: "FileScope.Conjunction.any.label",
                       defaultValue: "any",
                       table: "Document",
                       comment: "The popup item inserted into the sentence “Match [any|all] of the following conditions:”.")
            case .all:
                String(localized: "FileScope.Conjunction.all.label",
                       defaultValue: "all",
                       table: "Document",
                       comment: "The popup item inserted into the sentence “Match [any|all] of the following conditions:”.")
        }
    }
}


extension FileScope.Error: @retroactive LocalizedError {
    
    public var errorDescription: String? {
        
        switch self {
            case .emptyValue:
                String(localized: "FileScope.Error.emptyValue.message",
                       defaultValue: "The scope contains a rule without a value.",
                       table: "Document")
            case .invalidRegularExpression:
                String(localized: "FileScope.Error.invalidRegularExpression.message",
                       defaultValue: "The scope contains an invalid regular expression.",
                       table: "Document")
        }
    }
}


private extension FileScope.Rule.Target {
    
    /// The localized label.
    var label: String {
        
        switch self {
            case .filename:
                String(localized: "FileScope.Rule.Target.filename.label",
                       defaultValue: "File name",
                       table: "Document")
            case .filePath:
                String(localized: "FileScope.Rule.Target.filePath.label",
                       defaultValue: "File path",
                       table: "Document")
            case .fileExtension:
                String(localized: "FileScope.Rule.Target.fileExtension.label",
                       defaultValue: "File extension",
                       table: "Document")
        }
    }
}


private extension FileScope.Rule.Comparison {
    
    /// The localized label.
    var label: String {
        
        switch self {
            case .contains:
                String(localized: "FileScope.Rule.Comparison.contains.label",
                       defaultValue: "contains",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .doesNotContain:
                String(localized: "FileScope.Rule.Comparison.doesNotContain.label",
                       defaultValue: "does not contain",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .isEqualTo:
                String(localized: "FileScope.Rule.Comparison.isEqualTo.label",
                       defaultValue: "is",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .isNotEqualTo:
                String(localized: "FileScope.Rule.Comparison.isNotEqualTo.label",
                       defaultValue: "is not",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .startsWith:
                String(localized: "FileScope.Rule.Comparison.startsWith.label",
                       defaultValue: "begins with",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .endsWith:
                String(localized: "FileScope.Rule.Comparison.endsWith.label",
                       defaultValue: "ends with",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .matchesRegularExpression:
                String(localized: "FileScope.Rule.Comparison.matchesRegularExpression.label",
                       defaultValue: "matches regular expression",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
        }
    }
}


// MARK: - Preview

#Preview {
    FolderFindFileScopeView(fileScope: .init()) { _ in }
        .scenePadding()
}
