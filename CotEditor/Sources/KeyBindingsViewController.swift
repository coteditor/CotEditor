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
    
    static let title = NSUserInterfaceItemIdentifier("title")
    static let keySpecChars = NSUserInterfaceItemIdentifier("keyBindingKey")
}


class KeyBindingsViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate {
    
    // MARK: Private Properties
    
    private var outlineTree: [Node<KeyBindingItem>] = []
    @objc private dynamic var warningMessage: String?  // for binding
    @objc private dynamic var isRestorable: Bool = false  // for binding
    
    @IBOutlet fileprivate weak var outlineView: NSOutlineView?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.outlineTree = self.manager.outlineTree(defaults: false)
        self.isRestorable = !self.manager.usesDefaultKeyBindings
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
            let cellView = outlineView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView
        else { return nil }
        
        switch identifier {
            case .title:
                cellView.objectValue = node.name
                
            case .keySpecChars:
                switch node.item {
                    case let .value(item):
                        cellView.objectValue = (item.shortcut?.isValid == true) ? item.shortcut : nil
                        cellView.textField?.placeholderString = item.defaultShortcut.description
                        
                    case .children:
                        cellView.textField?.isEditable = false
                }
                
            default:
                preconditionFailure()
        }
        
        return cellView
    }
    
    
    
    // MARK: Text Field Delegate (ShortcutKeyField)
    
    /// Validate and apply new shortcut key input.
    func controlTextDidEndEditing(_ obj: Notification) {
        
        guard
            let textField = obj.object as? NSTextField,
            let outlineView = self.outlineView
        else { return assertionFailure() }
        
        let row = outlineView.row(for: textField)
        let column = outlineView.column(for: textField)
        
        guard
            let node = outlineView.item(atRow: row) as? Node<KeyBindingItem>,
            let item = node.value
        else { return }
        
        let oldShortcut = item.shortcut
        let input = textField.stringValue
        
        // reset once warning
        self.warningMessage = nil
        
        // cancel input
        guard
            input != "\u{1b}",  // = ESC key  -> treat Esc key as cancel
            input != oldShortcut?.description  // not edited
        else {
            // reset text field display
            textField.objectValue = oldShortcut?.description
            return
        }
        
        let shortcut = Shortcut(keySpecChars: input)
        
        do {
            try self.manager.validate(shortcut: shortcut, oldShortcut: oldShortcut)
            
        } catch let error as InvalidShortcutError {
            self.warningMessage = error.localizedDescription + " " + (error.recoverySuggestion ?? "")
            textField.objectValue = oldShortcut?.keySpecChars  // reset view with previous key
            NSSound.beep()
            
            // make text field edit mode again if invalid
            DispatchQueue.main.async {
                outlineView.editColumn(column, row: row, with: nil, select: true)
            }
            // reset text field display
            textField.objectValue = oldShortcut?.description
            return
            
        } catch { assertionFailure("Caught unknown error: \(error)") }
        
        // successfully update data
        item.shortcut = shortcut
        textField.objectValue = shortcut.description
        self.saveSettings()
        self.outlineView?.reloadData(forRowIndexes: [row], columnIndexes: [column])
    }
    
    
    
    // MARK: Action Messages
    
    /// Restore key binding setting to default.
    @IBAction func setToFactoryDefaults(_ sender: Any?) {
        
        self.outlineTree = self.manager.outlineTree(defaults: true)
        
        self.saveSettings()
        
        self.outlineView?.deselectAll(nil)
        self.outlineView?.reloadData()
        self.warningMessage = nil
        self.isRestorable = false
    }
    
    
    
    // MARK: Private Methods
    
    /// Corresponding key binding manager.
    fileprivate var manager: KeyBindingManager {
        
        MenuKeyBindingManager.shared
    }
    
    
    /// Save current settings.
    fileprivate func saveSettings() {
        
        let keyBindings: [KeyBinding] = self.outlineTree.flatMap(\.flatValues)
            .compactMap { item in
                guard let shortcut = item.shortcut else { return nil }
                
                return KeyBinding(name: item.name, action: item.action, tag: item.tag, shortcut: shortcut.isValid ? shortcut : nil)
            }
        
        do {
            try self.manager.saveKeyBindings(keyBindings)
        } catch {
            Swift.print(error)
        }
        
        self.isRestorable = !self.manager.usesDefaultKeyBindings
    }
}



// MARK: -

final class SnippetKeyBindingsViewController: KeyBindingsViewController, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var formatTextView: TokenTextView?
    @IBOutlet private weak var variableInsertionMenu: NSPopUpButton?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // setup variable menu
        self.variableInsertionMenu!.menu!.items += Snippet.Variable.allCases.map { $0.insertionMenuItem(target: self.formatTextView) }
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.formatTextView?.tokenizer = Snippet.Variable.tokenizer
        
        if let outlineView = self.outlineView, outlineView.selectedRow == -1 {
            outlineView.selectRowIndexes([0], byExtendingSelection: false)
        }
    }
    
    
    
    // MARK: Key Bindings View Controller Methods
    
    /// Corresponding key binding manager.
    fileprivate override var manager: KeyBindingManager {
        
        SnippetKeyBindingManager.shared
    }
    
    
    /// Restore key binding setting to default.
    @IBAction override func setToFactoryDefaults(_ sender: Any?) {
        
        SnippetKeyBindingManager.shared.restoreSnippets()
        
        super.setToFactoryDefaults(sender)
    }
    
    
    
    // MARK: Outline View Delegate
    
    /// Change snippet array controller's selection.
    func outlineViewSelectionDidChange(_ notification: Notification) {
        
        guard
            let outlineView = notification.object as? NSOutlineView,
            let textView = self.formatTextView
        else { return assertionFailure() }
        
        if outlineView.selectedRow >= 0 {
            textView.isEditable = true
            textView.textColor = .labelColor
            textView.backgroundColor = .textBackgroundColor
            textView.string = SnippetKeyBindingManager.shared.snippets[outlineView.selectedRow]
        } else {
            textView.isEditable = false
            textView.textColor = .tertiaryLabelColor
            textView.backgroundColor = .labelColor.withAlphaComponent(0.05)
            textView.string = String(localized: "Select Action")
        }
        
    }
    
    
    
    // MARK: Text View Delegate (insertion text view)
    
    /// Insertion text did update.
    func textDidEndEditing(_ notification: Notification) {
        
        guard
            let textView = notification.object as? NSTextView,
            let index = self.outlineView?.selectedRow,
            index >= 0
        else { return }
        
        SnippetKeyBindingManager.shared.snippets[index] = textView.string
    }
}
