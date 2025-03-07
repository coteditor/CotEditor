//
//  ThemeListViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2025 1024jp
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
import URLUtils

final class ThemeListViewController: NSViewController, NSMenuItemValidation, NSTableViewDelegate, NSTableViewDataSource, NSFilePromiseProviderDelegate, NSTextFieldDelegate {
    
    // MARK: Private Properties
    
    @Binding private var selection: String
    
    private var settingNames: [String] = []
    @objc private dynamic var isBundled = false  // bound to remove button
    
    private var observer: AnyCancellable?
    private lazy var filePromiseQueue = OperationQueue()
    
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private var actionButton: NSButton?
    @IBOutlet private var contextMenu: NSMenu?
    
    
    // MARK: View Controller Methods
    
    init?(coder: NSCoder, selection: Binding<String>) {
        
        self._selection = selection
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // register drag & drop types
        let receiverTypes = NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) }
        self.tableView?.registerForDraggedTypes([.fileURL] + receiverTypes)
        self.tableView?.setDraggingSourceOperationMask(.copy, forLocal: false)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.observer = ThemeManager.shared.$settingNames
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateList() }
        
        self.tableView?.scrollToBeginningOfDocument(nil)
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.observer = nil
    }
    
    
    // MARK: Public Methods
    
    /// Selects the specified setting.
    ///
    /// - Parameter settingName: The name of the setting to select.
    func select(settingName: String) {
        
        let row = self.settingNames.firstIndex(of: settingName) ?? 0
        self.tableView?.selectRowIndexes([row], byExtendingSelection: false)
    }
    
    
    // MARK: User Interface Validation
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextMenu = (menuItem.menu == self.contextMenu)
        
        let settingName = self.representedSettingName(for: menuItem.menu)
        menuItem.representedObject = settingName
        
        let itemSelected = (settingName != nil)
        let state = settingName.flatMap(ThemeManager.shared.state(of:))
        
        // append target setting name to menu titles
        switch menuItem.action {
            case #selector(addTheme), #selector(importTheme(_:)):
                menuItem.isHidden = (isContextMenu && itemSelected)
                
            case #selector(renameTheme(_:)):
                if let settingName, !isContextMenu {
                    menuItem.title = String(localized: "Rename “\(settingName)”", comment: "menu item label")
                }
                menuItem.isHidden = !itemSelected
                return state?.isBundled == false
                
            case #selector(duplicateTheme(_:)):
                if let settingName, !isContextMenu {
                    menuItem.title = String(localized: "Duplicate “\(settingName)”", comment: "menu item label")
                }
                menuItem.isHidden = !itemSelected
                
            case #selector(deleteTheme(_:)):
                menuItem.isHidden = (state?.isBundled == true || !itemSelected)
                
            case #selector(restoreTheme(_:)):
                if let settingName, !isContextMenu {
                    menuItem.title = String(localized: "Restore “\(settingName)”", comment: "menu item label")
                }
                menuItem.isHidden = (state?.isBundled == false || !itemSelected)
                return state?.isRestorable == true
                
            case #selector(exportTheme(_:)):
                if let settingName, !isContextMenu {
                    menuItem.title = String(localized: "Export “\(settingName)”…", comment: "menu item label")
                }
                menuItem.isHidden = !itemSelected
                return state?.isCustomized == true
                
            case #selector(shareTheme(_:)):
                menuItem.isHidden = state?.isCustomized != true
                return state?.isCustomized == true
                
            case #selector(revealThemeInFinder(_:)):
                if let settingName, !isContextMenu {
                    menuItem.title = String(localized: "Reveal “\(settingName)” in Finder", comment: "menu item label")
                }
                return state?.isCustomized == true
                
            case nil:
                return false
                
            default:
                break
        }
        
        return true
    }
    
    
    // MARK: Data Source
    
    /// The number of themes.
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        self.settingNames.count
    }
    
    
    /// The contents of the table cell.
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        self.settingNames[safe: row]
    }
    
    
    /// Validates when dragged items come to tableView.
    func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        guard
            info.draggingSource as? NSTableView != tableView,  // avoid self D&D
            let count = info.filePromiseReceivers(with: .cotTheme, for: tableView)?.count
                       ?? info.fileURLs(with: .cotTheme, for: tableView)?.count
        else { return [] }
        
        // highlight table view itself
        tableView.setDropRow(-1, dropOperation: .on)
        
        // show number of acceptable files
        info.numberOfValidItemsForDrop = count
        
        return .copy
    }
    
    
    /// Check the acceptability of dropped items and inserts them to table.
    func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        if let receivers = info.filePromiseReceivers(with: .cotTheme, for: tableView) {
            let dropDirectoryURL = (try? URL.itemReplacementDirectory) ?? .temporaryDirectory
            
            for receiver in receivers {
                receiver.receivePromisedFiles(atDestination: dropDirectoryURL, operationQueue: .main) { [weak self] (fileURL, error) in
                    if let error {
                        self?.presentErrorAsSheet(error)
                        return
                    }
                    self?.importTheme(at: fileURL)
                }
            }
            
        } else if let fileURLs = info.fileURLs(with: .cotTheme, for: tableView) {
            for fileURL in fileURLs {
                self.importTheme(at: fileURL)
            }
            
        } else {
            return false
        }
        
        AudioServicesPlaySystemSound(.volumeMount)
        
        return true
    }
    
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        
        let provider = NSFilePromiseProvider(fileType: UTType.cotTheme.identifier, delegate: self)
        provider.userInfo = self.settingNames[row]
        
        return provider
    }
    
    
    // MARK: File Promise Provider Delegate
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        
        (filePromiseProvider.userInfo as! String) + "." + UTType.cotTheme.preferredFilenameExtension!
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL) async throws {
        
        guard
            let settingName = filePromiseProvider.userInfo as? String,
            let sourceURL = ThemeManager.shared.urlForUserSetting(name: settingName)
        else { return }
        
        try FileManager.default.copyItem(at: sourceURL, to: url)
    }
    
    
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        
        self.filePromiseQueue
    }
    
    
    // MARK: Delegate
    
    // NSTableViewDelegate  < tableView
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        self.selection = self.selectedSettingName
    }
    
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        guard let view = rowView.view(atColumn: 0) as? NSTableCellView else { return }
        
        let settingName = self.settingNames[row]
        let isBundled = ThemeManager.shared.state(of: settingName)?.isBundled == true
        
        view.textField?.isSelectable = false
        view.textField?.isEditable = !isBundled
    }
    
    
    // NSTextFieldDelegate
    
    /// A theme name was edited.
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        let newName = fieldEditor.string
        
        // finish if empty (The original name will be restored automatically)
        guard !newName.isEmpty else { return true }
        
        let oldName = self.selectedSettingName
        
        do {
            try ThemeManager.shared.renameSetting(name: oldName, to: newName)
            
        } catch {
            // revert name
            fieldEditor.string = oldName
            
            // show alert
            self.presentErrorAsSheet(error)
            return false
        }
        
        self.selection = newName
        
        return true
    }
    
    
    // MARK: Action Messages
    
    /// Adds a new theme.
    @IBAction func addTheme(_ sender: Any?) {
        
        let settingName: String
        do {
            settingName = try ThemeManager.shared.createUntitledSetting()
        } catch {
            return self.presentErrorAsSheet(error)
        }
        
        self.updateList(bySelecting: settingName)
    }
    
    
    /// Duplicates the selected theme.
    @IBAction func duplicateTheme(_ sender: Any?) {
        
        let baseName = self.targetSettingName(for: sender)
        let settingName: String
        do {
            settingName = try ThemeManager.shared.duplicateSetting(name: baseName)
        } catch {
            return self.presentErrorAsSheet(error)
        }
        
        self.updateList(bySelecting: settingName)
    }
    
    
    /// Starts renaming a theme.
    @IBAction func renameTheme(_ sender: Any?) {
        
        let settingName = self.targetSettingName(for: sender)
        let row = self.settingNames.firstIndex(of: settingName) ?? 0
        
        self.tableView?.editColumn(0, row: row, with: nil, select: false)
    }
    
    
    /// Deletes the selected theme.
    @IBAction func deleteTheme(_ sender: Any?) {
        
        let settingName = self.targetSettingName(for: sender)
        
        self.deleteTheme(name: settingName)
    }
    
    
    /// Restores the selected theme to original bundled one.
    @IBAction func restoreTheme(_ sender: Any?) {
        
        let settingName = self.targetSettingName(for: sender)
        
        self.restoreTheme(name: settingName)
    }
    
    
    /// Exports the selected theme.
    @IBAction func exportTheme(_ sender: Any?) {
        
        let settingName = self.targetSettingName(for: sender)
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.isExtensionHidden = true
        savePanel.nameFieldLabel = String(localized: "Export As:", comment: "filename field label for save panel")
        savePanel.nameFieldStringValue = settingName
        savePanel.allowedContentTypes = [ThemeManager.fileType]
        
        Task {
            guard await savePanel.beginSheetModal(for: self.view.window!) == .OK else { return }
            
            do {
                try ThemeManager.shared.exportSetting(name: settingName, to: savePanel.url!, hidesExtension: savePanel.isExtensionHidden)
            } catch {
                self.presentErrorAsSheet(error)
            }
        }
    }
    
    
    /// Imports theme files via the open panel.
    @IBAction func importTheme(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = String(localized: "Import", comment: "button label")
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = [ThemeManager.fileType]
        
        Task {
            guard await openPanel.beginSheetModal(for: self.view.window!) == .OK else { return }
            
            for url in openPanel.urls {
                self.importTheme(at: url)
            }
        }
    }
    
    
    /// Shares the selected themes.
    @IBAction func shareTheme(_ sender: NSMenuItem) {
        
        let settingName = self.targetSettingName(for: sender)
        
        guard let url = ThemeManager.shared.urlForUserSetting(name: settingName) else { return }
        
        let picker = NSSharingServicePicker(items: [url])
        
        if let view = self.tableView?.clickedRowView {  // context menu
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minX)
            
        } else if let view = self.actionButton {  // action menu
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
    
    
    /// Opens the theme directory in the Application Support directory in the Finder where the selected theme exists.
    @IBAction func revealThemeInFinder(_ sender: Any?) {
        
        let settingName = self.targetSettingName(for: sender)
        
        guard let url = ThemeManager.shared.urlForUserSetting(name: settingName) else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    
    /// Reloads all the themes in the user domain.
    @IBAction func reloadAllThemes(_ sender: Any?) {
        
        Task.detached(priority: .utility) {
            ThemeManager.shared.loadUserSettings()
        }
    }
    
    
    // MARK: Private Methods
    
    /// Theme name which is currently selected in the list table.
    private var selectedSettingName: String {
        
        guard let tableView = self.tableView, tableView.selectedRow >= 0 else {
            return ThemeManager.shared.userDefaultSettingName
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
    
    
    /// Returns the target setting name represents for the current action.
    ///
    /// - Parameter menu: The parent menu of the sender if a specific sender exists.
    /// - Returns: A setting name, or `nil` if not found.
    private func representedSettingName(for menu: NSMenu?) -> String? {
        
        guard self.tableView?.menu == menu else {
            return self.selectedSettingName
        }
        
        guard let clickedRow = self.tableView?.clickedRow, clickedRow != -1 else { return nil }  // clicked blank area
        
        return self.settingNames[safe: clickedRow]
    }
    
    
    /// Tries to delete the given theme.
    ///
    /// - Parameter name: The name of the theme to delete.
    private func deleteTheme(name: String) {
        
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
                try ThemeManager.shared.removeSetting(name: name)
            } catch {
                NSSound.beep()
                return self.presentErrorAsSheet(error)
            }
            
            AudioServicesPlaySystemSound(.moveToTrash)
        }
    }
    
    
    /// Tries to restore the given theme.
    ///
    /// - Parameter name: The name of the theme to restore.
    private func restoreTheme(name: String) {
        
        do {
            try ThemeManager.shared.restoreSetting(name: name)
        } catch {
            self.presentErrorAsSheet(error)
        }
    }
    
    
    /// Tries to import the theme files at the given URL.
    ///
    /// - Parameters:
    ///   - fileURL: The filename of the theme.
    ///   - byDeletingOriginal: `true` if removing the original file at the `fileURL`; otherwise, it is kept.
    private func importTheme(at fileURL: URL, byDeletingOriginal: Bool = false) {
        
        do {
            try ThemeManager.shared.importSetting(at: fileURL, byDeletingOriginal: byDeletingOriginal)
        } catch {
            // ask for overwriting if a setting with the same name already exists
            self.presentErrorAsSheet(error)
        }
    }
    
    
    /// Updates the theme table and selects the desired item.
    ///
    /// - Parameter selectingName: The item name to select.
    private func updateList(bySelecting selectingName: String? = nil) {
        
        self.settingNames = ThemeManager.shared.settingNames
        
        guard let tableView = self.tableView else { return }
        
        let settingName = selectingName ?? ThemeManager.shared.userDefaultSettingName
        
        tableView.reloadData()
        
        let row = self.settingNames.firstIndex(of: settingName) ?? 0
        
        tableView.selectRowIndexes([row], byExtendingSelection: false)
        if let selectingName {
            self.selection = selectingName
            tableView.scrollRowToVisible(row)
        }
    }
}
