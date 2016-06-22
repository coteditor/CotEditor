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
 
 http://www.apache.org/licenses/LICENSE-2.0
 
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
class SnippetItem : NSObject {
    
    dynamic var text: String
    
    init(_ text: String) {
        self.text = text
    }
}



// MARK:

class KeyBindingsViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate {
    
    private var outlineData: [CEKeyBindingItemInterface] = [CEKeyBindingItemInterface]()
    private dynamic var warningMessage: String?  // for binding
    private dynamic var restoreble: Bool = false  // for binding
    
    @IBOutlet private weak var outlineView: NSOutlineView?
    
    
    
    // MARK:
    // MARK: Creation
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.outlineData = self.manager.bindingItemsForOutlineData(withFactoryDefaults: false)
        self.restoreble = self.manager.usesDefaultKeyBindings()
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: View Controller Methods
    
    /// nib name
    override var nibName: String? {
        
        return "MenuKeyBindingsEditView"
    }
    
    
    /// finish current editing
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.commitEditing()
    }
    
    
    
    // MARK: Outline View Data Source
    
    /// return number of child items
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        
        if let children = self.children(ofItem: item) {
            return children.count
        } else {
            return 0
        }
    }
    
    
    /// return if item is expandable
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        
        return (self.children(ofItem: item) != nil)
    }
    
    
    /// return child items
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        
        return self.children(ofItem: item)![index]
    }
    
    
    /// return suitable item for cell to display
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        
        guard let identifier = ColumnIdentifier(tableColumn?.identifier),
              let keyBindingItem = item as? CEKeyBindingItemInterface else { return "" }
        
        switch identifier {
        case .title:
            return keyBindingItem.title()
            
        case .keySpecChars:
            if let keyBindingItem = keyBindingItem as? CEKeyBindingItem {
                return CEKeyBindingUtils.printableKeyString(fromKeySpecChars: keyBindingItem.keySpecChars)
            }
        }
        
        return nil
    }
    
    
    
    // MARK: Delegate
    
    // NSOutlineViewDelegate  < outlineView
    
    /// set if table cell is editable
    func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        let item = outlineView.item(atRow: row)
        
        if outlineView.isExpandable(item) {
            if let textField = rowView.view(atColumn: outlineView.column(withIdentifier: ColumnIdentifier.keySpecChars.rawValue))?.textField {
                textField?.isEditable = false
            }
        }
    }
    
    
    // NSTextFieldDelegate  < outlineView->ShortcutKeyField
    
    /// validate and apply new shortcut key input
    override func controlTextDidEndEditing(_ obj: Notification) {
        
        guard let textField = obj.object as? NSTextField,
              let outlineView = self.outlineView else { return }
        
        let row = outlineView.row(for: textField)
        
        guard let item = outlineView.item(atRow: row) as? CEKeyBindingItem else { return }
        
        let oldKeySpecChars = item.keySpecChars
        let keySpecChars = textField.stringValue
        
        // reset once warning
        self.warningMessage = nil
        
        // validate input value
        if keySpecChars == "\u{1b}" {
            // treat esc key as cancel
            
        } else if keySpecChars == CEKeyBindingUtils.printableKeyString(fromKeySpecChars: oldKeySpecChars) {  // not edited
            // do nothing
            
        } else {
            var success = true
            do {
                try self.manager.validateKeySpecChars(keySpecChars, oldKeySpecChars: oldKeySpecChars)
                
            } catch let error as NSError {
                success = false
                self.warningMessage = error.localizedDescription + " " + (error.localizedRecoverySuggestion ?? "")
                textField.stringValue = oldKeySpecChars ?? ""  // reset view with previous key
                NSBeep()
                
                // make text field edit mode again if invalid
                DispatchQueue.main.async { [weak self] in
                    self?.beginEditingSelectedKeyCell()
                }
            }
            
            // update data
            if success {
                item.keySpecChars = keySpecChars
                self.saveSettings()
            }
        }
        
        // reload cell to apply printed form of key spec
        let column = outlineView.column(for: textField)
        outlineView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: column))
    }
    
    
    
    // MARK: Action Messages
    
    /// restore key binding setting to default
    @IBAction func setToFactoryDefaults(_ sender: AnyObject?) {
        
        self.outlineData = self.manager.bindingItemsForOutlineData(withFactoryDefaults: true)
        
        self.saveSettings()
        
        self.outlineView?.deselectAll(nil)
        self.outlineView?.reloadData()
        self.warningMessage = nil
    }
    
    
    
    // MARK: Private Methods
    
    /// corresponding key binding manager
    private var manager: CEKeyBindingManager {
        
        return CEMenuKeyBindingManager.shared()
    }
    
    
    /// return child items of passed-in item
    private func children(ofItem item: AnyObject?) -> [CEKeyBindingItemInterface]? {
    
        if item == nil {
            return self.outlineData
        } else if let item = item as? CEKeyBindingContainerItem {
            return item.children
        } else {
            return nil
        }
    }
    
    
    /// save current settings
    private func saveSettings() {
        
        self.manager.saveKeyBindings(self.outlineData)
        self.restoreble = !self.manager.usesDefaultKeyBindings()
    }
    
    
    /// make selected Key cell edit mode
    private func beginEditingSelectedKeyCell() {
        
        guard let outlineView = self.outlineView else { return }
        
        let selectedRow = outlineView.selectedRow
        
        guard selectedRow >= 0 else { return }
        
        let column = outlineView.column(withIdentifier: ColumnIdentifier.keySpecChars.rawValue)
        
        outlineView.editColumn(column, row: selectedRow, with: nil, select: true)
    }
    
}




// MARK: 

class SnippetKeyBindingsViewController: KeyBindingsViewController, NSTextViewDelegate {
    
    var snippets = [SnippetItem]()
    
    @IBOutlet private var snippetArrayController: NSArrayController?
    
    
    
    
    // MARK:
    // MARK: Creation
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.setup(snippets: CESnippetKeyBindingManager.shared().snippets(withFactoryDefaults: false))
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Key Bindings View Controller Methods
    
    /// nib name
    override var nibName: String? {
        
        return "TextKeyBindingsEditView"
    }
    
    
    /// corresponding key binding manager
    private override var manager: CEKeyBindingManager {
        
        return CESnippetKeyBindingManager.shared()
    }
    
    
    /// save current settings
    private override func saveSettings() {
        
        let snippets = self.snippets.flatMap({ snippet in snippet.text })
        CESnippetKeyBindingManager.shared().saveSnippets(snippets)
        
        super.saveSettings()
    }
    
    
    /// restore key binding setting to default
    override func setToFactoryDefaults(_ sender: AnyObject?) {
        
        self.setup(snippets: CESnippetKeyBindingManager.shared().snippets(withFactoryDefaults: true))
        
        super.setToFactoryDefaults(sender)
    }
    
    
    
    // MARK: Delegate
    
    // NSOutlineViewDelegate  < outlineView
    
    /// change snippet array controller's selection
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        
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
        var content = [SnippetItem]()
        for snippet in snippets {
            content.append(SnippetItem(snippet))
        }
        self.snippets = content
    }
    
}
