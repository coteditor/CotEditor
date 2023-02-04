//
//  KeyBindingsViewController.swift
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
    
    static let action = NSUserInterfaceItemIdentifier("action")
    static let key = NSUserInterfaceItemIdentifier("key")
}


final class KeyBindingsViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    // MARK: Private Properties
    
    private var outlineTree: [Node<KeyBindingItem>] = []
    @objc private dynamic var warningMessage: String?  // for binding
    @objc private dynamic var isRestorable: Bool = false  // for binding
    
    @IBOutlet private weak var outlineView: NSOutlineView?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.outlineTree = KeyBindingManager.shared.outlineTree(defaults: false)
        self.isRestorable = KeyBindingManager.shared.isCustomized
        self.warningMessage = nil
        self.outlineView?.reloadData()
    }
    
    
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        self.endEditing()
    }
    
    
    
    // MARK: Outline View Data Source
    
    /// return number of child items
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        guard let node = item as? Node<KeyBindingItem> else { return self.outlineTree.count }
        
        return node.children?.count ?? 0
    }
    
    
    /// return if item is expandable
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        guard let node = item as? Node<KeyBindingItem> else { return false }
        
        return node.children != nil
    }
    
    
    /// return child items
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        guard let node = item as? Node<KeyBindingItem> else { return self.outlineTree[index] }
        
        return node.children![index]
    }
    
    
    
    // MARK: Outline View Delegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        guard
            let node = item as? Node<KeyBindingItem>,
            let identifier = tableColumn?.identifier,
            let cellView = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        else { return nil }
        
        switch identifier {
            case .action:
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
        
        self.outlineTree = KeyBindingManager.shared.outlineTree(defaults: true)
        
        self.saveSettings()
        
        self.isRestorable = false
        self.warningMessage = nil
        self.outlineView?.deselectAll(nil)
        self.outlineView?.reloadData()
    }
    
    
    
    // MARK: Private Methods
    
    /// Save current settings.
    private func saveSettings() {
        
        let keyBindings = self.outlineTree
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
