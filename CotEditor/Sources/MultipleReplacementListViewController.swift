//
//  MultipleReplacementListViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2022 1024jp
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
import AudioToolbox
import UniformTypeIdentifiers

final class MultipleReplacementListViewController: NSViewController, NSMenuItemValidation {
    
    // MARK: Private Properties
    
    private var settingNames: [String] = []
    
    private var listUpdateObserver: AnyCancellable?
    private lazy var filePromiseQueue = OperationQueue()
    
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.detailViewController?.delegate = self
        
        // register drag & drop types
        let receiverTypes = NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) }
        self.tableView?.registerForDraggedTypes([.fileURL] + receiverTypes)
        self.tableView?.setDraggingSourceOperationMask(.copy, forLocal: false)
        
        // create blank if empty
        if ReplacementManager.shared.settingNames.isEmpty {
            do {
                try ReplacementManager.shared.createUntitledSetting()
            } catch {
                NSAlert(error: error).beginSheetModal(for: self.view.window!)
            }
        }
        
        self.settingNames = ReplacementManager.shared.settingNames
        
        // select an item in list
        let row: Int = {
            guard
                let lastSelectedName = UserDefaults.standard[.selectedMultipleReplacementSettingName],
                let row = self.settingNames.firstIndex(of: lastSelectedName)
            else { return 0 }
            
            return row
        }()
        self.tableView?.selectRowIndexes([row], byExtendingSelection: false)
        
        // observe replacement setting list change
        self.listUpdateObserver = ReplacementManager.shared.$settingNames
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateSettingList() }
    }
    
    
    
    // MARK: Menu Item Validation
    
    /// apply current state to menu items
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextualMenu = (menuItem.menu == self.tableView?.menu)
        let representedSettingName = self.representedSettingName(for: menuItem.menu)
        menuItem.representedObject = representedSettingName
        
        let itemSelected = (representedSettingName != nil)
        
        // append target setting name to menu titles
        switch menuItem.action {
            case #selector(addSetting), #selector(importSetting(_:)):
                menuItem.isHidden = (isContextualMenu && itemSelected)
            
            case #selector(renameSetting(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Rename “\(name)”")
                }
                menuItem.isHidden = !itemSelected
            
            case #selector(duplicateSetting(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Duplicate “\(name)”")
                }
                menuItem.isHidden = !itemSelected
            
            case #selector(deleteSetting(_:)):
                menuItem.isHidden = !itemSelected
            
            case #selector(exportSetting(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Export “\(name)”…")
                }
                menuItem.isHidden = !itemSelected
                
            case #selector(revealSettingInFinder(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Reveal “\(name)” in Finder")
                }
                
            case nil:
                return false
            
            default:
                break
        }
        
        return true
    }
    
    
    
    // MARK: Action Messages
    
    /// Add a blank setting.
    @IBAction func addSetting(_ sender: Any?) {
        
        let settingName: String
        do {
            settingName = try ReplacementManager.shared.createUntitledSetting()
        } catch {
            self.presentError(error)
            return
        }
        
        self.updateSettingList(bySelecting: settingName)
    }
    
    
    /// Duplicate the selected setting.
    @IBAction func duplicateSetting(_ sender: Any?) {
        
        guard let baseName = self.targetSettingName(for: sender) else { return }
        
        let settingName: String
        do {
            settingName = try ReplacementManager.shared.duplicateSetting(name: baseName)
        } catch {
            self.presentError(error)
            return
        }
        
        self.updateSettingList(bySelecting: settingName)
    }
    
    
    /// Rename the selected setting.
    @IBAction func renameSetting(_ sender: Any?) {
        
        guard
            let settingName = self.targetSettingName(for: sender),
            let row = self.settingNames.firstIndex(of: settingName)
        else { return }
        
        self.tableView?.editColumn(0, row: row, with: nil, select: false)
    }
    
    
    /// Remove the selected setting.
    @IBAction func deleteSetting(_ sender: Any?) {
        
        guard let settingName = self.targetSettingName(for: sender) else { return }
        
        self.deleteSetting(name: settingName)
    }
    
    
    /// Export the selected setting.
    @IBAction func exportSetting(_ sender: Any?) {
        
        guard let settingName = self.targetSettingName(for: sender) else { return }
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.isExtensionHidden = true
        savePanel.nameFieldLabel = "Export As:".localized
        savePanel.nameFieldStringValue = settingName
        savePanel.allowedContentTypes = [ReplacementManager.shared.fileType]
        
        Task {
            guard await savePanel.beginSheetModal(for: self.view.window!) == .OK else { return }
            
            do {
                try ReplacementManager.shared.exportSetting(name: settingName, to: savePanel.url!, hidesExtension: savePanel.isExtensionHidden)
            } catch {
                self.presentError(error)
            }
        }
    }
    
    
    /// Import a setting file.
    @IBAction func importSetting(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Import".localized
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = [ReplacementManager.shared.fileType]
        
        Task {
            guard await openPanel.beginSheetModal(for: self.view.window!) == .OK else { return }
            
            self.importSetting(fileURL: openPanel.url!)
        }
    }
    
    
    /// Open the directory in Application Support in the Finder where the selected setting exists.
    @IBAction func revealSettingInFinder(_ sender: Any?) {
        
        guard
            let settingName = self.targetSettingName(for: sender),
            let url = ReplacementManager.shared.urlForUserSetting(name: settingName)
        else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    
    /// Reload all setting files in Application Support.
    @IBAction func reloadAllSettings(_ sender: Any?) {
        
        ReplacementManager.shared.reloadCache()
    }
    
    
    
    // MARK: Private Methods
    
    /// Return the view controller for the detail view on the right side in the panel.
    private var detailViewController: MultipleReplacementViewController? {
        
        (self.parent as? MultipleReplacementSplitViewController)?.detailSplitViewItem?.viewController as? MultipleReplacementViewController
    }
    
    
    /// Return setting name which is currently selected in the list table.
    private var selectedSettingName: String? {
        
        let index = self.tableView?.selectedRow ?? 0
        
        return self.settingNames[safe: index]
    }
    
    
    /// Return representedObject if sender is menu item, otherwise selection in the list table.
    ///
    /// - Parameter sender: The sender of the current action if available.
    /// - Returns: The name of the target setting.
    private func targetSettingName(for sender: Any?) -> String? {
        
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as? String
        }
        return self.selectedSettingName
    }
    
    
    private func representedSettingName(for menu: NSMenu?) -> String? {
        
        guard self.tableView?.menu == menu else {
            return self.selectedSettingName
        }
        
        guard let clickedRow = self.tableView?.clickedRow, clickedRow != -1 else { return nil }  // clicked blank area
        
        return self.settingNames[safe: clickedRow]
    }
    
    
    /// Try to delete the given setting.
    ///
    /// - Parameter name: The name of the setting to delete.
    private func deleteSetting(name: String) {
        
        let alert = NSAlert()
        alert.messageText = String(localized: "Are you sure you want to delete “\(name)”?")
        alert.informativeText = "This action cannot be undone.".localized
        alert.addButton(withTitle: "Cancel".localized)
        alert.addButton(withTitle: "Delete".localized)
        alert.buttons.last?.hasDestructiveAction = true
        
        let window = self.view.window!
        Task {
            guard await alert.beginSheetModal(for: window) == .alertSecondButtonReturn else { return }  // cancelled
            
            do {
                try ReplacementManager.shared.removeSetting(name: name)
                
            } catch {
                alert.window.orderOut(nil)
                NSSound.beep()
                await NSAlert(error: error).beginSheetModal(for: window)
                return
            }
            
            AudioServicesPlaySystemSound(.moveToTrash)
            
            // add new blank setting to avoid empty list
            if ReplacementManager.shared.settingNames.isEmpty {
                self.addSetting(nil)
            }
        }
    }
    
    
    /// Try to import setting file at given URL.
    ///
    /// - Parameter fileURL: The file URL of the setting to import.
    private func importSetting(fileURL: URL) {
        
        do {
            try ReplacementManager.shared.importSetting(fileURL: fileURL)
        } catch {
            // ask for overwriting if a setting with the same name already exists
            self.presentError(error)
        }
    }
    
    
    /// Update setting list view.
    ///
    /// - Parameter selectingName: The setting name to select after the view update.
    private func updateSettingList(bySelecting selectingName: String? = nil) {
        
        let settingName = selectingName ?? self.selectedSettingName
        
        self.settingNames = ReplacementManager.shared.settingNames
        
        guard let tableView = self.tableView else { return }
        
        tableView.reloadData()
        
        guard
            let name = settingName,
            let row = self.settingNames.firstIndex(of: name)
        else { return }
        
        tableView.selectRowIndexes([row], byExtendingSelection: false)
        if selectingName != nil {
            tableView.scrollRowToVisible(row)
        }
    }
    
    
    /// Save the given setting as the current selected name.
    ///
    /// - Parameter setting: The setting to save.
    private func saveSetting(setting: MultipleReplacement) {
        
        guard let name = self.selectedSettingName else { return }
        
        do {
            try ReplacementManager.shared.save(setting: setting, name: name)
        } catch {
            print(error.localizedDescription)
        }
    }
}



