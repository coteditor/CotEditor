/*
 
 BatchReplacementViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-19.
 
 ------------------------------------------------------------------------------
 
 © 2017-2018 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

protocol BatchReplacementViewControllerDelegate: class {
    
    func didUpdate(batchReplacement: BatchReplacement)
}


final class BatchReplacementViewController: NSViewController, BatchReplacementPanelViewControlling {
    
    // MARK: Public Properties
    
    weak var delegate: BatchReplacementViewControllerDelegate?
    
    
    // MARK: Private Properties
    
    private var batchReplacement = BatchReplacement()
    private lazy var updateNotificationTask: Debouncer = Debouncer(delay: 1.0) { [weak self] in self?.notifyUpdate() }
    
    @objc private dynamic var canRemove: Bool = true
    @objc private dynamic var hasInvalidSetting = false
    @objc private dynamic var resultMessage: String?
    
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// reset previous search result
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.resultMessage = nil
    }
    
    
    /// pass settings to advanced options popover
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == NSStoryboardSegue.Identifier("OptionsSegue"),
            let destinationController = segue.destinationController as? NSViewController
        {
            destinationController.representedObject = BatchReplacement.Settings.Object(settings: self.batchReplacement.settings)
        }
    }
    
    
    /// get settings from advanced options popover
    override func dismissViewController(_ viewController: NSViewController) {
        
        super.dismissViewController(viewController)
        
        if let object = viewController.representedObject as? BatchReplacement.Settings.Object {
            guard self.batchReplacement.settings != object.settings else { return }
            
            self.batchReplacement.settings = object.settings
            self.updateNotificationTask.schedule()
        }
    }
    
    
    
    // MARK: Actions
    
    /// add a new replacement definition
    @IBAction func add(_ sender: Any?) {
        
        self.endEditing()
        
        // update data
        self.batchReplacement.replacements.append(BatchReplacement.Replacement())
        
        // update UI
        guard let tableView = self.tableView else { return }
        
        let lastRow = self.batchReplacement.replacements.count - 1
        let indexes = IndexSet(integer: lastRow)
        let column = tableView.column(withIdentifier: .findString)
        
        tableView.scrollRowToVisible(lastRow)
        tableView.insertRows(at: indexes, withAnimation: .effectGap)
        tableView.editColumn(column, row: lastRow, with: nil, select: true)  // start editing automatically
        
        // update remove button
        self.canRemove = self.batchReplacement.replacements.count > 1
    }
    
    
    /// remove selected replacement definitions
    @IBAction func remove(_ sender: Any?) {
        
        self.endEditing()
        
        guard let tableView = self.tableView else { return }
        
        let indexes = tableView.selectedRowIndexes
        
        // update UI
        tableView.removeRows(at: indexes, withAnimation: .effectGap)
        
        // update data
        self.batchReplacement.replacements.remove(in: indexes)
        
        // update remove button
        self.canRemove = self.batchReplacement.replacements.count > 1
    }
    
    
    /// highlight all matches in the target textView
    @IBAction func highlight(_ sender: Any?) {
        
        self.endEditing()
        self.validateObject()
        self.resultMessage = nil
        
        let inSelection = UserDefaults.standard[.findInSelection]
        self.batchReplacement.highlight(inSelection: inSelection) { [weak self] (resultMessage) in
            
            self?.resultMessage = resultMessage
        }
    }
    
    
    /// perform batch replacement
    @IBAction func batchReplace(_ sender: Any?) {
        
        self.endEditing()
        self.validateObject()
        self.resultMessage = nil
        
        let inSelection = UserDefaults.standard[.findInSelection]
        self.batchReplacement.replaceAll(inSelection: inSelection) { [weak self] (resultMessage) in
            
            self?.resultMessage = resultMessage
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// set another batch replacement definition
    func change(batchReplacement: BatchReplacement) {
        
        self.batchReplacement = batchReplacement
        self.hasInvalidSetting = false
        self.resultMessage = nil
        
        self.tableView?.reloadData()
        
        if batchReplacement.replacements.isEmpty {
            self.add(self)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// notify update to delegate
    private func notifyUpdate() {
    
        self.delegate?.didUpdate(batchReplacement: self.batchReplacement)
    }
    
    
    /// validate current setting
    @objc private func validateObject() {
        
        self.hasInvalidSetting = !self.batchReplacement.errors.isEmpty
    }
    
}



// MARK: - TableView Data Source & Delegate

private extension NSUserInterfaceItemIdentifier {
    
    static let isEnabled = NSUserInterfaceItemIdentifier("isEnabled")
    static let findString = NSUserInterfaceItemIdentifier("findString")
    static let replacementString = NSUserInterfaceItemIdentifier("replacementString")
    static let ignoresCase = NSUserInterfaceItemIdentifier("ignoresCase")
    static let usesRegularExpression = NSUserInterfaceItemIdentifier("usesRegularExpression")
    static let description = NSUserInterfaceItemIdentifier("description")
}


private extension NSPasteboard.PasteboardType {
    
    static let rows = NSPasteboard.PasteboardType("rows")
}


extension BatchReplacementViewController: NSTableViewDelegate {
    
    /// make table cell view
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard
            let replacement = self.batchReplacement.replacements[safe: row],
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
        
        // update warning icon
        if identifier == .findString, let imageView = cellView.imageView {
            let errorMessage: String? = {
                do {
                    try replacement.validate()
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
                .flatMap { $0 as? NSControl }
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
        
        let identifier = tableView.tableColumns[column].identifier
        let rowIndexes = IndexSet(integer: row)
        let updateRowIndexes: IndexSet
        
        switch sender {
        case let textField as NSTextField:
            updateRowIndexes = rowIndexes
            let value = textField.stringValue
            switch identifier {
            case .findString:
                self.batchReplacement.replacements[row].findString = value
            case .replacementString:
                self.batchReplacement.replacements[row].replacementString = value
            case .description:
                self.batchReplacement.replacements[row].description = (value.isEmpty) ? nil : value
            default:
                preconditionFailure()
            }
            
        case let checkbox as NSButton:
            // update all selected checkboxes in the same column
            let selectedIndexes = tableView.selectedRowIndexes
            updateRowIndexes = selectedIndexes.contains(row) ? selectedIndexes.union(rowIndexes) : rowIndexes
            
            let value = (checkbox.state == .on)
            for index in updateRowIndexes {
                switch identifier {
                case .isEnabled:
                    self.batchReplacement.replacements[index].isEnabled = value
                case .ignoresCase:
                    self.batchReplacement.replacements[index].ignoresCase = value
                case .usesRegularExpression:
                    self.batchReplacement.replacements[index].usesRegularExpression = value
                default:
                    preconditionFailure()
                }
            }
            
        default:
            preconditionFailure()
        }
        
        let allColumnIndexes = IndexSet(integersIn: 0..<tableView.numberOfColumns)
        tableView.reloadData(forRowIndexes: updateRowIndexes, columnIndexes: allColumnIndexes)
        
        self.updateNotificationTask.schedule()
    }
    
}


extension BatchReplacementViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return self.batchReplacement.replacements.count
    }
    
    
    /// start dragging
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        
        // register dragged type
        tableView.registerForDraggedTypes([.rows])
        pboard.declareTypes([.rows], owner: self)
        
        // select rows to drag
        tableView.selectRowIndexes(rowIndexes, byExtendingSelection: false)
        
        // store row index info to pasteboard
        let rows = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.setData(rows, forType: .rows)
        
        return true
    }
    
    
    /// validate when dragged items come into tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        // accept only self drag-and-drop
        guard info.draggingSource() as? NSTableView == tableView else { return [] }
        
        if dropOperation == .on {
            tableView.setDropRow(row, dropOperation: .above)
        }
        
        return .move
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        // accept only self drag-and-drop
        guard info.draggingSource() as? NSTableView == tableView else { return false }
        
        // obtain original rows from paste board
        guard
            let data = info.draggingPasteboard().data(forType: .rows),
            let sourceRows = NSKeyedUnarchiver.unarchiveObject(with: data) as? IndexSet else { return false }
        
        let destinationRow = row - sourceRows.count(in: 0...row)  // real insertion point after removing items to move
        let destinationRows = IndexSet(destinationRow..<(destinationRow + sourceRows.count))
        
        // update data
        let draggingItems = self.batchReplacement.replacements.elements(at: sourceRows)
        self.batchReplacement.replacements.remove(in: sourceRows)
        self.batchReplacement.replacements.insert(draggingItems, at: destinationRows)
        
        // update UI
        tableView.removeRows(at: sourceRows, withAnimation: [.effectFade, .slideDown])
        tableView.insertRows(at: destinationRows, withAnimation: .effectGap)
        tableView.selectRowIndexes(destinationRows, byExtendingSelection: false)
        
        return true
    }
    
}
