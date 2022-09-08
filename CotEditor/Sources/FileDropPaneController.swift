//
//  FileDropPaneController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2022 1024jp
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

import Combine
import Cocoa

final class FileDropPaneController: NSViewController, NSTableViewDelegate, NSTextFieldDelegate, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    private var arrayObservers: Set<AnyCancellable> = []
    
    @IBOutlet private var fileDropController: NSArrayController?
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private weak var addRemoveButton: NSSegmentedControl?
    @IBOutlet private weak var variableInsertionMenu: NSPopUpButton?
    @IBOutlet private weak var formatTextView: TokenTextView? {
        
        didSet {
            // set tokenizer for format text view
            formatTextView!.tokenizer = FileDropItem.Token.tokenizer
        }
    }
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // setup add/remove button
        self.arrayObservers.removeAll()
        self.fileDropController?.publisher(for: \.canAdd, options: .initial)
            .sink { [weak self] in self?.addRemoveButton?.setEnabled($0, forSegment: 0) }
            .store(in: &self.arrayObservers)
        self.fileDropController?.publisher(for: \.canRemove, options: .initial)
            .sink { [weak self] in self?.addRemoveButton?.setEnabled($0, forSegment: 1) }
            .store(in: &self.arrayObservers)
        
        // setup variable menu
        if let menu = self.variableInsertionMenu?.menu {
            menu.items += FileDropItem.Token.pathTokens
                .map { $0.insertionMenuItem(target: self.formatTextView) }
            
            menu.addItem(.separator())
            menu.items += FileDropItem.Token.textTokens
                .map { $0.insertionMenuItem(target: self.formatTextView) }
            
            menu.addItem(.separator())
            menu.items += FileDropItem.Token.imageTokens
                .map { $0.insertionMenuItem(target: self.formatTextView) }
        }
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.loadSetting()
    }
    
    
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        self.endEditing()
        self.saveSetting()
    }
    
    
    
    // MARK: Delegate
    
    /// extension field was edited
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        guard control.identifier?.rawValue == FileDropItem.CodingKeys.extensions.rawValue else { return true }
        
        // sanitize
        fieldEditor.string = Self.sanitize(extensionsString: fieldEditor.string)
        
        self.saveSetting()
        
        return true
    }
    
    
    /// setup scope popup menu
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        guard
            let cellView = rowView.view(atColumn: 1) as? NSTableCellView,
            let menu = cellView.subviews.first as? NSPopUpButton,
            let item = cellView.objectValue as? [String: String]
            else { return assertionFailure() }
        
        // reset attributed string for "All" item
        // -> Otherwise, the title isn't localized.
        let allItem = menu.itemArray.first!
        allItem.attributedTitle = NSAttributedString(string: allItem.title, attributes: allItem.attributedTitle!.attributes(at: 0, effectiveRange: nil))
        
        // add styles
        for styleName in SyntaxManager.shared.settingNames {
            menu.addItem(withTitle: styleName)
            menu.lastItem!.representedObject = styleName
        }
        
        // select item
        if let scope = item[FileDropItem.CodingKeys.scope] {
            menu.selectItem(withTitle: scope)
        } else {
            if let emptyItem = menu.itemArray.first(where: { !$0.isSeparatorItem && $0.title.isEmpty }) {
                menu.menu?.removeItem(emptyItem)
            }
            menu.selectItem(at: 0)
        }
    }
    
    
    // Text View Delegate < fromatTextView
    
    /// insertion format text view was edited
    func textDidEndEditing(_ notification: Notification) {
        
        guard let textView = notification.object as? NSTextView, textView == self.formatTextView else { return }
        
        self.saveSetting()
    }
    
    
    
    // MARK: Action Messages
    
    @IBAction func addRemove(_ sender: NSSegmentedControl) {
        
        self.endEditing()
        
        switch sender.selectedSegment {
            case 0:  // add
                self.fileDropController?.add(self)
                
            case 1:  // remove
                self.deleteSelectedSetting()  // ask user for deletion
                
            default:
                preconditionFailure()
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// write back file drop setting to UserDefaults
    private func saveSetting() {
        
        guard let content = self.fileDropController?.content as? [[String: String]] else { return }
        
        // sanitize
        let sanitized = content
            .map { $0.filter { !($0.key == FileDropItem.CodingKeys.extensions.rawValue && $0.value.isEmpty) } }
            .filter { $0[FileDropItem.CodingKeys.format] != nil }
        
        // check if the new setting is different from the default
        let defaultSetting = UserDefaults.standard.registeredValue(for: .fileDropArray)
        if defaultSetting == sanitized {
            UserDefaults.standard.restore(key: .fileDropArray)
        } else {
            UserDefaults.standard[.fileDropArray] = sanitized
        }
    }
    
    
    /// set file drop setting to ArrayController
    private func loadSetting() {
        
        // load/save settings manually rather than binding directly to UserDefaults
        // because Binding to UserDefaults has problems for example when zero-length string was set
        // http://www.hmdt-web.net/bbs/bbs.cgi?bbsname=mkino&mode=res&no=203&oyano=203&line=0
        
        // make data mutable for NSArrayController
        let content = NSMutableArray()
        for setting in UserDefaults.standard[.fileDropArray] {
            content.add(NSMutableDictionary(dictionary: setting))
        }
        self.fileDropController?.content = content
    }
    
    
    /// trim extension string format
    private static func sanitize(extensionsString: String) -> String {
        
        return extensionsString
            .components(separatedBy: CharacterSet.alphanumerics.inverted)  // separator + typical invalid characters
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .joined(separator: ", ")
    }
    
    
    /// ask if user really wants to delete the item
    private func deleteSelectedSetting() {
        
        guard
            let objects = self.fileDropController?.selectedObjects as? [[String: String]],
            !objects.isEmpty
            else { return }
        
        // obtain extension to delete for display
        let fileExtension = objects.first?[FileDropItem.CodingKeys.extensions] ?? ""
        
        let alert = NSAlert()
        alert.messageText = String(localized: "Are you sure you want to delete the file drop setting for “\(fileExtension)”?")
        alert.informativeText = "Deleted setting can’t be restored.".localized
        alert.addButton(withTitle: "Cancel".localized)
        alert.addButton(withTitle: "Delete".localized)
        alert.buttons.last?.hasDestructiveAction = true
        
        Task {
            guard await alert.beginSheetModal(for: self.view.window!) == .alertSecondButtonReturn else { return }
            
            self.fileDropController?.remove(self)
            self.saveSetting()
        }
    }
    
}
