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
            
            SubmitButtonGroup(helpAnchor: "howto_find_in_folder", action: self.apply, supplementalButton: {
                Button(String(localized: "Action.removeAll.label", defaultValue: "Remove All"), action: self.clear)
                    .disabled(self.fileScope.normalized.isEmpty)
            })
            .padding(.top)
        }
        .onChange(of: self.fileScope) {
            self.validationError = nil
        }
    }
    
    
    /// Clears the file scope.
    private func clear() {
        
        self.fileScope = FileScope()
        self.validationError = nil
    }
    
    
    /// Applies the current file scope and closes the sheet.
    private func apply() {
        
        let fileScope = self.fileScope.normalized
        
        do {
            try fileScope.validate(maximumFileSize: FolderFind.Options().maximumFileSize)
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
            
            let rules = fileScope.rules.isEmpty
                ? [FileScope.Rule(target: .filename, comparison: .contains, value: "")]
                : fileScope.rules
            
            for rule in rules {
                let row = ruleEditor.numberOfRows
                ruleEditor.insertRow(at: row, with: .simple, asSubrowOfRow: -1, animate: false)
                
                switch rule {
                    case .text(let rule):
                        ruleEditor.setCriteria([
                            Criterion(rule.target),
                            Criterion(rule.comparison),
                            Criterion(.value),
                        ], andDisplayValues: [
                            rule.target.label,
                            rule.comparison.label,
                            self.textField(value: rule.value),
                        ], forRowAt: row)
                    
                    case .fileSize(let rule):
                        ruleEditor.setCriteria([
                            Criterion(.sizeTarget),
                            Criterion(rule.comparison),
                            Criterion(.sizeValue),
                            Criterion(rule.unit),
                        ], andDisplayValues: [
                            Self.sizeTargetLabel,
                            rule.comparison.label,
                            self.sizeField(value: rule.value),
                            rule.unit.label,
                        ], forRowAt: row)
                }
            }
        }
        
        
        func ruleEditor(_ editor: NSRuleEditor, numberOfChildrenForCriterion criterion: Any?, with rowType: NSRuleEditor.RowType) -> Int {
            
            guard let criterion = criterion as? Criterion else {
                return switch rowType {
                    case .compound:
                        0
                    case .simple:
                        FileScope.TextRule.Target.allCases.count + 1  // + file size target
                    @unknown default:
                        0
                }
            }
            
            return switch criterion.kind {
                case .target: FileScope.TextRule.Comparison.allCases.count
                case .comparison: 1
                case .value: 0
                case .sizeTarget: FileScope.FileSizeRule.Comparison.allCases.count
                case .sizeComparison: 1
                case .sizeValue: FileScope.FileSizeRule.Unit.allCases.count
                case .sizeUnit: 0
            }
        }
        
        
        func ruleEditor(_ editor: NSRuleEditor, child index: Int, forCriterion criterion: Any?, with rowType: NSRuleEditor.RowType) -> Any {
            
            guard let criterion = criterion as? Criterion else {
                return switch rowType {
                    case .compound:
                        Criterion(.value)
                    case .simple:
                        (index < FileScope.TextRule.Target.allCases.count)
                            ? Criterion(FileScope.TextRule.Target.allCases[index])
                            : Criterion(.sizeTarget)
                    @unknown default:
                        Criterion(.value)
                }
            }
            
            return switch criterion.kind {
                case .target:
                    Criterion(FileScope.TextRule.Comparison.allCases[index])
                case .comparison:
                    Criterion(.value)
                case .value:
                    Criterion(.value)
                case .sizeTarget:
                    Criterion(FileScope.FileSizeRule.Comparison.allCases[index])
                case .sizeComparison:
                    Criterion(.sizeValue)
                case .sizeValue:
                    Criterion(FileScope.FileSizeRule.Unit.allCases[index])
                case .sizeUnit:
                    Criterion(.sizeUnit(FileScope.FileSizeRule.Unit.allCases[index]))
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
                case .sizeTarget:
                    Self.sizeTargetLabel
                case .sizeComparison(let comparison):
                    comparison.label
                case .sizeValue:
                    self.sizeField(value: nil)
                case .sizeUnit(let unit):
                    unit.label
            }
        }
        
        
        func ruleEditorRowsDidChange(_ notification: Notification) {
            
            self.updateFileScope()
        }
        
        
        func controlTextDidChange(_ notification: Notification) {
            
            self.updateFileScope()
        }
        
        
        // MARK: Private Methods
        
        /// The localized label for the file size target.
        private static let sizeTargetLabel = String(localized: "FileScope.Rule.Target.fileSize.label",
                                                    defaultValue: "File size",
                                                    table: "Document")
        
        
        /// Updates the bound file scope from the rule editor.
        private func updateFileScope() {
            
            guard self.updatesFileScope, let ruleEditor else { return }
            
            self.fileScope.wrappedValue = self.fileScope(from: ruleEditor)
        }
        
        
        /// Returns a file scope from the rule editor.
        ///
        /// - Parameter ruleEditor: The rule editor to read.
        /// - Returns: The current file scope.
        func fileScope(from ruleEditor: NSRuleEditor) -> FileScope {
            
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
            let displayValues = ruleEditor.displayValues(forRow: row)
            
            if criteria.contains(where: { $0.kind == .sizeTarget }) {
                guard
                    let comparison = criteria.compactMap(\.kind.sizeComparison).first,
                    let unit = criteria.compactMap(\.kind.sizeUnit).first
                else { return nil }
                
                let value = displayValues
                    .compactMap { ($0 as? NSTextField)?.doubleValue }
                    .last ?? 0
                
                return .fileSize(FileScope.FileSizeRule(comparison: comparison, value: value, unit: unit))
            
            } else {
                guard
                    let target = criteria.compactMap(\.kind.target).first,
                    let comparison = criteria.compactMap(\.kind.comparison).first
                else { return nil }
                
                let value = displayValues
                    .compactMap { ($0 as? NSTextField)?.stringValue }
                    .last ?? ""
                
                return .text(FileScope.TextRule(target: target, comparison: comparison, value: value))
            }
        }
        
        
        /// Creates a text field for a text rule value.
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
        
        
        /// Creates a text field for a file size rule value.
        ///
        /// - Parameter value: The size value to display, or `nil` to leave the field empty.
        /// - Returns: The text field.
        private func sizeField(value: Double?) -> NSTextField {
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.usesGroupingSeparator = false
            formatter.minimum = 0
            formatter.isLenient = true
            
            let textField = NSTextField(string: "")
            textField.delegate = self
            textField.controlSize = .small
            textField.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            textField.formatter = formatter
            textField.frame.size.width = 96
            if let value {
                textField.objectValue = value
            }
            
            return textField
        }
    }
}


