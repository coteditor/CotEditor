//
//  MultipleReplaceView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2025 1024jp
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

import AppKit
import SwiftUI
import Defaults
import TextFind

struct MultipleReplaceView: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = MultipleReplaceViewController
    
    @Binding var setting: MultipleReplace
    var updateHandler: (MultipleReplace) -> Void
    
    
    func makeNSViewController(context: Context) -> MultipleReplaceViewController {
        
        NSStoryboard(name: "MultipleReplaceView", bundle: nil).instantiateInitialController { coder in
            MultipleReplaceViewController(coder: coder, updateHandler: self.updateHandler)
        }!
    }
    
    
    func updateNSViewController(_ nsViewController: MultipleReplaceViewController, context: Context) {
        
        nsViewController.change(setting: self.setting)
    }
}


final class MultipleReplaceViewController: NSViewController, NSUserInterfaceValidations {
    
    // MARK: Private Properties
    
    private let updateHandler: (MultipleReplace) -> Void
    
    private var definition = MultipleReplace()
    private lazy var updateNotificationDebouncer = Debouncer(delay: .seconds(1)) { [weak self] in self?.notifyUpdate() }
    
    @objc private dynamic var hasInvalidSetting = false
    @objc private dynamic var resultMessage: String?
    
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private weak var addRemoveButton: NSSegmentedControl?
    
    
    // MARK: Lifecycle
    
    required init?(coder: NSCoder, updateHandler: @escaping (MultipleReplace) -> Void) {
        
        self.updateHandler = updateHandler
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // register dragged type
        self.tableView?.registerForDraggedTypes([.row])
        self.tableView?.setDraggingSourceOperationMask([.delete], forLocal: false)
        
        self.addRemoveButton?.setToolTip(String(localized: "Action.add.tooltip", defaultValue: "Add new item"), forSegment: 0)
        self.addRemoveButton?.setToolTip(String(localized: "Action.delete.tooltip", defaultValue: "Delete selected items"), forSegment: 1)
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.updateNotificationDebouncer.fireNow()
        self.resultMessage = nil
    }
    
    
    @discardableResult
    override func commitEditing() -> Bool {
        
        guard super.commitEditing() else { return false }
        
        // commit unsaved changes
        self.endEditing()
        self.updateNotificationDebouncer.fireNow()
        
        return true
    }
    
    
    // MARK: Actions
    
