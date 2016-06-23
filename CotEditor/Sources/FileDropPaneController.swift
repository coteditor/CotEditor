/*
 
 FileDropPaneController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-18.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

class FileDropPaneController: NSViewController, NSTableViewDelegate, NSTextFieldDelegate, NSTextViewDelegate {
    
    private var deletingFileDrop = false
    
    @IBOutlet private var fileDropController: NSArrayController?
    @IBOutlet private weak var extensionTableView: NSTableView?
    @IBOutlet private var formatTextView: NSTextView?  // NSTextView cannot be weak
    @IBOutlet private var glossaryTextView: NSTextView?  // NSTextView cannot be weak
    
    
    
    // MARK:
    // MARK: View Controller Methods
    
    /// nib name
    override var nibName: String? {
        
        return "FileDropPane"
    }
    
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // load setting
        self.loadSetting()
        
        // set localized glossary to view
        let glossaryURL = Bundle.main().urlForResource("FileDropGlossary", withExtension: "txt")!
        let glossary = try! String(contentsOf: glossaryURL)
        self.glossaryTextView?.string = glossary
    }
    
    
    /// finish current editing
    override func viewWillDisappear() {
        
        self.commitEditing()
        self.saveSetting()
    }
    
    
    
    // MARK: Delegate
    
    /// extension table was edited
    override func controlTextDidEndEditing(_ obj: Notification) {
        
        guard obj.object is NSTextField else { return }
        
        guard let extensions = self.fileDropController?.selection.value(forKey: CEFileDropExtensionsKey) as? String,
              let format = self.fileDropController?.selection.value(forKey: CEFileDropFormatStringKey) as? String else
        {
            // delete row if empty
            // -> set false to flag for in case that the delete button was pressed while editing and the target can be automatically deleted
            self.deletingFileDrop = false
            self.fileDropController?.remove(self)
            return
        }
        
        // sanitize
        let newExtensions = self.dynamicType.sanitize(extensionsString: extensions)
        
        // save if new text valid
        if !newExtensions.isEmpty {
            self.fileDropController?.selection.setValue(newExtensions, forKey: CEFileDropExtensionsKey)
        } else if format.isEmpty {
            self.fileDropController?.remove(self)
        }
        
        self.saveSetting()
    }
    
    
    /// start editing extantion table field just added
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        let isLastRow = tableView.numberOfRows - 1 == row
        guard let content = rowView.view(atColumn: 0)?.textField??.stringValue else { return }
        
        if isLastRow && content.isEmpty {
            tableView.editColumn(0, row: row, with: nil, select: true)
        }
    }
    
    
    /// set action on swiping theme name
    @available(OSX 10.11, *)
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
        
        guard let textView = notification.object as? NSTextView where textView == self.formatTextView else { return }
        
        self.saveSetting()
    }
    
    
    
    // MARK: Action Messages
    
    /// preset token insertion menu was selected
    @IBAction func insertToken(_ sender: AnyObject?) {
        
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
    @IBAction func addSetting(_ sender: AnyObject?) {
        
        self.commitEditing()
        
        self.fileDropController?.add(self)
    }
    
    
    /// remove selected file drop setting
    @IBAction func removeSetting(_ sender: AnyObject?) {
        
        guard let selectedRow = self.extensionTableView?.selectedRow where selectedRow != -1 else { return }
        
        // raise flag for in case that the delete button was pressed while editing and the target can be automatically deleted
        self.deletingFileDrop = true
        
        self.commitEditing()
        
        // ask user for deletion
        self.deleteSetting(at: selectedRow)
        
    }
    
    
    
    // MARK: Private Methods
    
    /// write back file drop setting to UserDefaults
    private func saveSetting() {
        
        guard let content = self.fileDropController?.content else { return }
        
        UserDefaults.standard().set(content, forKey: CEDefaultFileDropArrayKey)
    }
    
    
    /// set file drop setting to ArrayController
    private func loadSetting() {
        
        // load/save settings manually rather than binding directly to UserDefaults
        // because Binding to UserDefaults has problems for example when zero-length string was set
        // http://www.hmdt-web.net/bbs/bbs.cgi?bbsname=mkino&mode=res&no=203&oyano=203&line=0
        
        // make data mutable for NSArrayController
        let content = NSMutableArray()
        if let settings = UserDefaults.standard().array(forKey: CEDefaultFileDropArrayKey) as? [[String: String]] {
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
        var sanitizedExtensions = [String]()
        
        // trim
        for extension_ in extensions {
            let sanitizedExtension = extension_.trimmingCharacters(in: trimSet)
            if !sanitizedExtensions.isEmpty {
                sanitizedExtensions.append(sanitizedExtension)
            }
        }
        
        guard !sanitizedExtensions.isEmpty else { return "" }
        
        return sanitizedExtensions.joined(separator: ", ")
    }
    
    
    /// ask if user really wants to delete the item
    private func deleteSetting(at row: Int) {
        
        // do nothing if it's already removed in `controlTextDidEndEditing:`
        guard self.deletingFileDrop else { return }
        
        guard let objects = self.fileDropController?.arrangedObjects as? [[String: String]] else { return }
        
        // obtain extension to delete for display
        let extension_ = objects[row][CEFileDropExtensionsKey] ?? ""
        
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("Are you sure you want to delete the file drop setting for “%@”?", comment: ""), extension_)
        alert.informativeText = NSLocalizedString("Deleted setting can’t be restored.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        
        alert.beginSheetModal(for: self.view.window!) { [unowned self] (returnCode: NSModalResponse) in
            
            guard returnCode == NSAlertSecondButtonReturn else { return } // = Cancel
            guard self.deletingFileDrop else { return }
            
            self.fileDropController?.remove(atArrangedObjectIndex: row)
            self.saveSetting()
            self.deletingFileDrop = false
        }
    }
    
}