private final class Criterion: NSObject {
    
    enum Kind: Hashable {
        
        case target(FileScope.TextRule.Target)
        case comparison(FileScope.TextRule.Comparison)
        case value
        case sizeTarget
        case sizeComparison(FileScope.FileSizeRule.Comparison)
        case sizeValue
        case sizeUnit(FileScope.FileSizeRule.Unit)
    }
    
    
    let kind: Kind
    
    
    /// Initializes with a kind.
    ///
    /// - Parameter kind: The criterion kind.
    init(_ kind: Kind) {
        
        self.kind = kind
    }
    
    
    /// Initializes with a text rule target.
    ///
    /// - Parameter target: The text rule target.
    convenience init(_ target: FileScope.TextRule.Target) {
        
        self.init(.target(target))
    }
    
    
    /// Initializes with a text rule comparison.
    ///
    /// - Parameter comparison: The text rule comparison.
    convenience init(_ comparison: FileScope.TextRule.Comparison) {
        
        self.init(.comparison(comparison))
    }
    
    
    /// Initializes with a file size rule comparison.
    ///
    /// - Parameter comparison: The file size rule comparison.
    convenience init(_ comparison: FileScope.FileSizeRule.Comparison) {
        
        self.init(.sizeComparison(comparison))
    }
    
    
    /// Initializes with a file size unit.
    ///
    /// - Parameter unit: The file size unit.
    convenience init(_ unit: FileScope.FileSizeRule.Unit) {
        
        self.init(.sizeUnit(unit))
    }
    
    
    override var hash: Int {
        
        self.kind.hashValue
    }
    
    
    override func isEqual(_ object: Any?) -> Bool {
        
        (object as? Criterion)?.kind == self.kind
    }
}