    func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(batchReplaceAll):
                return self.client?.isEditable == true
            case nil:
                return false
            default:
                return true
        }
    }
    
    
    /// The segmented control for the add/remove actions was clicked.
    @IBAction func addRemove(_ sender: NSSegmentedControl) {
        
        switch sender.selectedSegment {
            case 0: self.add(sender)
            case 1: self.remove(sender)
            default: preconditionFailure()
        }
    }
    
    
    /// Adds a new replacement rule at the end.
    @IBAction func add(_ sender: Any?) {
        
        self.endEditing()
        
        let row = self.tableView?.selectedRowIndexes.last?.advanced(by: 1) ?? self.definition.replacements.endIndex
        let replacements = [MultipleReplace.Replacement()]
        
        self.insertReplacements(replacements, at: [row])
        
        guard let tableView = self.tableView else { return }
        
        // start editing automatically
        let column = tableView.column(withIdentifier: .findString)
        tableView.selectRowIndexes([row], byExtendingSelection: false)
        tableView.scrollRowToVisible(row)
        tableView.editColumn(column, row: row, with: nil, select: true)
    }
    
    
    /// Removes selected replacement rules.
    @IBAction func remove(_ sender: Any?) {
        
        self.endEditing()
        
        guard let tableView = self.tableView else { return assertionFailure() }
        
        let rowIndexes = tableView.selectedRowIndexes
        
        self.removeReplacements(at: rowIndexes)
        
        if self.definition.replacements.isEmpty {
            self.add(nil)
        }
    }
    
    
    /// Shows the advanced options view.
    @IBAction func showOptions(_ sender: NSButton) {
        
        if let viewController = self.presentedViewControllers?.first(where: { $0 is NSHostingController<MultipleReplaceSettingsView> }) {
            return self.dismiss(viewController)
        }
        
        let view = MultipleReplaceSettingsView(settings: self.definition.settings) { settings in
            guard self.definition.settings != settings else { return }
            
            self.definition.settings = settings
            self.tableView?.reloadData()  // update regex highlight for replacement string
            self.updateNotificationDebouncer.schedule()
        }
        let viewController = NSHostingController(rootView: view)
        
        self.present(viewController, asPopoverRelativeTo: sender.bounds, of: sender, preferredEdge: .maxX, behavior: .transient)
    }
    
    
    /// Highlights all matches in the target textView.
    @IBAction func highlight(_ sender: Any?) {
        
        self.endEditing()
        self.validateObject()
        self.resultMessage = nil
        
        guard let textView = self.client else { return NSSound.beep() }
        
        let inSelection = UserDefaults.standard[.findInSelection]
        
        Task {
            self.resultMessage = try? await textView.highlight(self.definition, inSelection: inSelection)
        }
    }
    
    
    /// Performs replacement with current set.
    @IBAction func batchReplaceAll(_ sender: Any?) {
        
        self.endEditing()
        self.validateObject()
        self.resultMessage = nil
        
        guard
            let textView = self.client,
            textView.isEditable,
            textView.window?.attachedSheet == nil
        else { return NSSound.beep() }
        
        let inSelection = UserDefaults.standard[.findInSelection]
        
        Task {
            self.resultMessage = try? await textView.replaceAll(self.definition, inSelection: inSelection)
        }
    }
    
    
    // MARK: Public Methods
    
    /// Sets another replacement definition.
    ///
    /// - Parameter setting: The setting to replace.
    func change(setting: MultipleReplace) {
        
        guard setting != self.definition else { return }
        
        self.definition = setting
        self.hasInvalidSetting = false
        self.resultMessage = nil
        
        self.undoManager?.removeAllActions(withTarget: self)
        self.tableView?.reloadData()
        
        self.invalidateRemoveButton()
    }
    
    
    // MARK: Private Methods
    
    /// Target text view.
    var client: NSTextView? {
        
        NSApp.mainWindow?.firstResponder
            .map { sequence(first: $0, next: \.nextResponder) }?
            .compactMap { $0 as? NSTextView }
            .first { $0 is any TextFinderClient }
    }
    
    
    /// Notifies the update to delegate.
    private func notifyUpdate() {
        
        self.updateHandler(self.definition)
    }
    
    
    /// Validates the availability of the remove button.
    private func invalidateRemoveButton() {
        
        let canRemove = self.tableView?.selectedRowIndexes.isEmpty == false
        self.addRemoveButton?.setEnabled(canRemove, forSegment: 1)
    }
    
    
    /// Validates the current setting.
    private func validateObject() {
        
        self.hasInvalidSetting = self.definition.replacements.contains {
            do { try $0.validate() } catch { return true }
            return false
        }
    }
    
    
    /// Performs undoable insertion of replacement definitions.
    ///
    /// - Parameters:
    ///   - replacements: New replacement definitions to insert.
    ///   - rowIndexes: Rows of definitions to insert.
    private func insertReplacements(_ replacements: [MultipleReplace.Replacement], at rowIndexes: IndexSet) {
        
        assert(replacements.count == rowIndexes.count)
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { target in
                target.removeReplacements(at: rowIndexes)
            }
            if !undoManager.isUndoing {
                undoManager.setActionName(String(localized: "Insert Rule", table: "MultipleReplace", comment: "action name"))
            }
        }
        
        // update data
        self.definition.replacements.insert(replacements, at: rowIndexes)
        
        // update view
        if let tableView = self.tableView {
            tableView.insertRows(at: rowIndexes, withAnimation: .effectGap)
        }
        
        // notify modification
        self.updateNotificationDebouncer.schedule()
    }
    
    
    /// Performs undoable removal of replacement definitions.
    ///
    /// - Parameter rowIndexes: Rows of definitions to remove.
    private func removeReplacements(at rowIndexes: IndexSet) {
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { [replacements = self.definition.replacements.elements(at: rowIndexes)] target in
                target.insertReplacements(replacements, at: rowIndexes)
            }
            if !undoManager.isUndoing {
                undoManager.setActionName(String(localized: "Delete Rules", table: "MultipleReplace", comment: "action name"))
            }
        }
        
        // update view
        if let tableView = self.tableView {
            tableView.removeRows(at: rowIndexes, withAnimation: [.slideUp, .effectFade])
        }
        
        // update data
        self.definition.replacements.remove(in: rowIndexes)
        
        // notify modification
        self.updateNotificationDebouncer.schedule()
    }
    
    
    /// Performs undoable replacement definitions' update.
    ///
    /// - Parameters:
    ///   - replacements: New replacement definitions to update.
    ///   - rowIndexes: Rows of definitions to be updated.
    private func updateReplacements(_ replacements: [MultipleReplace.Replacement], at rowIndexes: IndexSet) {
        
        assert(replacements.count == rowIndexes.count)
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { [replacements = self.definition.replacements.elements(at: rowIndexes)] target in
                target.updateReplacements(replacements, at: rowIndexes)
            }
            if !undoManager.isUndoing {
                undoManager.setActionName(String(localized: "Edit Rule", table: "MultipleReplace", comment: "action name"))
            }
        }
        
        // update data
        for (row, replacement) in zip(rowIndexes, replacements) {
            self.definition.replacements[row] = replacement
        }
        
        // update view
        if let tableView = self.tableView {
            let allColumnIndexes = IndexSet(0..<tableView.numberOfColumns)
            tableView.reloadData(forRowIndexes: rowIndexes, columnIndexes: allColumnIndexes)
        }
        
        // notify modification
        self.updateNotificationDebouncer.schedule()
    }
    
    
    /// Performs undoable move of replacement definitions.
    ///
    /// - Parameters:
    ///   - sourceRows: Rows of definitions to move.
    ///   - destinationRows: Rows of definitions to place.
    private func moveReplacements(from sourceRows: IndexSet, to destinationRows: IndexSet) {
        
        assert(sourceRows.count == destinationRows.count)
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { target in
                target.moveReplacements(from: destinationRows, to: sourceRows)
            }
            if !undoManager.isUndoing {
                undoManager.setActionName(String(localized: "Move Rules", table: "MultipleReplace", comment: "action name"))
            }
        }
        
        // update data
        let draggingItems = self.definition.replacements.elements(at: sourceRows)
        self.definition.replacements.remove(in: sourceRows)
        self.definition.replacements.insert(draggingItems, at: destinationRows)
        
        // update view
        if let tableView = self.tableView {
            tableView.beginUpdates()
            tableView.removeRows(at: sourceRows, withAnimation: [.effectFade, .slideDown])
            tableView.insertRows(at: destinationRows, withAnimation: .effectGap)
            tableView.selectRowIndexes(destinationRows, byExtendingSelection: false)
            tableView.endUpdates()
        }
        
        // notify modification
        self.updateNotificationDebouncer.schedule()
    }
}


