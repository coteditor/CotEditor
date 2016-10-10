/*
 
 KeyBindingsViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-08-20.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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

/// outilneView column identifier
private enum ColumnIdentifier: String {
    
    case title = "title"
    case keySpecChars = "keyBindingKey"
    
    
    /// initializer accepting optional rawValue
    init?(_ string: String?) {
        
        guard let string = string else { return nil }
        
        self = ColumnIdentifier(rawValue: string)!
    }
}


/// model object for NSArrayController
final class SnippetItem : NSObject {
    
    dynamic var text: String
    
    required init(_ text: String) {
        
        self.text = text
        
        super.init()
    }
}



// MARK:

class KeyBindingsViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate {
    
    // MARK: Private Properties
    
    private var outlineTree: [NSTreeNode] = [NSTreeNode]()
    private dynamic var warningMessage: String?  // for binding
    private dynamic var isRestoreble: Bool = false  // for binding
    
    @IBOutlet private weak var outlineView: NSOutlineView?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override var nibName: String? {
        
        return "MenuKeyBindingsEditView"
    }
    
    
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.outlineTree = self.manager.outlineTree(defaults: false)
        self.isRestoreble = !self.manager.usesDefaultKeyBindings
    }
    
    
    /// finish current editing
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        self.commitEditing()
    }
    
    
    
    // MARK: Outline View Data Source
    
    /// return number of child items
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        guard let children = self.children(ofItem: item) else { return 0 }
        
        return children.count
    }
    
    
    /// return if item is expandable
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        return (self.children(ofItem: item) != nil)
    }
    
    
    /// return child items
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        return self.children(ofItem: item)![index]
    }
    
    
    /// return suitable item for cell to display
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        
        guard let identifier = ColumnIdentifier(tableColumn?.identifier),
              let node = item as? NamedTreeNode else { return "" }
        
        switch identifier {
        case .title:
            return node.name
            
        case .keySpecChars:
            guard let shortcut = (node.representedObject as? KeyBindingItem)?.shortcut, shortcut.isValid else { return nil }
            return shortcut.isValid ? shortcut.description : nil
        }
    }
    
    
    
    // MARK: Delegate
    
    // NSOutlineViewDelegate  < outlineView
    
    /// initialize table cell view
    func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        if let view = rowView.view(atColumn: outlineView.column(withIdentifier: ColumnIdentifier.keySpecChars.rawValue)) as? NSTableCellView,
            let textField = view.textField,
            let node = outlineView.item(atRow: row) as? NSTreeNode
        {
            let keyBinding = node.representedObject as? KeyBindingItem
            
            // set if table cell is editable
            textField.isEditable = (keyBinding != nil)
            
            // set default short cut to placeholder
            textField.placeholderString = keyBinding?.defaultShortcut.description
        }
    }
    
    
    // NSTextFieldDelegate  < outlineView->ShortcutKeyField
    
    /// validate and apply new shortcut key input
    override func controlTextDidEndEditing(_ obj: Notification) {
        
        guard
            let textField = obj.object as? NSTextField,
            let outlineView = self.outlineView else { return }
        
        let row = outlineView.row(for: textField)
        let column = outlineView.column(for: textField)
        
        guard let node = outlineView.item(atRow: row) as? NSTreeNode, node.isLeaf else { return }
        guard let item = node.representedObject as? KeyBindingItem else { return }
        
        let oldShortcut = item.shortcut
        let input = textField.stringValue
        
        // reset once warning
        self.warningMessage = nil
        
        defer {
            // reset text field display
            textField.objectValue = oldShortcut?.description
        }
        
        // treat esc key as cancel
        guard input != "\u{1b}" else { return } // = ESC key
        
        guard input != item.shortcut?.description else { return }  // not edited
        
        let shortcut = Shortcut(keySpecChars: input)
        
        do {
            try self.manager.validate(shortcut: shortcut, oldShortcut: oldShortcut)
            
        } catch let error as InvalidKeySpecCharactersError {
            self.warningMessage = error.localizedDescription + " " + (error.recoverySuggestion ?? "")
            textField.objectValue = oldShortcut?.keySpecChars  // reset view with previous key
            NSBeep()
            
            // make text field edit mode again if invalid
            DispatchQueue.main.async {
                outlineView.editColumn(column, row: row, with: nil, select: true)
            }
            return
        } catch { assertionFailure("Caught unknown error.") }
        
        // successfully update data
        item.shortcut = shortcut
        self.saveSettings()
        self.outlineView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
    }
    
    
    
    // MARK: Action Messages
    
    /// restore key binding setting to default
    @IBAction func setToFactoryDefaults(_ sender: Any?) {
        
        self.outlineTree = self.manager.outlineTree(defaults: true)
        
        self.saveSettings()
        
        self.outlineView?.deselectAll(nil)
        self.outlineView?.reloadData()
        self.warningMessage = nil
        self.isRestoreble = false
    }
    
    
    
    // MARK: Private Methods
    
    /// corresponding key binding manager
    fileprivate var manager: KeyBindingManager {
        
        return MenuKeyBindingManager.shared
    }
    
    
    /// return child items of passed-in item
    private func children(ofItem item: Any?) -> [NSTreeNode]? {
    
        guard let node = item as? NSTreeNode else { return self.outlineTree }
        
        return node.isLeaf ? nil : node.children
    }
    
    
    /// save current settings
    fileprivate func saveSettings() {
        
        do {
            try self.manager.saveKeyBindings(outlineTree: self.outlineTree)
        } catch let error {
            Swift.print(error)
        }
        
        self.isRestoreble = !self.manager.usesDefaultKeyBindings
    }
    
}




// MARK: -

final class SnippetKeyBindingsViewController: KeyBindingsViewController, NSTextViewDelegate {
    
    dynamic var snippets = [SnippetItem]()
    
    @IBOutlet private var snippetArrayController: NSArrayController?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override var nibName: String? {
        
        return "TextKeyBindingsEditView"
    }
    
    
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.setup(snippets: SnippetKeyBindingManager.shared.snippets(defaults: false))
    }
    
    
    
    // MARK: Key Bindings View Controller Methods
    
    /// corresponding key binding manager
    fileprivate override var manager: KeyBindingManager {
        
        return SnippetKeyBindingManager.shared
    }
    
    
    /// save current settings
    fileprivate override func saveSettings() {
        
        let snippets = self.snippets.flatMap { $0.text }
        SnippetKeyBindingManager.shared.saveSnippets(snippets)
        
        super.saveSettings()
    }
    
    
    /// restore key binding setting to default
    @IBAction override func setToFactoryDefaults(_ sender: Any?) {
        
        self.setup(snippets: SnippetKeyBindingManager.shared.snippets(defaults: true))
        
        super.setToFactoryDefaults(sender)
    }
    
    
    
    // MARK: Delegate
    
    // NSOutlineViewDelegate  < outlineView
    
    /// change snippet array controller's selection
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        
        if let arrayController = self.snippetArrayController {
            let index = outlineView.row(forItem: item)
            
            arrayController.setSelectionIndex(index)
        }
        
        return true
    }
    
    
    // NSTextViewDelegate  < insertion text view
    
    /// insertion text did update
    func textDidEndEditing(_ notification: Notification) {
        
        if notification.object is NSTextView {
            self.saveSettings()
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// set snippets to arrayController
    private func setup(snippets: [String]) {
        
        // wrap with SnippetItem object for Cocoa-Binding
        self.snippets = snippets.map { SnippetItem($0) }
    }
    
}
