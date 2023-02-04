//
//  KeyBindingsPaneController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-08-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2023 1024jp
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

/// outlineView column identifier
private extension NSUserInterfaceItemIdentifier {
    
    static let command = NSUserInterfaceItemIdentifier("command")
    static let key = NSUserInterfaceItemIdentifier("key")
}


final class KeyBindingsPaneController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    // MARK: Private Properties
    
    private var menuTree: [Node<KeyBindingItem>] = []
    @objc private dynamic var warningMessage: String?  // for binding
    @objc private dynamic var isRestorable: Bool = false  // for binding
    
    @IBOutlet private weak var listView: NSTableView?
    @IBOutlet private weak var outlineView: NSOutlineView?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.menuTree = KeyBindingManager.shared.menuTree
        self.isRestorable = KeyBindingManager.shared.isCustomized
        self.warningMessage = nil
        self.listView?.reloadData()
        self.outlineView?.reloadData()
    }
    
    
    
    // MARK: Outline View Data Source
    
    /// return number of child items
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        if let node = item as? Node<KeyBindingItem> {
            return node.children?.count ?? 0
        } else if let index = self.listView?.selectedRow, index >= 0 {
            return self.menuTree[index].children?.count ?? 0
        } else {
            return 0
        }
    }
    
    
    /// return if item is expandable
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        (item as? Node<KeyBindingItem>)?.children != nil
    }
    
    
    /// return child items
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        if let node = item as? Node<KeyBindingItem> {
            return node.children![index]
        } else if let rootIndex = self.listView?.selectedRow {
            return self.menuTree[rootIndex].children![index]
        } else {
            preconditionFailure()
        }
    }
    
    
    
    // MARK: Outline View Delegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        guard
            let node = item as? Node<KeyBindingItem>,
            let identifier = tableColumn?.identifier,
            let cellView = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        else { return nil }
        
        switch identifier {
            case .command:
                cellView.objectValue = node.name
                
            case .key:
                switch node.item {
                    case let .value(item):
                        cellView.objectValue = item.shortcut
                        cellView.textField?.placeholderString = item.defaultShortcut?.symbol
                        
                    case .children:
                        cellView.textField?.isEditable = false
                }
                
            default:
                preconditionFailure()
        }
        
        return cellView
    }
    
    
    
    // MARK: Action Messages
    
    /// Validate and apply new shortcut key input.
    @IBAction func didEditShortcut(_ sender: ShortcutField) {
        
        guard let outlineView = self.outlineView else { return assertionFailure() }
        
        let row = outlineView.row(for: sender)
        let column = outlineView.column(for: sender)
        
        guard
            let node = outlineView.item(atRow: row) as? Node<KeyBindingItem>,
            let item = node.value
        else { return }
        
        let oldShortcut = item.shortcut
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
                    outlineView.editColumn(column, row: row, with: nil, select: true)
                }
                return
            }
        }
        
        // successfully update data
        item.shortcut = shortcut
        self.saveSettings()
        outlineView.reloadData(forRowIndexes: [row], columnIndexes: [column])
    }
    
    
    /// Restore key binding setting to default.
    @IBAction func setToFactoryDefaults(_ sender: Any?) {
        
        try? KeyBindingManager.shared.restoreDefaults()
        
        self.menuTree = KeyBindingManager.shared.menuTree
        self.isRestorable = false
        self.warningMessage = nil
        self.outlineView?.reloadData()
    }
    
    
    
    // MARK: Private Methods
    
    /// Save current settings.
    private func saveSettings() {
        
        let keyBindings = self.menuTree
            .flatMap(\.flatValues)
            .filter { $0.shortcut?.isValid ?? true }
            .compactMap { KeyBinding(action: $0.action, tag: $0.tag, shortcut: $0.shortcut) }
        
        do {
            try KeyBindingManager.shared.saveKeyBindings(keyBindings)
        } catch {
            Swift.print(error)
        }
        
        self.isRestorable = KeyBindingManager.shared.isCustomized
    }
}



extension KeyBindingsPaneController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        self.menuTree.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        self.menuTree[row].name
    }
    
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        self.commitEditing()
        self.outlineView?.reloadData()
    }
}
