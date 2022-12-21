//
//  MultipleReplacementViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2022 1024jp
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

import Cocoa
import SwiftUI

protocol MultipleReplacementViewControllerDelegate: AnyObject {
    
    func didUpdate(setting: MultipleReplacement)
}


final class MultipleReplacementViewController: NSViewController {
    
    // MARK: Public Properties
    
    weak var delegate: MultipleReplacementViewControllerDelegate?
    
    
    // MARK: Private Properties
    
    private var definition = MultipleReplacement()
    private lazy var updateNotificationDebouncer = Debouncer(delay: .seconds(1)) { [weak self] in self?.notifyUpdate() }
    
    @objc private dynamic var hasInvalidSetting = false
    @objc private dynamic var resultMessage: String?
    
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private weak var addRemoveButton: NSSegmentedControl?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView?.setDraggingSourceOperationMask([.delete], forLocal: false)
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
    
    /// The segmented control for the add/remove actions was clicked.
    @IBAction func addRemove(_ sender: NSSegmentedControl) {
        
        switch sender.selectedSegment {
            case 0: self.add(sender)
            case 1: self.remove(sender)
            default: preconditionFailure()
        }
    }
    
    
    /// Add a new replacement rule at the end.
    @IBAction func add(_ sender: Any?) {
        
        self.endEditing()
        
        let row = self.tableView?.selectedRowIndexes.last.flatMap { $0 + 1 } ?? self.definition.replacements.endIndex
        let replacements = [MultipleReplacement.Replacement()]
        
        self.insertReplacements(replacements, at: [row])
        
        guard let tableView = self.tableView else { return }
        
        // start editing automatically
        let column = tableView.column(withIdentifier: .findString)
        tableView.selectRowIndexes([row], byExtendingSelection: false)
        tableView.scrollRowToVisible(row)
        tableView.editColumn(column, row: row, with: nil, select: true)
    }
    
    
    /// Remove selected replacement rules.
    @IBAction func remove(_ sender: Any?) {
        
        self.endEditing()
        
        guard let tableView = self.tableView else { return assertionFailure() }
        
        let rowIndexes = tableView.selectedRowIndexes
        
        self.removeReplacements(at: rowIndexes)
        
        if self.definition.replacements.isEmpty {
            self.add(nil)
        }
    }
    
    
    /// Show the advanced options view.
    @IBAction func showOptions(_ sender: NSButton) {
        
        if let viewController = self.presentedViewControllers?.first(where: { $0 is NSHostingController<MultipleReplacementSettingsView> }) {
            return self.dismiss(viewController)
        }
        
        let view = MultipleReplacementSettingsView(settings: self.definition.settings) { settings in
            guard self.definition.settings != settings else { return }
            
            self.definition.settings = settings
            self.tableView?.reloadData()  // update regex highlight for replacement string
            self.updateNotificationDebouncer.schedule()
        }
        let viewController = NSHostingController(rootView: view)
        viewController.ensureFrameSize()
        
        self.present(viewController, asPopoverRelativeTo: sender.bounds, of: sender, preferredEdge: .maxX, behavior: .transient)
    }
    
    
    /// Highlight all matches in the target textView.
    @IBAction func highlight(_ sender: Any?) {
        
        self.endEditing()
        self.validateObject()
        self.resultMessage = nil
        
        guard let textView = TextFinder.shared.client else { return NSSound.beep() }
        
        let inSelection = UserDefaults.standard[.findInSelection]
        
        Task {
            guard let message = try? await textView.highlight(self.definition, inSelection: inSelection) else { return }
            
            self.resultMessage = message
            
            // feedback for VoiceOver
            if let window = NSApp.mainWindow {
                NSAccessibility.post(element: window, notification: .announcementRequested, userInfo: [.announcement: message])
            }
        }
    }
    
    
    /// Perform replacement with current set.
    @IBAction func batchReplaceAll(_ sender: Any?) {
        
        self.endEditing()
        self.validateObject()
        self.resultMessage = nil
        
        guard let textView = TextFinder.shared.client,
              textView.isEditable,
              textView.window?.attachedSheet == nil
        else { return NSSound.beep() }
        
        let inSelection = UserDefaults.standard[.findInSelection]
        
        Task {
            guard let message = try? await textView.replaceAll(self.definition, inSelection: inSelection) else { return }
            
            self.resultMessage = message
            
            // feedback for VoiceOver
            if let window = NSApp.mainWindow {
                NSAccessibility.post(element: window, notification: .announcementRequested, userInfo: [.announcement: message])
            }
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Set another replacement definition.
    ///
    /// - Parameter setting: The setting to replace.
    func change(setting: MultipleReplacement) {
        
        self.definition = setting
        self.hasInvalidSetting = false
        self.resultMessage = nil
        
        self.undoManager?.removeAllActions(withTarget: self)
        self.tableView?.reloadData()
        
        // workaround issue drawing issue (macOS 13, 2022-11)
        // cf. [#1402](https://github.com/coteditor/CotEditor/issues/1402)
        self.tableView?.needsDisplay = true
        
        if setting.replacements.isEmpty {
            self.add(self)
        }
        
        self.invalidateRemoveButton()
    }
    
    
    
    // MARK: Private Methods
    
    /// Notify update to delegate.
    private func notifyUpdate() {
        
        self.delegate?.didUpdate(setting: self.definition)
    }
    
    
    /// Validate the availability of the remove button.
    private func invalidateRemoveButton() {
        
        let canRemove = self.tableView?.selectedRowIndexes.isEmpty == false
        self.addRemoveButton?.setEnabled(canRemove, forSegment: 1)
    }
    
    
    /// Validate the current setting.
    private func validateObject() {
        
        self.hasInvalidSetting = self.definition.replacements.contains {
            do { try $0.validate() } catch { return true }
            return false
        }
    }
    
    
    /// Undoable insertion of replacement definitions.
    ///
    /// - Parameters:
    ///   - replacements: New replacement definitions to insert.
    ///   - rowIndexes: Rows of definitions to insert.
    private func insertReplacements(_ replacements: [MultipleReplacement.Replacement], at rowIndexes: IndexSet) {
        
        assert(replacements.count == rowIndexes.count)
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { target in
                target.removeReplacements(at: rowIndexes)
            }
            if !undoManager.isUndoing {
                undoManager.setActionName("Insert Rule".localized)
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
    
    
    /// Undoable removal of replacement definitions.
    ///
    /// - Parameter rowIndexes: Rows of definitions to remove.
    private func removeReplacements(at rowIndexes: IndexSet) {
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { [replacements = self.definition.replacements.elements(at: rowIndexes)] target in
                target.insertReplacements(replacements, at: rowIndexes)
            }
            if !undoManager.isUndoing {
                undoManager.setActionName("Delete Rules".localized)
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
    
    
    /// Undoable replacement definitions' update.
    ///
    /// - Parameters:
    ///   - replacements: New replacement definitions to update.
    ///   - rowIndexes: Rows of definitions to be updated.
    private func updateReplacements(_ replacements: [MultipleReplacement.Replacement], at rowIndexes: IndexSet) {
        
        assert(replacements.count == rowIndexes.count)
        
        // register undo
        if let undoManager = self.undoManager {
            undoManager.registerUndo(withTarget: self) { [replacements = self.definition.replacements.elements(at: rowIndexes)] target in
                target.updateReplacements(replacements, at: rowIndexes)
            }
            if !undoManager.isUndoing {
                undoManager.setActionName("Edit Rule".localized)
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
    
    
    /// Undoable move of replacement definitions.
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
                undoManager.setActionName("Move Rules".localized)
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
    
    static let rows = NSPasteboard.PasteboardType("rows")
}


extension MultipleReplacementViewController: NSTableViewDelegate {
    
    /// selection did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        self.invalidateRemoveButton()
    }
    
    
    /// make table cell view
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard
            let replacement = self.definition.replacements[safe: row],
            let identifier = tableColumn?.identifier,
            let cellView = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView
        else { return nil }
        
        switch identifier {
            case .isEnabled:
                cellView.objectValue = replacement.isEnabled
            case .findString:
                cellView.objectValue = replacement.findString
            case .replacementString:
                cellView.objectValue = replacement.replacementString
            case .ignoresCase:
                cellView.objectValue = replacement.ignoresCase
            case .usesRegularExpression:
                cellView.objectValue = replacement.usesRegularExpression
            case .description:
                cellView.objectValue = replacement.description
            default:
                preconditionFailure()
        }
        
        // update regex field
        if let field = cellView.textField as? RegexTextField {
            field.parsesRegularExpression = replacement.isEnabled && replacement.usesRegularExpression
            field.unescapesReplacement = self.definition.settings.unescapesReplacementString
        }
        
        // update warning icon
        if identifier == .findString, let imageView = cellView.imageView {
            let errorMessage: String? = {
                do {
                    try replacement.validate(regexOptions: self.definition.settings.regexOptions)
                } catch {
                    guard let suggestion = (error as? LocalizedError)?.recoverySuggestion else { return error.localizedDescription }
                    
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
    
    /// apply edited value to data model
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
        
        let replacements: [MultipleReplacement.Replacement] = rowIndexes
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


extension MultipleReplacementViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        self.definition.replacements.count
    }
    
    
    /// start dragging
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        
        // register dragged type
        tableView.registerForDraggedTypes([.rows])
        pboard.declareTypes([.rows], owner: self)
        
        // select rows to drag
        tableView.selectRowIndexes(rowIndexes, byExtendingSelection: false)
        
        // store row index info to pasteboard
        guard let rows = try? NSKeyedArchiver.archivedData(withRootObject: rowIndexes, requiringSecureCoding: true) else { return false }
        
        pboard.setData(rows, forType: .rows)
        
        return true
    }
    
    
    /// validate when dragged items come into tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        // accept only self drag-and-drop
        guard info.draggingSource as? NSTableView == tableView else { return [] }
        
        if dropOperation == .on {
            tableView.setDropRow(row, dropOperation: .above)
        }
        
        return .move
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        // accept only self drag-and-drop
        guard info.draggingSource as? NSTableView == tableView else { return false }
        
        // obtain original rows from paste board
        guard
            let data = info.draggingPasteboard.data(forType: .rows),
            let sourceRows = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSIndexSet.self, from: data) as IndexSet?
        else { return false }
        
        let destinationRow = row - sourceRows.count(in: 0...row)  // real insertion point after removing items to move
        let destinationRows = IndexSet(destinationRow..<(destinationRow + sourceRows.count))
        
        // move
        self.moveReplacements(from: sourceRows, to: destinationRows)
        
        return true
    }
    
    
    /// items are dropped somewhere
    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        
        switch operation {
            case .delete:  // ended at the Trash
                guard
                    let data = session.draggingPasteboard.data(forType: .rows),
                    let rows = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSIndexSet.self, from: data) as IndexSet?
                else { return }
                
                self.removeReplacements(at: rows)
            
            default:
                break
        }
    }
}
