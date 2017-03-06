/*
 
 FileDropPaneController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-18.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2017 1024jp
 
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

final class FileDropPaneController: NSViewController, NSTableViewDelegate, NSTextFieldDelegate, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    private var deletingFileDrop = false
    
    @IBOutlet private var fileDropController: NSArrayController?
    @IBOutlet private weak var extensionTableView: NSTableView?
    @IBOutlet private weak var variableInsertionMenu: NSPopUpButton?
    @IBOutlet private var glossaryTextView: NSTextView?  // NSTextView cannot be weak
    @IBOutlet private var formatTextView: TokenTextView? {  // NSTextView cannot be weak
        didSet {
            // set tokenizer for format text view
            self.formatTextView!.tokenizer = FileDropComposer.Token.tokenizer
        }
    }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.formatTextView?.delegate = nil
        self.glossaryTextView?.delegate = nil
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // load setting
        self.loadSetting()
        
        // set localized glossary to view
        self.glossaryTextView!.string = FileDropComposer.Token.all
            .map { $0.token + "\n" + $0.localizedDescription }
            .joined(separator: "\n\n")
        self.glossaryTextView?.textContainerInset = NSSize(width: 2, height: 6)
        
        // setup variable menu
        if let menu = self.variableInsertionMenu?.menu {
            for variable in FileDropComposer.Token.pathTokens {
                let item = NSMenuItem(title: variable.token, action: #selector(insertVariable), keyEquivalent: "")
                item.toolTip = variable.localizedDescription
                menu.addItem(item)
            }
            menu.addItem(NSMenuItem.separator())
            for variable in FileDropComposer.Token.imageTokens {
                let item = NSMenuItem(title: variable.token, action: #selector(insertVariable), keyEquivalent: "")
                item.toolTip = variable.localizedDescription
                menu.addItem(item)
            }
        }
    }
    
    
    /// finish current editing
    override func viewWillDisappear() {
        
        self.endEditing()
        
        self.saveSetting()
    }
    
    
    
    // MARK: Delegate
    
    /// extension table was edited
    override func controlTextDidEndEditing(_ obj: Notification) {
        
        guard obj.object is NSTextField,
            let controller = self.fileDropController else { return }
        
        guard
            let newItem = controller.selectedObjects.first as? [String: String],
            let extensions = newItem[FileDropComposer.SettingKey.extensions], !extensions.isEmpty
            else {
                // delete row if empty
                // -> set false to flag for in case that the delete button was pressed while editing and the target can be automatically deleted
                self.deletingFileDrop = false
                controller.remove(nil)
                return
        }
        
        // sanitize
        let newExtensions = type(of: self).sanitize(extensionsString: extensions)
        
        // save if new text valid
        if !newExtensions.isEmpty {
            (controller.selection as AnyObject).setValue(newExtensions, forKey: FileDropComposer.SettingKey.extensions)
        } else if let format = newItem[FileDropComposer.SettingKey.formatString], format.isEmpty {
            controller.remove(nil)
        }
        
        self.saveSetting()
    }
    
    
    /// start editing extantion table field just added
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        guard let content = (rowView.view(atColumn: 0) as? NSTableCellView)?.textField?.stringValue else { return }
        
        let isLastRow = (tableView.numberOfRows - 1 == row)
        
        if isLastRow && content.isEmpty {
            tableView.editColumn(0, row: row, with: nil, select: true)
        }
    }
    
    
    /// set action on swiping theme name
    @available(macOS 10.11, *)
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        
        guard edge == .trailing else { return [] }
        
        // delete
        return [NSTableViewRowAction(style: .destructive,
                                     title: NSLocalizedString("Delete", comment: "table view action title"),
                                     handler: { [weak self] (action: NSTableViewRowAction, row: Int) in
                                        self?.deletingFileDrop = true
                                        self?.deleteSetting(at: row)
            })]
    }
    
    
    // Text View Delegate < fromatTextView
    
    /// insertion format text view was edited
    func textDidEndEditing(_ notification: Notification) {
        
        guard let textView = notification.object as? NSTextView, textView == self.formatTextView else { return }
        
        self.saveSetting()
    }
    
    
    
    // MARK: Action Messages
    
    /// variable insertion menu was selected
    @IBAction func insertVariable(_ sender: Any?) {
        
        guard let menuItem = sender as? NSMenuItem else { return }
        guard let textView = self.formatTextView else { return }
        
        let title = menuItem.title
        let range = textView.rangeForUserTextChange
        
        self.view.window?.makeFirstResponder(textView)
        if textView.shouldChangeText(in: range, replacementString: title) {
            textView.replaceCharacters(in: range, with: title)
            textView.didChangeText()
        }
    }
    
    
    /// add file drop setting
    @IBAction func addSetting(_ sender: Any?) {
        
        self.endEditing()
        
        self.fileDropController?.add(self)
    }
    
    
    /// remove selected file drop setting
    @IBAction func removeSetting(_ sender: Any?) {
        
        guard let selectedRow = self.extensionTableView?.selectedRow, selectedRow != -1 else { return }
        
        // raise flag for in case that the delete button was pressed while editing and the target can be automatically deleted
        self.deletingFileDrop = true
        
        self.endEditing()
        
        // ask user for deletion
        self.deleteSetting(at: selectedRow)
    }
    
    
    
    // MARK: Private Methods
    
    /// write back file drop setting to UserDefaults
    private func saveSetting() {
        
        guard let content = self.fileDropController?.content as? [Any] else { return }
        
        UserDefaults.standard[.fileDropArray] = content
    }
    
    
    /// set file drop setting to ArrayController
    private func loadSetting() {
        
        // load/save settings manually rather than binding directly to UserDefaults
        // because Binding to UserDefaults has problems for example when zero-length string was set
        // http://www.hmdt-web.net/bbs/bbs.cgi?bbsname=mkino&mode=res&no=203&oyano=203&line=0
        
        // make data mutable for NSArrayController
        let content = NSMutableArray()
        if let settings = UserDefaults.standard[.fileDropArray] as? [[String: String]] {
            for setting in settings {
                content.add(NSMutableDictionary(dictionary: setting))
            }
        }
        self.fileDropController?.content = content
    }
    
    
    /// trim extension string format or return nil if all invalid
    private static func sanitize(extensionsString: String) -> String {
        
        guard !extensionsString.isEmpty else { return "" }
        
        let trimSet = CharacterSet(charactersIn: "./ \t\r\n")
        let extensions = extensionsString.components(separatedBy: ",")
        
        // trim
        let sanitizedExtensions: [String] = extensions.flatMap { extension_ in
            let trimmed = extension_.trimmingCharacters(in: trimSet)
            return trimmed.isEmpty ? nil : trimmed
        }
        
        return sanitizedExtensions.joined(separator: ", ")
    }
    
    
    /// ask if user really wants to delete the item
    private func deleteSetting(at row: Int) {
        
        // do nothing if it's already removed in `controlTextDidEndEditing:`
        guard self.deletingFileDrop else { return }
        
        guard let objects = self.fileDropController?.arrangedObjects as? [[String: String]] else { return }
        
        // obtain extension to delete for display
        let extension_ = objects[row][FileDropComposer.SettingKey.extensions] ?? ""
        
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("Are you sure you want to delete the file drop setting for “%@”?", comment: ""), extension_)
        alert.informativeText = NSLocalizedString("Deleted setting can’t be restored.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        
        alert.beginSheetModal(for: self.view.window!) { [weak self] (returnCode: NSModalResponse) in
            guard let strongSelf = self else { return }
            
            guard returnCode == NSAlertSecondButtonReturn else {  // cancelled
                // flush swipe action for in case if this deletion was invoked by swiping the theme name
                if #available(macOS 10.11, *) {
                    strongSelf.extensionTableView?.rowActionsVisible = false
                }
                return
            }
            guard strongSelf.deletingFileDrop else { return }
            
            strongSelf.fileDropController?.remove(atArrangedObjectIndex: row)
            strongSelf.saveSetting()
            strongSelf.deletingFileDrop = false
        }
    }
    
}