// MARK: - TableView Data Source & Delegate

private extension NSUserInterfaceItemIdentifier {
    
    static let isEnabled = NSUserInterfaceItemIdentifier("isEnabled")
    static let findString = NSUserInterfaceItemIdentifier("findString")
    static let replacementString = NSUserInterfaceItemIdentifier("replacementString")
    static let usesRegularExpression = NSUserInterfaceItemIdentifier("usesRegularExpression")
    static let ignoresCase = NSUserInterfaceItemIdentifier("ignoresCase")
    static let description = NSUserInterfaceItemIdentifier("description")
}


private extension NSPasteboard.PasteboardType {
    
    static let row = NSPasteboard.PasteboardType("com.coteditor.row")
}


extension MultipleReplaceViewController: NSTableViewDelegate {
    
    /// Invoked when the selection did change.
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        self.invalidateRemoveButton()
    }
    
    
    /// Makes table cell view.
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard
            let replacement = self.definition.replacements[safe: row],
            let identifier = tableColumn?.identifier,
            let cellView = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView
        else { return nil }
        
        cellView.objectValue = switch identifier {
            case .isEnabled:
                replacement.isEnabled
            case .findString:
                replacement.findString
            case .replacementString:
                replacement.replacementString
            case .ignoresCase:
                replacement.ignoresCase
            case .usesRegularExpression:
                replacement.usesRegularExpression
            case .description:
                replacement.description
            default:
                preconditionFailure()
        }
        
        // update regex field
        if let field = cellView.textField as? RegularExpressionTextField {
            field.isRegexHighlighted = replacement.isEnabled && replacement.usesRegularExpression
            field.unescapesReplacement = self.definition.settings.unescapesReplacementString
        }
        
        // update warning icon
        if identifier == .findString, let imageView = cellView.imageView {
            let errorMessage: String? = {
                do throws(TextFind.Error) {
                    try replacement.validate(regexOptions: self.definition.settings.regexOptions)
                } catch {
                    guard let suggestion = error.recoverySuggestion else { return error.localizedDescription }
                    
                    return "[" + error.localizedDescription + "] " + suggestion
                }
                return nil
            }()
            imageView.isHidden = (errorMessage == nil)
            imageView.toolTip = errorMessage
        }
        
        // disable controls if needed
        if identifier != .isEnabled {
            cellView.subviews.lazy
                .compactMap { $0 as? NSControl }
                .forEach { $0.isEnabled = replacement.isEnabled }
        }
        
        return cellView
    }
    
    
    // MARK: Actions
    
    /// Applies edited value to data model.
    @IBAction func didEditTableCell(_ sender: NSControl) {
        
        guard let tableView = self.tableView else { return }
        
        let row = tableView.row(for: sender)
        let column = tableView.column(for: sender)
        
        guard row >= 0, column >= 0 else { return }
        
        // update all selected checkboxes in the same column
        let rowIndex = IndexSet(integer: row)
        let rowIndexes = (sender is NSButton && tableView.selectedRowIndexes.contains(row))
            ? rowIndex.union(tableView.selectedRowIndexes)
            : rowIndex
        
        let identifier = tableView.tableColumns[column].identifier
        
        let replacements: [MultipleReplace.Replacement] = rowIndexes
            .map { self.definition.replacements[$0] }
            .map { replacement in
                var replacement = replacement
                
                switch sender {
                    case let textField as NSTextField:
                        let value = textField.stringValue
                        switch identifier {
                            case .findString:
                                replacement.findString = value
                            case .replacementString:
                                replacement.replacementString = value
                            case .description:
                                replacement.description = value.isEmpty ? nil : value
                            default:
                                preconditionFailure()
                        }
                        
                    case let checkbox as NSButton:
                        let value = (checkbox.state == .on)
                        switch identifier {
                            case .isEnabled:
                                replacement.isEnabled = value
                            case .ignoresCase:
                                replacement.ignoresCase = value
                            case .usesRegularExpression:
                                replacement.usesRegularExpression = value
                            default:
                                preconditionFailure()
                        }
                        
                    default:
                        preconditionFailure()
                }
                
                return replacement
            }
        
        self.updateReplacements(replacements, at: rowIndexes)
    }
}