// MARK: - MultipleReplacementViewController Delegate

extension MultipleReplacementListViewController: MultipleReplacementViewControllerDelegate {
    
    /// replacement definition being edited in the main view did update
    func didUpdate(setting: MultipleReplacement) {
        
        self.saveSetting(setting: setting)
    }
}



// MARK: - TableView Data Source

extension MultipleReplacementListViewController: NSTableViewDataSource {
    
    /// number of settings
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        self.settingNames.count
    }
    
    
    /// content of table cell
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        self.settingNames[row]
    }
    
    
    /// validate when dragged items come to tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        guard
            info.draggingSource as? NSTableView != tableView,  // avoid self D&D
            let count = info.filePromiseReceivers(with: .cotReplacement, for: tableView)?.count
                     ?? info.fileURLs(with: .cotReplacement, for: tableView)?.count
        else { return [] }
        
        // highlight table view itself
        tableView.setDropRow(-1, dropOperation: .on)
        
        // show number of acceptable files
        info.numberOfValidItemsForDrop = count
        
        return .copy
    }
    
    
    /// check acceptability of dropped items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        if let receivers = info.filePromiseReceivers(with: .cotReplacement, for: tableView) {
            let dropDirectoryURL = FileManager.default.createTemporaryDirectory()
            
            for receiver in receivers {
                receiver.receivePromisedFiles(atDestination: dropDirectoryURL, operationQueue: .main) { [weak self] (fileURL, error) in
                    if let error = error {
                        self?.presentError(error)
                        return
                    }
                    self?.importSetting(fileURL: fileURL)
                }
            }
            
        } else if let fileURLs = info.fileURLs(with: .cotReplacement, for: tableView) {
            for fileURL in fileURLs {
                self.importSetting(fileURL: fileURL)
            }
            
        } else {
            return false
        }
        
        return true
    }
    
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        
        let provider = NSFilePromiseProvider(fileType: UTType.cotReplacement.identifier, delegate: self)
        provider.userInfo = self.settingNames[row]
        
        return provider
    }
}


