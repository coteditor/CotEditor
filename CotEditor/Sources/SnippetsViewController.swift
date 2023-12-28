//
//  SnippetsViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-02-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

/// Column identifiers for table view.
private extension NSUserInterfaceItemIdentifier {
    
    static let scope = NSUserInterfaceItemIdentifier("scope")
    static let name = NSUserInterfaceItemIdentifier("name")
    static let key = NSUserInterfaceItemIdentifier("key")
}


private extension NSPasteboard.PasteboardType {
    
    static let rows = NSPasteboard.PasteboardType("rows")
}


final class SnippetsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    private var snippets: [Snippet] = []
    
    @objc private dynamic var warningMessage: String?  // for binding
    
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private weak var addRemoveButton: NSSegmentedControl?
    @IBOutlet private weak var formatTextView: TokenTextView?
    @IBOutlet private weak var variableInsertionMenu: NSPopUpButton?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // setup variable menu
        self.variableInsertionMenu!.menu!.items += Snippet.Variable.allCases
            .map { $0.insertionMenuItem(target: self.formatTextView) }
        
        // set tokenizer for format text view
        self.formatTextView!.tokenizer = Snippet.Variable.tokenizer
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.snippets = SnippetManager.shared.snippets
        self.tableView?.reloadData()
        self.selectionDidChange()
        self.warningMessage = nil
    }
    
    
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        self.endEditing()
        self.saveSetting()
    }
    
    
    
    // MARK: Table View Data Source
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        self.snippets.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        guard let identifier = tableColumn?.identifier else { return nil }
        
        let snippet = self.snippets[row]
        
        switch identifier {
            case .scope:
                return snippet.scope
            case .name:
                return snippet.name
            case .key:
                return snippet.shortcut
            default:
                preconditionFailure()
        }
    }
    
    
    /// Starts dragging.
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        
        // register dragged type
        tableView.registerForDraggedTypes([.rows])
        pboard.declareTypes([.rows], owner: self)
        
        // store row index info to pasteboard
        guard let rows = try? NSKeyedArchiver.archivedData(withRootObject: rowIndexes, requiringSecureCoding: true) else { return false }
        
        pboard.setData(rows, forType: .rows)
        
        return true
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
    
    
    /// Checks acceptability of dragged items and insert them to table.
    func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        // accept only self drag-and-drop
        guard info.draggingSource as? NSTableView == tableView else { return false }
        
        // obtain original rows from paste board
        guard
            let data = info.draggingPasteboard.data(forType: .rows),
            let sourceRows = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSIndexSet.self, from: data) as IndexSet?
        else { return false }
        
        // move
        self.snippets.move(fromOffsets: sourceRows, toOffset: row)
        tableView.moveRows(at: sourceRows, to: row)
        
        self.saveSetting()
        
        return true
    }
    
    
    // MARK: Table View Delegate
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard
            let identifier = tableColumn?.identifier,
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        else { return nil }
        
        let snippet = self.snippets[row]
        
        switch identifier {
            case .scope:
                guard let menu = cellView.subviews.first as? NSPopUpButton else { assertionFailure(); return nil }
                
                // reset attributed string for "All" item
                // -> Otherwise, the title isn't localized.
                let allItem = menu.itemArray.first!
                allItem.attributedTitle = NSAttributedString(string: allItem.title, attributes: allItem.attributedTitle!.attributes(at: 0, effectiveRange: nil))
                
                // add syntaxes
                for settingName in SyntaxManager.shared.settingNames {
                    menu.addItem(withTitle: settingName)
                    menu.lastItem!.representedObject = settingName
                }
                
                // select item
                if let scope = snippet.scope {
                    menu.selectItem(withTitle: scope)
                } else {
                    if let emptyItem = menu.itemArray.first(where: { !$0.isSeparatorItem && $0.title.isEmpty }) {
                        menu.menu?.removeItem(emptyItem)
                    }
                    menu.selectItem(at: 0)
                }
                
            default:
                break
        }
        
        return cellView
    }
    
    
    /// Invoked when the selection in the table did change.
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        self.selectionDidChange()
    }
    
    
    // MARK: Text View Delegate (format text view)
    
    /// Invoked when the insertion text did update.
    func textDidEndEditing(_ notification: Notification) {
        
        guard
            let textView = notification.object as? NSTextView,
            let tableView = self.tableView,
            tableView.selectedRowIndexes.count == 1
        else { return }
        
        self.snippets[tableView.selectedRow].format = textView.string
        self.saveSetting()
    }
    
    
    // MARK: Actions
    
    @IBAction func addRemove(_ sender: NSSegmentedControl) {
        
        self.endEditing()
        
        guard let rows = self.tableView?.selectedRowIndexes else { return }
        
        switch sender.selectedSegment {
            case 0:  // add
                let snippet = SnippetManager.shared.createUntitledSetting()
                let row = rows.last.flatMap { $0 + 1 } ?? self.snippets.endIndex
                self.snippets.insert(snippet, at: row)
                self.tableView?.insertRows(at: [row], withAnimation: .effectGap)
                
            case 1:  // remove
                guard !rows.isEmpty else { return }
                self.snippets.remove(in: rows)
                self.tableView?.removeRows(at: rows, withAnimation: [.slideUp, .effectFade])
                
            default:
                preconditionFailure()
        }
        
        self.saveSetting()
    }
    
    
    @IBAction func didSelectSyntax(_ sender: NSPopUpButton) {
        
        guard let tableView = self.tableView else { return assertionFailure() }
        
        let row = tableView.row(for: sender)
        let column = tableView.column(for: sender)
        
        guard row >= 0, column >= 0 else { return }
        
        self.snippets[row].scope = sender.selectedItem?.representedObject as? String
        self.saveSetting()
        tableView.reloadData(forRowIndexes: [row], columnIndexes: [column])
    }
    
    
    @IBAction func didEditName(_ sender: NSTextField) {
        
        guard let tableView = self.tableView else { return assertionFailure() }
        
        let row = tableView.row(for: sender)
        let column = tableView.column(for: sender)
        
        guard row >= 0, column >= 0 else { return }
        
        // successfully update data
        self.snippets[row].name = sender.stringValue
        self.saveSetting()
        tableView.reloadData(forRowIndexes: [row], columnIndexes: [column])
    }
    
    
    /// Validates and applies the new shortcut key input.
    @IBAction func didEditShortcut(_ sender: ShortcutField) {
        
        guard let tableView = self.tableView else { return assertionFailure() }
        
        let row = tableView.row(for: sender)
        let column = tableView.column(for: sender)
        
        let oldShortcut = self.snippets[row].shortcut
        let shortcut = sender.objectValue as? Shortcut
        
        // reset once warning
        self.warningMessage = nil
        
        // not edited
        guard shortcut != oldShortcut else { return }
        
        if let shortcut {
            do {
                try shortcut.checkCustomizationAvailability()
                
            } catch {
                self.warningMessage = error.localizedDescription
                sender.objectValue = oldShortcut  // reset text field
                NSSound.beep()
                
                // make text field edit mode again
                Task {
                    tableView.editColumn(column, row: row, with: nil, select: true)
                }
                return
            }
        }
        
        // successfully update data
        self.snippets[row].shortcut = shortcut
        self.saveSetting()
        tableView.reloadData(forRowIndexes: [row], columnIndexes: [column])
    }
    
    
    
    // MARK: Private Methods
    
    /// Saves current setting.
    private func saveSetting() {
        
        SnippetManager.shared.save(self.snippets)
    }
    
    
    /// Updates controls according to the state of selection in the table view.
    private func selectionDidChange() {
        
        guard
            let tableView = self.tableView,
            let textView = self.formatTextView
        else { return assertionFailure() }
        
        if tableView.selectedRowIndexes.count == 1 {
            textView.isEditable = true
            textView.textColor = .textColor
            textView.string = self.snippets[tableView.selectedRow].format
        } else {
            textView.isEditable = false
            textView.textColor = .disabledControlTextColor
            textView.string = String(localized: "Select a snippet to edit.")
        }
        
        self.addRemoveButton?.setEnabled(!tableView.selectedRowIndexes.isEmpty, forSegment: 1)
    }
}


private extension NSTableView {
    
    /// Moves the specified rows to the new row location using animation.
    ///
    /// - Parameters:
    ///   - oldIndexes: Initial row indexes.
    ///   - newIndex: Row index to insert all specified rows.
    func moveRows(at oldIndexes: IndexSet, to newIndex: Int) {
        
        var oldOffset = 0
        var newOffset = 0
        
        self.beginUpdates()
        for oldIndex in oldIndexes {
            if oldIndex < newIndex {
                self.moveRow(at: oldIndex + oldOffset, to: newIndex - 1)
                oldOffset -= 1
            } else {
                self.moveRow(at: oldIndex, to: newIndex + newOffset)
                newOffset += 1
            }
        }
        self.endUpdates()
    }
}