extension MultipleReplaceViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        self.definition.replacements.count
    }
    
    
    /// Sets items per row to drag.
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        
        NSPasteboardItem(pasteboardPropertyList: row, ofType: .row)
    }
    
    
    /// Validates when dragged items come into tableView.
    func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        // accept only self drag-and-drop
        guard info.draggingSource as? NSTableView == tableView else { return [] }
        
        if dropOperation == .on {
            tableView.setDropRow(row, dropOperation: .above)
        }
        
        return .move
    }
    
    
    /// Inserts dragged items to table.
    func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        // accept only self drag-and-drop
        guard info.draggingSource as? NSTableView == tableView else { return false }
        
        // obtain original rows from pasteboard
        guard let sourceRows = info.draggingPasteboard.rows else { return false }
        
        let destinationRow = row - sourceRows.count(in: 0...row)  // real insertion point after removing items to move
        let destinationRows = IndexSet(destinationRow..<(destinationRow + sourceRows.count))
        
        self.moveReplacements(from: sourceRows, to: destinationRows)
        
        return true
    }
    
    
    /// Items are dropped somewhere.
    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        
        switch operation {
            case .delete:  // ended at the Trash
                guard let rows = session.draggingPasteboard.rows else { return }
                
                self.removeReplacements(at: rows)
                
            default:
                break
        }
    }
}


private extension NSViewController {
    
    /// Safely ends the current editing.
    final func endEditing() {
        
        self.viewIfLoaded?.window?.makeFirstResponder(nil)
    }
}


private extension NSPasteboard {
    
    var rows: IndexSet? {
        
         self.pasteboardItems?
            .compactMap { $0.propertyList(forType: .row) as? Int }
            .reduce(into: IndexSet()) { $0.insert($1) }
    }
}