// MARK: - File Promise Provider Delegate

extension MultipleReplacementListViewController: NSFilePromiseProviderDelegate {
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        
        (filePromiseProvider.userInfo as! String) + "." + UTType.cotReplacement.preferredFilenameExtension!
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL) async throws {
        
        guard
            let settingName = filePromiseProvider.userInfo as? String,
            let sourceURL = ReplacementManager.shared.urlForUserSetting(name: settingName)
        else { return }
        
        try FileManager.default.copyItem(at: sourceURL, to: url)
    }
    
    
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        
        self.filePromiseQueue
    }
}


// MARK: - TableView Delegate

extension MultipleReplacementListViewController: NSTableViewDelegate {
    
    /// selection of setting table will change
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        // save the unsaved change before the selection changes
        self.detailViewController?.commitEditing()
        
        return true
    }
    
    
    /// selection of setting table did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard
            let settingName = self.selectedSettingName,
            let setting = ReplacementManager.shared.setting(name: settingName)
        else { return }
        
        self.detailViewController?.change(setting: setting)
        UserDefaults.standard[.selectedMultipleReplacementSettingName] = settingName
    }
}



// MARK: - TextField Delegate

extension MultipleReplacementListViewController: NSTextFieldDelegate {
    
    /// setting name was edited
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        // finish if empty (The original name will be restored automatically)
        let newName = fieldEditor.string
        guard
            !newName.isEmpty,
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



// MARK: - Menu Delegate

extension MultipleReplacementListViewController: NSMenuDelegate {
    
    func menuWillOpen(_ menu: NSMenu) {
        
        // create share menu dynamically
        if let shareMenuItem = menu.items.compactMap({ $0 as? ShareMenuItem }).first,
           let settingName = self.representedSettingName(for: menu) ?? self.selectedSettingName
        {
            shareMenuItem.sharingItems = ReplacementManager.shared.urlForUserSetting(name: settingName).flatMap { [$0] }
        }
    }
}
