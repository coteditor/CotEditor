//
//  FormatPaneController.swift
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

final class FormatPaneController: NSViewController, NSMenuItemValidation, NSTableViewDelegate, NSTableViewDataSource, NSFilePromiseProviderDelegate, EncodingChanging {
    
    // MARK: Private Properties
    
    private var syntaxNames: [String] = []
    @objc private dynamic var isBundled = false  // bound to remove button
    
    private var encodingChangeObserver: AnyCancellable?
    private var syntaxChangeObserver: AnyCancellable?
    private lazy var filePromiseQueue = OperationQueue()
    
    @IBOutlet private weak var encodingPopUpButton: NSPopUpButton?
    
    @IBOutlet private var syntaxTableMenu: NSMenu?
    @IBOutlet private weak var syntaxTableView: NSTableView?
    @IBOutlet private weak var syntaxTableActionButton: NSButton?
    @IBOutlet private weak var syntaxDefaultPopUpButton: NSPopUpButton?
    
    
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.syntaxTableView?.doubleAction = #selector(editSyntax)
        self.syntaxTableView?.target = self
        
        // register drag & drop types
        let receiverTypes = NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) }
        self.syntaxTableView?.registerForDraggedTypes([.fileURL] + receiverTypes)
        self.syntaxTableView?.setDraggingSourceOperationMask(.copy, forLocal: false)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.encodingChangeObserver = EncodingManager.shared.$encodings
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.setupEncodingMenu() }
        
        self.syntaxChangeObserver = Publishers.Merge(SyntaxManager.shared.$settingNames.eraseToVoid(),
                                                     SyntaxManager.shared.didUpdateSetting.eraseToVoid())
            .debounce(for: 0, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.setupSyntaxMenus() }
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        // stop observations for UI update
        self.encodingChangeObserver = nil
        self.syntaxChangeObserver = nil
    }
    
    
    
    // MARK: Menu Item Validation
    
    /// Applies the current state to menu items.
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextualMenu = (menuItem.menu == self.syntaxTableMenu)
        let representedSettingName = self.representedSettingName(for: menuItem.menu)
        
        // set syntax name as representedObject to menu items whose action is related to syntax
        if NSStringFromSelector(menuItem.action!).contains("Syntax") {
            menuItem.representedObject = representedSettingName
        }
        
        let itemSelected = (representedSettingName != nil)
        let state = representedSettingName.flatMap(SyntaxManager.shared.state(of:))
        
        // append target setting name to menu titles
        switch menuItem.action {
            case #selector(openSyntaxMappingConflictSheet(_:)):
                return !SyntaxManager.shared.mappingConflicts.isEmpty
                
            case #selector(duplicateSyntax(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Duplicate “\(name)”")
                }
                menuItem.isHidden = !itemSelected
                
            case #selector(deleteSyntax(_:)):
                menuItem.isHidden = (state?.isBundled == true || !itemSelected)
                
            case #selector(restoreSyntax(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Restore “\(name)”")
                }
                menuItem.isHidden = (state?.isBundled == false || !itemSelected)
                return state?.isRestorable ?? false
                
            case #selector(exportSyntax(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Export “\(name)”…")
                }
                menuItem.isHidden = !itemSelected
                return state?.isCustomized ?? false
                
            case #selector(shareStyle(_:)):
                menuItem.isHidden = state?.isCustomized != true
                return state?.isCustomized == true
                
            case #selector(revealSyntaxInFinder(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Reveal “\(name)” in Finder")
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
        
        self.syntaxNames.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        guard
            let name = self.syntaxNames[safe: row],
            let state = SyntaxManager.shared.state(of: name)
        else { return nil }
        
        return ["name": name,
                "state": state.isCustomized] as [String: Any]
    }
    
    
    
    /// Invoked when the selected syntax in the "Installed syntaxes" list table did change.
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard notification.object as? NSTableView == self.syntaxTableView else { return }
        
        self.isBundled = SyntaxManager.shared.state(of: self.selectedSyntaxName)?.isBundled == true
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
                    self?.importSyntax(fileURL: fileURL)
                }
            }
            
        } else if let fileURLs = info.fileURLs(with: .yaml, for: tableView) {
            for fileURL in fileURLs {
                self.importSyntax(fileURL: fileURL)
            }
            
        } else {
            return false
        }
        
        AudioServicesPlaySystemSound(.volumeMount)
        
        return true
    }
    
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        
        guard let settingName = self.syntaxNames[safe: row] else { return nil }
        
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
    
    /// Saves the default text encoding.
    @IBAction func changeEncoding(_ sender: NSMenuItem) {
        
        EncodingManager.shared.defaultEncoding = FileEncoding(tag: sender.tag)
    }
    
    
    /// Shows the encoding list sheet.
    @IBAction func showEncodingList(_ sender: Any?) {
        
        let view = EncodingListView()
        let viewController = NSHostingController(rootView: view)
        viewController.rootView.parent = viewController
        
        self.presentAsSheet(viewController)
    }
    
    
    /// Shows the syntax mapping conflict error sheet.
    @IBAction func openSyntaxMappingConflictSheet(_ sender: Any?) {
        
        let view = SyntaxMappingConflictsView(dictionary: SyntaxManager.shared.mappingConflicts)
        let viewController = NSHostingController(rootView: view)
        viewController.rootView.parent = viewController
        
        self.presentAsSheet(viewController)
    }
    
    
    /// Shows the syntax edit sheet.
    @IBAction func editSyntax(_ sender: Any?) {
        
        let syntaxName = self.targetSyntaxName(for: sender)
        let state = SyntaxManager.shared.state(of: syntaxName)!
        
        self.presentSyntaxEditor(state: state)
    }
    
    
    /// Duplicates the selected syntax.
    @IBAction func duplicateSyntax(_ sender: Any?) {
        
        let baseName = self.targetSyntaxName(for: sender)
        let settingName: String
        do {
            settingName = try SyntaxManager.shared.duplicateSetting(name: baseName)
        } catch {
            self.presentError(error)
            return
        }
        
        self.updateSyntaxList(bySelecting: settingName)
    }
    
    
    /// Shows the syntax edit sheet in new mode.
    @IBAction func createSyntax(_ sender: Any?) {
        
        self.presentSyntaxEditor()
    }
    
    /// Deletes the selected syntax.
    @IBAction func deleteSyntax(_ sender: Any?) {
        
        let syntaxName = self.targetSyntaxName(for: sender)
        
        self.deleteSyntax(name: syntaxName)
    }
    
    
    /// Restores the selected syntax to original bundled one.
    @IBAction func restoreSyntax(_ sender: Any?) {
        
        let syntaxName = self.targetSyntaxName(for: sender)
        
        self.restoreSyntax(name: syntaxName)
    }
    
    
    /// Exports the selected syntax.
    @IBAction func exportSyntax(_ sender: Any?) {
        
        let settingName = self.targetSyntaxName(for: sender)
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldLabel = String(localized: "Export As:")
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
    @IBAction func importSyntax(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = String(localized: "Import")
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = [SyntaxManager.shared.fileType]
        
        Task {
            guard await openPanel.beginSheetModal(for: self.view.window!) == .OK else { return }
            
            for url in openPanel.urls {
                self.importSyntax(fileURL: url)
            }
        }
    }
    
    
    /// Shares the selected syntax.
    @IBAction func shareStyle(_ sender: NSMenuItem) {
        
        let styleName = self.targetSyntaxName(for: sender)
        
        guard let url = SyntaxManager.shared.urlForUserSetting(name: styleName) else { return }
        
        let picker = NSSharingServicePicker(items: [url])
        
        if let view = self.syntaxTableView?.clickedRowView {  // context menu
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minX)
            
        } else if let view = self.syntaxTableActionButton {  // action menu
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
    
    
    /// Opens the syntax directory in the Application Support directory in the Finder where the selected syntax exists.
    @IBAction func revealSyntaxInFinder(_ sender: Any?) {
        
        let syntaxName = self.targetSyntaxName(for: sender)
        
        guard let url = SyntaxManager.shared.urlForUserSetting(name: syntaxName) else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    
    /// Reloads all the syntaxes in the user domain.
    @IBAction func reloadAllSyntaxes(_ sender: Any?) {
        
        Task.detached(priority: .utility) {
            SyntaxManager.shared.loadUserSettings()
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Builds the encoding menu.
    private func setupEncodingMenu() {
        
        guard
            let popUpButton = self.encodingPopUpButton,
            let menu = popUpButton.menu
        else { return assertionFailure() }
        
        EncodingManager.shared.updateChangeEncodingMenu(menu)
        popUpButton.selectItem(withTag: EncodingManager.shared.defaultEncoding.tag)
    }
    
    
    /// Builds the syntax menus.
    private func setupSyntaxMenus() {
        
        let syntaxNames = SyntaxManager.shared.settingNames
        
        // update installed syntax list table
        let selectedSyntaxName = self.selectedSyntaxName
        self.syntaxNames = syntaxNames
        self.syntaxTableView?.reloadData()
        if let index = syntaxNames.firstIndex(of: selectedSyntaxName) {
            self.syntaxTableView?.selectRowIndexes([index], byExtendingSelection: false)
        }
        
        // update default syntax popup menu
        if let popUpButton = self.syntaxDefaultPopUpButton {
            popUpButton.removeAllItems()
            popUpButton.addItem(withTitle: BundledSyntaxName.none)
            popUpButton.menu?.addItem(.separator())
            popUpButton.addItems(withTitles: syntaxNames)
            
            // select menu item for the current setting manually although Cocoa-Bindings are used on this menu
            // -> Because items were actually added after Cocoa-Binding selected the item.
            let defaultSyntax = UserDefaults.standard[.syntax]
            let selectedSyntax = syntaxNames.contains(defaultSyntax) ? defaultSyntax : BundledSyntaxName.none
            
            popUpButton.selectItem(withTitle: selectedSyntax)
        }
    }
    
    
    /// The syntax name which is currently selected in the list table.
    private var selectedSyntaxName: String {
        
        guard let tableView = self.syntaxTableView, tableView.selectedRow >= 0 else {
            return UserDefaults.standard[.syntax]
        }
        return self.syntaxNames[tableView.selectedRow]
    }
    
    
    /// Returns representedObject if sender is menu item, otherwise selection in the list table.
    ///
    /// - Parameter sender: The sender to test.
    /// - Returns: The setting name.
    private func targetSyntaxName(for sender: Any?) -> String {
        
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as! String
        }
        return self.selectedSyntaxName
    }
    
    
    private func representedSettingName(for menu: NSMenu?) -> String? {
        
        guard self.syntaxTableView?.menu == menu else {
            return self.selectedSyntaxName
        }
        
        guard let clickedRow = self.syntaxTableView?.clickedRow, clickedRow != -1 else { return nil }  // clicked blank area
        
        return self.syntaxNames[safe: clickedRow]
    }
    
    
    /// Tries to delete the given syntax.
    ///
    /// - Parameter name: The name of the syntax to delete.
    private func deleteSyntax(name: String) {
        
        let alert = NSAlert()
        alert.messageText = String(localized: "Are you sure you want to delete “\(name)”?")
        alert.informativeText = String(localized: "This action cannot be undone.")
        alert.addButton(withTitle: String(localized: "Cancel"))
        alert.addButton(withTitle: String(localized: "Delete"))
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
    private func restoreSyntax(name: String) {
        
        do {
            try SyntaxManager.shared.restoreSetting(name: name)
        } catch {
            self.presentError(error)
        }
    }
    
    
    /// Tries to import the syntax files at the given URL.
    ///
    /// - Parameter fileURL: The file name of the syntax.
    private func importSyntax(fileURL: URL) {
        
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
        
        let manager = SyntaxManager.shared
        let syntax: SyntaxManager.SyntaxDictionary = if let state {
            manager.settingDictionary(name: state.name) ?? manager.blankSettingDictionary
        } else {
            manager.blankSettingDictionary
        }
        
        let viewController = NSStoryboard(name: "SyntaxEditView", bundle: nil).instantiateInitialController { coder in
            SyntaxEditViewController(coder: coder, syntax: syntax, state: state) { (dictionary, name) in
                try SyntaxManager.shared.save(settingDictionary: dictionary, name: name, oldName: state?.name)
            }
        }!
        
        self.presentAsSheet(viewController)
    }
    
    
    /// Updates the syntax table and selects the desired item.
    ///
    /// - Parameter selectingName: The item name to select.
    private func updateSyntaxList(bySelecting selectingName: String) {
        
        self.syntaxNames = SyntaxManager.shared.settingNames
        
        guard
            let tableView = self.syntaxTableView,
            let row = self.syntaxNames.firstIndex(of: selectingName)
        else { return assertionFailure() }
        
        tableView.reloadData()
        tableView.selectRowIndexes([row], byExtendingSelection: false)
        tableView.scrollRowToVisible(row)
    }
}
