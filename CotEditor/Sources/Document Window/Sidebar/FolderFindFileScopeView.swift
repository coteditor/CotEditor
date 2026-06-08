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

struct FolderFindFileScopeView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var fileScope: FileScope
    @State private var validationError: FileScope.Error?
    
    private var completionHandler: (FileScope) -> Void
    
    
    /// Initializes a file scope editor view.
    ///
    /// - Parameters:
    ///   - fileScope: The initial file scope.
    ///   - completionHandler: The handler to call with the updated file scope.
    init(fileScope: FileScope, completionHandler: @escaping (FileScope) -> Void) {
        
        self._fileScope = State(initialValue: fileScope)
        self.completionHandler = completionHandler
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Any of the following conditions are met:", tableName: "Document")
            RuleEditor(fileScope: $fileScope)
            
            if let validationError {
                Label(validationError.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
            }
            
            SubmitButtonGroup(action: self.apply)
                .padding(.top)
        }
        .onChange(of: self.fileScope) {
            self.validationError = nil
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
            
            let rules = fileScope.rules.isEmpty
                ? [FileScope.Rule(target: .filename, comparison: .contains, value: "")]
                : fileScope.rules
            
            for rule in rules {
                let row = ruleEditor.numberOfRows
                ruleEditor.insertRow(at: row, with: .simple, asSubrowOfRow: -1, animate: false)
                ruleEditor.setCriteria([
                    Criterion(rule.target),
                    Criterion(rule.comparison),
                    Criterion(.value),
                ], andDisplayValues: [
                    rule.target.label,
                    rule.comparison.label,
                    self.textField(value: rule.value),
                ], forRowAt: row)
            }
        }
        
        
        func ruleEditor(_ editor: NSRuleEditor, numberOfChildrenForCriterion criterion: Any?, with rowType: NSRuleEditor.RowType) -> Int {
            
            guard let criterion = criterion as? Criterion else {
                return switch rowType {
                    case .compound:
                        0
                    case .simple:
                        FileScope.Rule.Target.allCases.count
                    @unknown default:
                        0
                }
            }
            
            return switch criterion.kind {
                case .target: FileScope.Rule.Comparison.allCases.count
                case .comparison: 1
                case .value: 0
            }
        }
        
        
        func ruleEditor(_ editor: NSRuleEditor, child index: Int, forCriterion criterion: Any?, with rowType: NSRuleEditor.RowType) -> Any {
            
            guard let criterion = criterion as? Criterion else {
                return switch rowType {
                    case .compound:
                        Criterion(.value)
                    case .simple:
                        Criterion(FileScope.Rule.Target.allCases[index])
                    @unknown default:
                        Criterion(.value)
                }
            }
            
            return switch criterion.kind {
                case .target:
                    Criterion(FileScope.Rule.Comparison.allCases[index])
                case .comparison:
                    Criterion(.value)
                case .value:
                    Criterion(.value)
            }
        }
        
        
        func ruleEditor(_ editor: NSRuleEditor, displayValueForCriterion criterion: Any, inRow row: Int) -> Any {
            
            guard let criterion = criterion as? Criterion else { return "" }
            
            return switch criterion.kind {
                case .target(let target):
                    target.label
                case .comparison(let comparison):
                    comparison.label
                case .value:
                    self.textField(value: "")
            }
        }
        
        
        func ruleEditorRowsDidChange(_ notification: Notification) {
            
            self.updateFileScope()
        }
        
        
        func controlTextDidChange(_ notification: Notification) {
            
            self.updateFileScope()
        }
        
        
        /// Updates the bound file scope from the rule editor.
        private func updateFileScope() {
            
            guard self.updatesFileScope, let ruleEditor else { return }
            
            self.fileScope.wrappedValue = self.fileScope(from: ruleEditor)
        }
        
        
        /// Returns a file scope from the rule editor.
        ///
        /// - Parameter ruleEditor: The rule editor to read.
        /// - Returns: The current file scope.
        private func fileScope(from ruleEditor: NSRuleEditor) -> FileScope {
            
            let rules = ruleEditor.subrowIndexes(forRow: -1)
                .compactMap { self.rule(from: ruleEditor, row: $0) }
            
            return FileScope(rules: rules)
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
        
        
        /// Creates a text field for a rule value.
        ///
        /// - Parameter value: The text field string value.
        /// - Returns: The text field.
        private func textField(value: String) -> NSTextField {
            
            let textField = NSTextField(string: value)
            
            textField.delegate = self
            textField.controlSize = .small
            textField.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            textField.frame.size.width = 180
            
            return textField
        }
    }
}


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
    
    
    /// Initializes with a target.
    ///
    /// - Parameter target: The file scope target.
    convenience init(_ target: FileScope.Rule.Target) {
        
        self.init(.target(target))
    }
    
    
    /// Initializes with a comparison.
    ///
    /// - Parameter comparison: The file scope comparison.
    convenience init(_ comparison: FileScope.Rule.Comparison) {
        
        self.init(.comparison(comparison))
    }
    
    
    override var hash: Int {
        
        self.kind.hashValue
    }
    
    
    override func isEqual(_ object: Any?) -> Bool {
        
        (object as? Criterion)?.kind == self.kind
    }
}


private extension Criterion.Kind {
    
    /// The target value if the criterion represents a target.
    var target: FileScope.Rule.Target? {
        
        switch self {
            case .target(let target):
                target
            default:
                nil
        }
    }
    
    
    /// The comparison value if the criterion represents a comparison.
    var comparison: FileScope.Rule.Comparison? {
        
        switch self {
            case .comparison(let comparison):
                comparison
            default:
                nil
        }
    }
}


private extension FileScope {
    
    /// The file scope without no-op default rules.
    var normalized: Self {
        
        Self(rules: self.rules.filter {
            $0.target != .filename || $0.comparison != .contains || !$0.value.isEmpty
        })
    }
}


extension FileScope.Error: @retroactive LocalizedError {
    
    public var errorDescription: String? {
        
        switch self {
            case .emptyValue:
                String(localized: "FileScope.Error.emptyValue.message",
                       defaultValue: "The file scope contains a rule without a value.",
                       table: "Document")
            case .invalidRegularExpression:
                String(localized: "FileScope.Error.invalidRegularExpression.message",
                       defaultValue: "The file scope contains an invalid regular expression.",
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
                       table: "Document")
            case .isEqualTo:
                String(localized: "FileScope.Rule.Comparison.isEqualTo.label",
                       defaultValue: "is equal to",
                       table: "Document")
            case .isNotEqualTo:
                String(localized: "FileScope.Rule.Comparison.isNotEqualTo.label",
                       defaultValue: "is not equal to",
                       table: "Document")
            case .startsWith:
                String(localized: "FileScope.Rule.Comparison.startsWith.label",
                       defaultValue: "starts with",
                       table: "Document")
            case .endsWith:
                String(localized: "FileScope.Rule.Comparison.endsWith.label",
                       defaultValue: "ends with",
                       table: "Document")
            case .matchesRegularExpression:
                String(localized: "FileScope.Rule.Comparison.matchesRegularExpression.label",
                       defaultValue: "matches regular expression",
                       table: "Document")
        }
    }
}
