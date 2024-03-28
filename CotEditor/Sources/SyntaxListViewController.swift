//
//  SyntaxListViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2024 1024jp
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

import AppKit
import AudioToolbox
import Combine
import SwiftUI
import UniformTypeIdentifiers

final class SyntaxListViewController: NSViewController, NSMenuItemValidation, NSTableViewDelegate, NSTableViewDataSource, NSFilePromiseProviderDelegate {
    
    // MARK: Private Properties
    
    private var settingNames: [String] = []
    @objc private dynamic var isBundled = false  // bound to remove button
    
    private var observer: AnyCancellable?
    private lazy var filePromiseQueue = OperationQueue()
    
    @IBOutlet private var contextMenu: NSMenu?
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private weak var actionButton: NSButton?
    
    
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView?.doubleAction = #selector(editSetting)
        self.tableView?.target = self
        
        // register drag & drop types
        let receiverTypes = NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) }
        self.tableView?.registerForDraggedTypes([.fileURL] + receiverTypes)
        self.tableView?.setDraggingSourceOperationMask(.copy, forLocal: false)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.observer = Publishers.Merge(SyntaxManager.shared.$settingNames.eraseToVoid(),
                                         SyntaxManager.shared.didUpdateSetting.eraseToVoid())
        .debounce(for: 0, scheduler: RunLoop.main)
        .sink { [weak self] _ in self?.setupMenus() }
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.observer = nil
    }
    
    
    
    // MARK: Menu Item Validation
    
    /// Applies the current state to menu items.
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextMenu = (menuItem.menu == self.contextMenu)
        let settingName = self.representedSettingName(for: menuItem.menu)
        
        menuItem.representedObject = settingName
        
        let itemSelected = (settingName != nil)
        let state = settingName.flatMap(SyntaxManager.shared.state(of:))
        
        // append target setting name to menu titles
        switch menuItem.action {
            case #selector(openSyntaxMappingConflictSheet(_:)):
                return !SyntaxManager.shared.mappingConflicts.isEmpty
                
            case #selector(duplicateSetting(_:)):
                if let settingName, !isContextMenu {
                    menuItem.title = String(localized: "Duplicate “\(settingName)”", comment: "menu item label")
                }
                menuItem.isHidden = !itemSelected
                
            case #selector(deleteSetting(_:)):
                menuItem.isHidden = (state?.isBundled == true || !itemSelected)
                
            case #selector(restoreSetting(_:)):
                if let settingName, !isContextMenu {
                    menuItem.title = String(localized: "Restore “\(settingName)”", comment: "menu item label")
                }
                menuItem.isHidden = (state?.isBundled == false || !itemSelected)
                return state?.isRestorable ?? false
                
            case #selector(exportSetting(_:)):
                if let settingName, !isContextMenu {
                    menuItem.title = String(localized: "Export “\(settingName)”…", comment: "menu item label")
                }
                menuItem.isHidden = !itemSelected
                return state?.isCustomized ?? false
                
            case #selector(shareSetting(_:)):
                menuItem.isHidden = state?.isCustomized != true
                return state?.isCustomized == true
                
            case #selector(revealSettingInFinder(_:)):
                if let settingName, !isContextMenu {
                    menuItem.title = String(localized: "Reveal “\(settingName)” in Finder", comment: "menu item label")
                }
                return state?.isCustomized ?? false
                
            case nil:
                return false
                
            default:
                break
        }
        
        return true
    }
    
    
    
    // MARK: Delegate & Data Source
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        self.settingNames.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        guard
            let settingName = self.settingNames[safe: row],
            let state = SyntaxManager.shared.state(of: settingName)
        else { return nil }
        
        return ["name": settingName,
                "state": state.isCustomized] as [String: Any]
    }
    
    
    
    /// Invoked when the selected syntax in the "Installed syntaxes" list table did change.
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        self.isBundled = SyntaxManager.shared.state(of: self.selectedSettingName)?.isBundled == true
    }
    
    
    /// Validates when dragged items come to tableView.
    func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        guard
            info.draggingSource as? NSTableView != tableView,  // avoid self D&D
            let count = info.filePromiseReceivers(with: .yaml, for: tableView)?.count
                     ?? info.fileURLs(with: .yaml, for: tableView)?.count
        else { return [] }
        
        // highlight table view itself
        tableView.setDropRow(-1, dropOperation: .on)
        
        // show number of acceptable files
        info.numberOfValidItemsForDrop = count
        
        return .copy
    }
    
    
    /// Checks acceptability of dropped items and inserts them to table.
    func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        if let receivers = info.filePromiseReceivers(with: .yaml, for: tableView) {
            let dropDirectoryURL = (try? URL.itemReplacementDirectory) ?? .temporaryDirectory
            
            for receiver in receivers {
                receiver.receivePromisedFiles(atDestination: dropDirectoryURL, operationQueue: .main) { [weak self] (fileURL, error) in
                    if let error {
                        self?.presentError(error)
                        return
                    }
                    self?.importSetting(fileURL: fileURL)
                }
            }
            
        } else if let fileURLs = info.fileURLs(with: .yaml, for: tableView) {
            for fileURL in fileURLs {
                self.importSetting(fileURL: fileURL)
            }
            
        } else {
            return false
        }
        
        AudioServicesPlaySystemSound(.volumeMount)
        
        return true
    }
    
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        
        guard let settingName = self.settingNames[safe: row] else { return nil }
        
        let provider = NSFilePromiseProvider(fileType: UTType.yaml.identifier, delegate: self)
        provider.userInfo = settingName
        
        return provider
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        
        (filePromiseProvider.userInfo as! String) + "." + UTType.yaml.preferredFilenameExtension!
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL) async throws {
        
        guard
            let settingName = filePromiseProvider.userInfo as? String,
            let sourceURL = SyntaxManager.shared.urlForUserSetting(name: settingName)
        else { return }
        
        try FileManager.default.copyItem(at: sourceURL, to: url)
    }
    
    
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        
        self.filePromiseQueue
    }
    
    
    
    // MARK: Action Messages
    
    /// Shows the syntax mapping conflict error sheet.
    @IBAction func openSyntaxMappingConflictSheet(_ sender: Any?) {
        
        let view = SyntaxMappingConflictView(table: SyntaxManager.shared.mappingConflicts)
        let viewController = NSHostingController(rootView: view)
        viewController.rootView.parent = viewController
        
        self.presentAsSheet(viewController)
    }
    
    
    /// Shows the syntax edit sheet.
    @IBAction func editSetting(_ sender: Any?) {
        
        let settingName = self.targetSettingName(for: sender)
        let state = SyntaxManager.shared.state(of: settingName)!
        
        self.presentSyntaxEditor(state: state)
    }
    
    
    /// Duplicates the selected syntax.
    @IBAction func duplicateSetting(_ sender: Any?) {
        
        let baseName = self.targetSettingName(for: sender)
        let settingName: String
        do {
            settingName = try SyntaxManager.shared.duplicateSetting(name: baseName)
        } catch {
            self.presentError(error)
            return
        }
        
        self.updateList(bySelecting: settingName)
    }
    
    
    /// Shows the syntax edit sheet in new mode.
    @IBAction func addSetting(_ sender: Any?) {
        
        self.presentSyntaxEditor()
    }
    
    
    /// Deletes the selected syntax.
    @IBAction func deleteSetting(_ sender: Any?) {
        
        let settingName = self.targetSettingName(for: sender)
        
        self.deleteSetting(name: settingName)
    }
    
    
    /// Restores the selected syntax to original bundled one.
    @IBAction func restoreSetting(_ sender: Any?) {
        
        let settingName = self.targetSettingName(for: sender)
        
        self.restoreSetting(name: settingName)
    }
    
    
    /// Exports the selected syntax.
    @IBAction func exportSetting(_ sender: Any?) {
        
        let settingName = self.targetSettingName(for: sender)
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldLabel = String(localized: "Export As:", comment: "filename field label for save panel")
        savePanel.nameFieldStringValue = settingName
        savePanel.allowedContentTypes = [SyntaxManager.shared.fileType]
        
        Task {
            guard await savePanel.beginSheetModal(for: self.view.window!) == .OK else { return }
            
            do {
                try SyntaxManager.shared.exportSetting(name: settingName, to: savePanel.url!, hidesExtension: savePanel.isExtensionHidden)
            } catch {
                self.presentError(error)
            }
        }
    }
    
    
    /// Imports syntax files via the open panel.
    @IBAction func importSetting(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = String(localized: "Import", comment: "button label")
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = [SyntaxManager.shared.fileType]
        
        Task {
            guard await openPanel.beginSheetModal(for: self.view.window!) == .OK else { return }
            
            for url in openPanel.urls {
                self.importSetting(fileURL: url)
            }
        }
    }
    
    
    /// Shares the selected syntax.
    @IBAction func shareSetting(_ sender: NSMenuItem) {
        
        let settingName = self.targetSettingName(for: sender)
        
        guard let url = SyntaxManager.shared.urlForUserSetting(name: settingName) else { return }
        
        let picker = NSSharingServicePicker(items: [url])
        
        if let view = self.tableView?.clickedRowView {  // context menu
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minX)
            
        } else if let view = self.actionButton {  // action menu
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
    
    
    /// Opens the syntax directory in the Application Support directory in the Finder where the selected syntax exists.
    @IBAction func revealSettingInFinder(_ sender: Any?) {
        
        let settingName = self.targetSettingName(for: sender)
        
        guard let url = SyntaxManager.shared.urlForUserSetting(name: settingName) else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    
    /// Reloads all the syntaxes in the user domain.
    @IBAction func reloadAllSettings(_ sender: Any?) {
        
        Task.detached(priority: .utility) {
            SyntaxManager.shared.loadUserSettings()
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Builds the syntax menus.
    private func setupMenus() {
        
        let settingNames = SyntaxManager.shared.settingNames
        
        // update installed syntax list table
        let selectedSettingName = self.selectedSettingName
        self.settingNames = settingNames
        self.tableView?.reloadData()
        if let index = settingNames.firstIndex(of: selectedSettingName) {
            self.tableView?.selectRowIndexes([index], byExtendingSelection: false)
        }
    }
    
    
    /// The syntax name which is currently selected in the list table.
    private var selectedSettingName: String {
        
        guard let tableView = self.tableView, tableView.selectedRow >= 0 else {
            return UserDefaults.standard[.syntax]
        }
        return self.settingNames[tableView.selectedRow]
    }
    
    
    /// Returns representedObject if sender is menu item, otherwise selection in the list table.
    ///
    /// - Parameter sender: The sender to test.
    /// - Returns: The setting name.
    private func targetSettingName(for sender: Any?) -> String {
        
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as! String
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
    
    
    /// Tries to delete the given syntax.
    ///
    /// - Parameter name: The name of the syntax to delete.
    private func deleteSetting(name: String) {
        
        let alert = NSAlert()
        alert.messageText = String(localized: "DeletionConfirmationAlert.message",
                                   defaultValue: "Are you sure you want to delete “\(name)”?")
        alert.informativeText = String(localized: "DeletionConfirmationAlert.informativeText",
                                       defaultValue: "This action cannot be undone.")
        alert.addButton(withTitle: String(localized: "Cancel"))
        alert.addButton(withTitle: String(localized: "DeletionConfirmationAlert.button.delete",
                                          defaultValue: "Delete", comment: "button label"))
        alert.buttons.last?.hasDestructiveAction = true
        
        let window = self.view.window!
        Task {
            guard await alert.beginSheetModal(for: window) == .alertSecondButtonReturn else { return }
            
            do {
                try SyntaxManager.shared.removeSetting(name: name)
                
            } catch {
                alert.window.orderOut(nil)
                NSSound.beep()
                await NSAlert(error: error).beginSheetModal(for: window)
                return
            }
            
            AudioServicesPlaySystemSound(.moveToTrash)
        }
    }
    
    
    /// Tries to restore the given syntax.
    ///
    /// - Parameter name: The name of the syntax to restore.
    private func restoreSetting(name: String) {
        
        do {
            try SyntaxManager.shared.restoreSetting(name: name)
        } catch {
            self.presentError(error)
        }
    }
    
    
    /// Tries to import the syntax files at the given URL.
    ///
    /// - Parameter fileURL: The file name of the syntax.
    private func importSetting(fileURL: URL) {
        
        do {
            try SyntaxManager.shared.importSetting(fileURL: fileURL)
        } catch {
            // ask for overwriting if a setting with the same name already exists
            self.presentError(error)
        }
    }
    
    
    /// Presents the syntax edit sheet.
    ///
    /// - Parameter state: The setting state to edit, or `nil` for a new setting.
    private func presentSyntaxEditor(state: SettingState? = nil) {
        
        let syntax = state.flatMap { SyntaxManager.shared.setting(name: $0.name) }
        let isBundled = state?.isBundled ?? false
        
        let view = SyntaxEditView(syntax: syntax, originalName: state?.name, isBundled: isBundled) { (syntax, name) in
            try SyntaxManager.shared.save(setting: syntax, name: name, oldName: state?.name)
        }
        
        let viewController = NSHostingController(rootView: view)
        viewController.rootView.parent = viewController
        viewController.view.frame.size = viewController.view.intrinsicContentSize
        
        self.presentAsSheet(viewController)
    }
    
    
    /// Updates the syntax table and selects the desired item.
    ///
    /// - Parameter selectingName: The item name to select.
    private func updateList(bySelecting selectingName: String) {
        
        self.settingNames = SyntaxManager.shared.settingNames
        
        guard
            let tableView = self.tableView,
            let row = self.settingNames.firstIndex(of: selectingName)
        else { return assertionFailure() }
        
        tableView.reloadData()
        tableView.selectRowIndexes([row], byExtendingSelection: false)
        tableView.scrollRowToVisible(row)
    }
}
