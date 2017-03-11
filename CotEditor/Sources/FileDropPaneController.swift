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
    
    @IBOutlet private var fileDropController: NSArrayController?
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private weak var variableInsertionMenu: NSPopUpButton?
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
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // setup variable menu
        if let menu = self.variableInsertionMenu?.menu {
            menu.addItems(for: FileDropComposer.Token.pathTokens, target: self.formatTextView)
            menu.addItem(.separator())
            menu.addItems(for: FileDropComposer.Token.imageTokens, target: self.formatTextView)
        }
    }
    
    
    /// apply current settings to UI
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.loadSetting()
    }
    
    
    /// finish current editing
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        self.endEditing()
        self.saveSetting()
    }
    
    
    
    // MARK: Delegate
    
    /// extension field was edited
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        guard control.identifier == FileDropComposer.SettingKey.extensions else { return true }
        
        // sanitize
        if let string = fieldEditor.string {
            fieldEditor.string = type(of: self).sanitize(extensionsString: string)
        }
        
        self.saveSetting()
        
        return true
    }
    
    
    /// setup scope popup menu
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        guard
            let cellView = rowView.view(atColumn: 1) as? NSTableCellView,
            let menu = cellView.subviews.first as? NSPopUpButton,
            let item = cellView.objectValue as? [String: String]
            else {
                assertionFailure()
                return
        }
        
        // reset attributed string for "All" item
        // -> Otherwise, the title isn't localized.
        let allItem = menu.itemArray.first!
        allItem.attributedTitle = NSAttributedString(string: allItem.title, attributes: allItem.attributedTitle!.attributes(at: 0, effectiveRange: nil))
        
        
        // add styles
        for styleName in SyntaxManager.shared.styleNames {
            menu.addItem(withTitle: styleName)
            menu.lastItem!.representedObject = styleName
        }
        
        // select item
        if let scope = item[FileDropComposer.SettingKey.scope] {
            menu.selectItem(withTitle: scope)
        } else {
            if let emptyItem = menu.itemArray.first(where: { !$0.isSeparatorItem && $0.title.isEmpty }) {
                menu.menu?.removeItem(emptyItem)
            }
            menu.selectItem(at: 0)
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
    
    /// add file drop setting
    @IBAction func addSetting(_ sender: Any?) {
        
        self.endEditing()
        
        self.fileDropController?.add(self)
    }
    
    
    /// remove selected file drop setting
    @IBAction func removeSetting(_ sender: Any?) {
        
        guard let selectedRow = self.tableView?.selectedRow, selectedRow != -1 else { return }
        
        self.endEditing()
        
        // ask user for deletion
        self.deleteSetting(at: selectedRow)
    }
    
    
    
    // MARK: Private Methods
    
    /// write back file drop setting to UserDefaults
    private func saveSetting() {
        
        guard let content = self.fileDropController?.content as? [[String: String]] else { return }
        
        // sanitize
        UserDefaults.standard[.fileDropArray] = content.flatMap { (item: [String: String]) -> [String: String]? in
            
            if let extensions = item[FileDropComposer.SettingKey.extensions], extensions.isEmpty {
                var item = item
                item[FileDropComposer.SettingKey.extensions] = nil
            }
            
            guard item[FileDropComposer.SettingKey.extensions] != nil || item[FileDropComposer.SettingKey.scope] != nil else { return nil }
            
            return item
        }
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
    
    
    /// trim extension string format
    private static func sanitize(extensionsString: String) -> String {
        
        let trimSet = CharacterSet.alphanumerics.inverted  // separator + typical invalid characters
        
        return extensionsString
            .components(separatedBy: trimSet)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .joined(separator: ", ")
    }
    
    
    /// ask if user really wants to delete the item
    private func deleteSetting(at row: Int) {
        
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
                    strongSelf.tableView?.rowActionsVisible = false
                }
                return
            }
            
            strongSelf.fileDropController?.remove(atArrangedObjectIndex: row)
            strongSelf.saveSetting()
        }
    }
    
}