private extension Criterion.Kind {
    
    /// The target value if the criterion represents a text rule target.
    var target: FileScope.TextRule.Target? {
        
        switch self {
            case .target(let target):
                target
            default:
                nil
        }
    }
    
    
    /// The comparison value if the criterion represents a text rule comparison.
    var comparison: FileScope.TextRule.Comparison? {
        
        switch self {
            case .comparison(let comparison):
                comparison
            default:
                nil
        }
    }
    
    
    /// The comparison value if the criterion represents a file size rule comparison.
    var sizeComparison: FileScope.FileSizeRule.Comparison? {
        
        switch self {
            case .sizeComparison(let comparison):
                comparison
            default:
                nil
        }
    }
    
    
    /// The unit value if the criterion represents a file size unit.
    var sizeUnit: FileScope.FileSizeRule.Unit? {
        
        switch self {
            case .sizeUnit(let unit):
                unit
            default:
                nil
        }
    }
}


private extension FileScope {
    
    /// The file scope without no-op default rules.
    var normalized: Self {
        
        Self(rules: self.rules.filter { rule in
            switch rule {
                case .text(let rule):
                    rule.target != .filename || rule.comparison != .contains || !rule.value.isEmpty
                case .fileSize:
                    true
            }
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
            case .invalidSizeValue:
                String(localized: "FileScope.Error.invalidSizeValue.message",
                       defaultValue: "The file scope contains a rule with an invalid file size value.",
                       table: "Document")
            case .unreachableSizeValue(let maximumFileSize):
                String(localized: "FileScope.Error.unreachableSizeValue.message",
                       defaultValue: "The file scope contains a file size rule exceeding the maximum searchable file size (\(maximumFileSize.formatted(.byteCount(style: .file)))).",
                       table: "Document")
        }
    }
}


private extension FileScope.TextRule.Target {
    
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


private extension FileScope.TextRule.Comparison {
    
    /// The localized label.
    var label: String {
        
        switch self {
            case .contains:
                String(localized: "FileScope.TextRule.Comparison.contains.label",
                       defaultValue: "contains",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .isEqualTo:
                String(localized: "FileScope.TextRule.Comparison.isEqualTo.label",
                       defaultValue: "is",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .isNotEqualTo:
                String(localized: "FileScope.TextRule.Comparison.isNotEqualTo.label",
                       defaultValue: "is not",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .startsWith:
                String(localized: "FileScope.TextRule.Comparison.startsWith.label",
                       defaultValue: "begins with",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .endsWith:
                String(localized: "FileScope.TextRule.Comparison.endsWith.label",
                       defaultValue: "ends with",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .matchesRegularExpression:
                String(localized: "FileScope.TextRule.Comparison.matchesRegularExpression.label",
                       defaultValue: "matches regular expression",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
        }
    }
}


private extension FileScope.FileSizeRule.Comparison {
    
    /// The localized label.
    var label: String {
        
        switch self {
            case .isEqualTo:
                String(localized: "FileScope.FileSizeRule.Comparison.isEqualTo.label",
                       defaultValue: "is",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .isLessThan:
                String(localized: "FileScope.FileSizeRule.Comparison.isLessThan.label",
                       defaultValue: "is less than",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
            case .isGreaterThan:
                String(localized: "FileScope.FileSizeRule.Comparison.isGreaterThan.label",
                       defaultValue: "is greater than",
                       table: "Document",
                       comment: "This is immediately followed by the value field.")
        }
    }
}


private extension FileScope.FileSizeRule.Unit {
    
    /// The localized label.
    var label: String {
        
        switch self {
            case .bytes:
                String(localized: "FileScope.FileSizeRule.Unit.bytes.label",
                       defaultValue: "bytes",
                       table: "Document")
            case .kilobytes:
                String(localized: "FileScope.FileSizeRule.Unit.kilobytes.label",
                       defaultValue: "KB",
                       table: "Document")
            case .megabytes:
                String(localized: "FileScope.FileSizeRule.Unit.megabytes.label",
                       defaultValue: "MB",
                       table: "Document")
        }
    }
}


// MARK: - Preview

#Preview {
    FolderFindFileScopeView(fileScope: .init()) { _ in }
        .scenePadding()
}
