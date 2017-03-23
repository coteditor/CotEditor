/*
 
 BatchReplacementListViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-03-17.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
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
import AudioToolbox

final class BatchReplacementListViewController: NSViewController, BatchReplacementPanelViewControlling {
    
    // MARK: Private Properties
    
    fileprivate var settingNames = [String]()
    
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // register droppable types
        self.tableView?.register(forDraggedTypes: [kUTTypeFileURL as String])
        
        // observe replacement setting list change
        NotificationCenter.default.addObserver(self, selector: #selector(setupList), name: .SettingListDidUpdate, object: ReplacementManager.shared)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
    }
    
    
    /// apply current state to menu items
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextualMenu = (menuItem.menu == self.tableView?.menu)
        
        let representedSettingName: String? = {
            guard isContextualMenu else {
                return self.selectedSettingName
            }
            
            guard let clickedRow = self.tableView?.clickedRow, clickedRow != -1 else { return nil }  // clicked blank area
            
            return self.settingNames[safe: clickedRow]
        }()
        menuItem.representedObject = representedSettingName
        
        let itemSelected = (representedSettingName != nil)
        
        guard let action = menuItem.action else { return false }
        
        // append target setting name to menu titles
        switch action {
        case #selector(addSetting), #selector(importSetting(_:)):
            menuItem.isHidden = (isContextualMenu && itemSelected)
            
        case #selector(renameSetting(_:)):
            if let name = representedSettingName, !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Rename “%@”", comment: ""), name)
            }
            menuItem.isHidden = !itemSelected
            
        case #selector(duplicateSetting(_:)):
            if let name = representedSettingName, !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Duplicate “%@”", comment: ""), name)
            }
            menuItem.isHidden = !itemSelected
            
        case #selector(deleteSetting(_:)):
            menuItem.isHidden = !itemSelected
            
        case #selector(exportSetting(_:)):
            if let name = representedSettingName, !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Export “%@”…", comment: ""), name)
            }
            menuItem.isHidden = !itemSelected
            
        case #selector(revealSettingInFinder(_:)):
            if let name = representedSettingName, !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Reveal “%@” in Finder", comment: ""), name)
            }
            
        default: break
        }
        
        return true
    }
    
    
    
    // MARK: Action Messages
    
    /// add setting
    @IBAction func addSetting(_ sender: Any?) {
        
        guard let tableView = self.tableView else { return }
        
        try? ReplacementManager.shared.createUntitledSetting { (settingName: String) in
            let settingNames = ReplacementManager.shared.settingNames
            let row = settingNames.index(of: settingName) ?? 0
            
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }
    
    
    /// duplicate selected setting
    @IBAction func duplicateSetting(_ sender: Any?) {
        
        guard let settingName = self.targetSettingName(for: sender) else { return }
        
        try? ReplacementManager.shared.duplicateSetting(name: settingName)
    }
    
    
    /// rename selected setting
    @IBAction func renameSetting(_ sender: Any?) {
        
        guard
            let settingName = self.targetSettingName(for: sender),
            let row = self.settingNames.index(of: settingName)
            else { return }
        
        self.tableView?.editColumn(0, row: row, with: nil, select: false)
    }
    
    
    /// remove selected setting
    @IBAction func deleteSetting(_ sender: Any?) {
        
        guard let settingName = self.targetSettingName(for: sender) else { return }
        
        self.deleteSetting(name: settingName)
    }
    
    
    /// export selected setting
    @IBAction func exportSetting(_ sender: Any?) {
        
        guard let settingName = self.targetSettingName(for: sender) else { return }
       
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.nameFieldLabel = NSLocalizedString("Export As:", comment: "")
        savePanel.nameFieldStringValue = settingName
        savePanel.allowedFileTypes = []
        
        savePanel.beginSheetModal(for: self.view.window!) { (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            try? ReplacementManager.shared.exportSetting(name: settingName, to: savePanel.url!)
        }
    }
    
    
    /// import a setting file
    @IBAction func importSetting(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = NSLocalizedString("Import", comment: "")
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = [ReplacementManager.shared.filePathExtension]
        
        openPanel.beginSheetModal(for: self.view.window!) { [weak self] (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            self?.importSetting(fileURL: openPanel.url!)
        }
    }
    
    
    /// open directory in Application Support in Finder where the selected setting exists
    @IBAction func revealSettingInFinder(_ sender: Any?) {
        
        guard
            let settingName = self.targetSettingName(for: sender),
            let url = ReplacementManager.shared.urlForUserSetting(name: settingName)
            else { return }
        
        NSWorkspace.shared().activateFileViewerSelecting([url])
    }
    
    
    /// reload all setting files in Application Support
    @IBAction func reloadAllSettings(_ sender: Any?) {
        
        ReplacementManager.shared.updateCache()
    }
    
    
    
    // MARK: Private Methods
    
    /// return setting name which is currently selected in the list table
    fileprivate dynamic var selectedSettingName: String? {
        
        let index = self.tableView?.selectedRow ?? 0
        
        return self.settingNames[safe: index]
    }
    
    
    /// return representedObject if sender is menu item, otherwise selection in the list table
    private func targetSettingName(for sender: Any?) -> String? {
        
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as? String
        }
        return self.selectedSettingName
    }
    
    
    /// try to delete given setting
    fileprivate func deleteSetting(name: String) {
        
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("Are you sure you want to delete “%@”?", comment: ""), name)
        alert.informativeText = NSLocalizedString("This action cannot be undone.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        
        let window = self.view.window!
        alert.beginSheetModal(for: window) { (returnCode: NSModalResponse) in
            
            guard returnCode == NSAlertSecondButtonReturn else { return }  // cancelled
            
            do {
                try ReplacementManager.shared.removeSetting(name: name)
                
            } catch {
                alert.window.orderOut(nil)
                NSBeep()
                NSAlert(error: error).beginSheetModal(for: window)
                return
            }
            
            AudioServicesPlaySystemSound(.moveToTrash)
        }
    }
    
    
    /// try to import setting file at given URL
    fileprivate func importSetting(fileURL: URL) {
        
        do {
            try ReplacementManager.shared.importSetting(fileURL: fileURL)
        } catch {
            // ask for overwriting if a setting with the same name already exists
            self.presentError(error)
        }
    }
    
    
    /// update setting list
    @objc private func setupList() {
        
        let settingName = self.selectedSettingName
        
        self.settingNames = ReplacementManager.shared.settingNames
        
        self.tableView?.reloadData()
        
        if let settingName = settingName,
            let row = self.settingNames.index(of: settingName)
        {
            self.tableView?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }
    
}



// MARK: - TableView Data Source

extension BatchReplacementListViewController: NSTableViewDataSource {
    
    /// number of settings
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return ReplacementManager.shared.settings.count
    }
    
    
    /// content of table cell
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        return self.settingNames[safe: row]
    }
    
    
    /// validate when dragged items come to tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        
        // get file URLs from pasteboard
        let pboard = info.draggingPasteboard()
        let objects = pboard.readObjects(forClasses: [NSURL.self],
                                         options: [NSPasteboardURLReadingFileURLsOnlyKey: true,
                                                   NSPasteboardURLReadingContentsConformToTypesKey: [DocumentType.replacement.UTType]])
        
        guard let urls = objects, !urls.isEmpty else { return [] }
        
        // highlight text view itself
        tableView.setDropRow(-1, dropOperation: .on)
        
        // show number of setting files
        info.numberOfValidItemsForDrop = urls.count
        
        return .copy
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        
        info.enumerateDraggingItems(for: tableView, classes: [NSURL.self],
                                    searchOptions: [NSPasteboardURLReadingFileURLsOnlyKey: true,
                                                    NSPasteboardURLReadingContentsConformToTypesKey: [DocumentType.replacement.UTType]])
        { [weak self] (draggingItem: NSDraggingItem, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            
            guard let fileURL = draggingItem.item as? URL else { return }
            
            self?.importSetting(fileURL: fileURL)
        }
        
        return true
    }
    
}



// MARK: - TableView Delegate

extension BatchReplacementListViewController: NSTableViewDelegate {
    
    /// selection of setting table did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard
            let settingName = self.selectedSettingName,
            let setting = ReplacementManager.shared.settings[settingName]
            else { return }
        
        self.mainViewController?.representedObject = setting
    }
    
}



// MARK: - TextField Delegate

extension BatchReplacementListViewController: NSTextFieldDelegate {
    
    /// setting name was edited
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        // finish if empty (The original name will be restored automatically)
        guard
            let newName = fieldEditor.string, !newName.isEmpty,
            let oldName = self.selectedSettingName
            else { return true }
        
        do {
            try ReplacementManager.shared.renameSetting(name: oldName, to: newName)
            
        } catch {
            // revert name
            fieldEditor.string = oldName
            
            // show alert
            NSAlert(error: error).beginSheetModal(for: self.view.window!)
            return false
        }
        
        return true
    }
    
}
