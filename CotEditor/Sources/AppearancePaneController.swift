//
//  AppearancePaneController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2023 1024jp
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

final class AppearancePaneController: NSViewController, NSMenuItemValidation, NSTableViewDelegate, NSTableViewDataSource, NSFilePromiseProviderDelegate, NSTextFieldDelegate {
    
    // MARK: Private Properties
    
    private var fontPanelTarget: FontType = .standard
    private var themeNames: [String] = []
    @objc private dynamic var isBundled = false  // bound to remove button
    
    private var fontObservers: Set<AnyCancellable> = []
    private var themeManagerObservers: Set<AnyCancellable> = []
    private lazy var filePromiseQueue = OperationQueue()
    
    @IBOutlet private weak var fontField: AntialiasingTextField?
    @IBOutlet private weak var monospacedFontField: AntialiasingTextField?
    @IBOutlet private weak var lineHeightField: NSTextField?
    @IBOutlet private weak var editorOpacityField: NSTextField?
    
    @IBOutlet private weak var defaultAppearanceButton: NSButton?
    @IBOutlet private weak var lightAppearanceButton: NSButton?
    @IBOutlet private weak var darkAppearanceButton: NSButton?
    
    @IBOutlet private weak var themeTableView: NSTableView?
    @IBOutlet private var themeTableActionButton: NSButton?
    @IBOutlet private var themeTableMenu: NSMenu?
    @IBOutlet private var themeViewContainer: NSBox?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // register drag & drop types
        let receiverTypes = NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) }
        self.themeTableView?.registerForDraggedTypes([.fileURL] + receiverTypes)
        self.themeTableView?.setDraggingSourceOperationMask(.copy, forLocal: false)
        
        // set initial value as field's placeholder
        self.lineHeightField?.bindNullPlaceholderToUserDefaults()
        self.editorOpacityField?.bindNullPlaceholderToUserDefaults()
        
        self.themeNames = ThemeManager.shared.settingNames
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // setup font fields
        self.fontObservers = [
            UserDefaults.standard.publisher(for: .font, initial: true)
                .sink { [weak self] _ in self?.fontField?.displayFontName(for: UserDefaults.standard.font(for: .standard)) },
            UserDefaults.standard.publisher(for: .shouldAntialias, initial: true)
                .sink { [weak self] in self?.fontField?.disablesAntialiasing = !$0 },
            UserDefaults.standard.publisher(for: .monospacedFont, initial: true)
                .sink { [weak self] _ in self?.monospacedFontField?.displayFontName(for: UserDefaults.standard.font(for: .monospaced)) },
            UserDefaults.standard.publisher(for: .monospacedShouldAntialias, initial: true)
                .sink { [weak self] in self?.monospacedFontField?.disablesAntialiasing = !$0 },
        ]
        
        // select one of appearance radio buttons
        switch UserDefaults.standard[.documentAppearance] {
            case .default:
                self.defaultAppearanceButton?.state = .on
            case .light:
                self.lightAppearanceButton?.state = .on
            case .dark:
                self.darkAppearanceButton?.state = .on
        }
        
        // sync theme list change
        self.themeManagerObservers = [
            ThemeManager.shared.$settingNames
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.updateThemeList() },
            ThemeManager.shared.didUpdateSetting
                .compactMap(\.new)
                .receive(on: RunLoop.main)
                .sink { [weak self] name in
                    guard
                        name == self?.selectedThemeName,
                        let latestTheme = ThemeManager.shared.setting(name: name)
                    else { return }
                    
                    self?.setTheme(latestTheme, name: name)
                },
        ]
        self.themeTableView?.scrollToBeginningOfDocument(nil)
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        // stop observations for UI update
        self.fontObservers.removeAll()
        self.themeManagerObservers.removeAll()
        
        // detach a possible font panel's target set in `showFonts(_:)`
        if NSFontManager.shared.target === self {
            NSFontManager.shared.target = nil
            NSFontPanel.shared.close()
        }
    }
    
    
    
    // MARK: User Interface Validation
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextualMenu = (menuItem.menu == self.themeTableMenu)
        
        let representedSettingName = self.representedSettingName(for: menuItem.menu)
        menuItem.representedObject = representedSettingName
        
        let itemSelected = (representedSettingName != nil)
        let state = representedSettingName.flatMap(ThemeManager.shared.state(of:))
        
        // append target setting name to menu titles
        switch menuItem.action {
            case #selector(addTheme), #selector(importTheme(_:)):
                menuItem.isHidden = (isContextualMenu && itemSelected)
                
            case #selector(renameTheme(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Rename “\(name)”")
                }
                menuItem.isHidden = !itemSelected
                return state?.isBundled == false
                
            case #selector(duplicateTheme(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Duplicate “\(name)”")
                }
                menuItem.isHidden = !itemSelected
                
            case #selector(deleteTheme(_:)):
                menuItem.isHidden = (state?.isBundled == true || !itemSelected)
                
            case #selector(restoreTheme(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Restore “\(name)”")
                }
                menuItem.isHidden = (state?.isBundled == false || !itemSelected)
                return state?.isRestorable == true
                
            case #selector(exportTheme(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Export “\(name)”…")
                }
                menuItem.isHidden = !itemSelected
                return state?.isCustomized == true
                
            case #selector(shareTheme(_:)):
                menuItem.isHidden = true
                return state?.isCustomized == true
                
            case #selector(revealThemeInFinder(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(localized: "Reveal “\(name)” in Finder")
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
        
        self.themeNames.count
    }
    
    
    /// The content of the table cell.
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        self.themeNames[safe: row]
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
            let dropDirectoryURL = ThemeManager.shared.itemReplacementDirectoryURL
            
            for receiver in receivers {
                receiver.receivePromisedFiles(atDestination: dropDirectoryURL, operationQueue: .main) { [weak self] (fileURL, error) in
                    if let error {
                        self?.presentError(error)
                        return
                    }
                    self?.importTheme(fileURL: fileURL)
                }
            }
            
        } else if let fileURLs = info.fileURLs(with: .cotTheme, for: tableView) {
            for fileURL in fileURLs {
                self.importTheme(fileURL: fileURL)
            }
            
        } else {
            return false
        }
        
        AudioServicesPlaySystemSound(.volumeMount)
        
        return true
    }
    
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        
        let provider = NSFilePromiseProvider(fileType: UTType.cotTheme.identifier, delegate: self)
        provider.userInfo = self.themeNames[row]
        
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
    
    // NSTableViewDelegate  < themeTableView
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard notification.object as? NSTableView == self.themeTableView else { return }
        
        self.setTheme(name: self.selectedThemeName)
    }
    
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        guard let view = rowView.view(atColumn: 0) as? NSTableCellView else { return }
        
        let themeName = self.themeNames[row]
        let isBundled = ThemeManager.shared.state(of: themeName)?.isBundled == true
        
        view.textField?.isSelectable = false
        view.textField?.isEditable = !isBundled
    }
    
    
    // NSTextFieldDelegate
    
    /// A theme name was edited.
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        let newName = fieldEditor.string
        
        // finish if empty (The original name will be restored automatically)
        guard !newName.isEmpty else { return true }
        
        let oldName = self.selectedThemeName
        
        do {
            try ThemeManager.shared.renameSetting(name: oldName, to: newName)
            
        } catch {
            // revert name
            fieldEditor.string = oldName
            
            // show alert
            NSAlert(error: error).beginSheetModal(for: self.view.window!)
            return false
        }
        
        if UserDefaults.standard[.theme] == oldName {
            UserDefaults.standard[.theme] = newName
        }
        
        return true
    }
    
    
    
    // MARK: Action Messages
    
    /// A radio button for `documentAppearance` was clicked.
    @IBAction func updateAppearanceSetting(_ sender: NSButton) {
        
        UserDefaults.standard[.documentAppearance] = AppearanceMode(rawValue: sender.tag)!
        
        let themeName = ThemeManager.shared.userDefaultSettingName
        let row = self.themeNames.firstIndex(of: themeName) ?? 0
        
        self.themeTableView?.selectRowIndexes([row], byExtendingSelection: false)
    }
    
    
    /// Adds a new theme.
    @IBAction func addTheme(_ sender: Any?) {
        
        let settingName: String
        do {
            settingName = try ThemeManager.shared.createUntitledSetting()
        } catch {
            self.presentError(error)
            return
        }
        
        self.updateThemeList(bySelecting: settingName)
    }
    
    
    /// Duplicates the selected theme.
    @IBAction func duplicateTheme(_ sender: Any?) {
        
        let baseName = self.targetThemeName(for: sender)
        let settingName: String
        do {
            settingName = try ThemeManager.shared.duplicateSetting(name: baseName)
        } catch {
            self.presentError(error)
            return
        }
        
        self.updateThemeList(bySelecting: settingName)
    }
    
    
    /// Starts renaming a theme.
    @IBAction func renameTheme(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        let row = self.themeNames.firstIndex(of: themeName) ?? 0
        
        self.themeTableView?.editColumn(0, row: row, with: nil, select: false)
    }
    
    
    /// Deletes the selected theme.
    @IBAction func deleteTheme(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        self.deleteTheme(name: themeName)
    }
    
    
    /// Restores the selected theme to original bundled one.
    @IBAction func restoreTheme(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        self.restoreTheme(name: themeName)
    }
    
    
    /// Exports the selected theme.
    @IBAction func exportTheme(_ sender: Any?) {
        
        let settingName = self.targetThemeName(for: sender)
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.isExtensionHidden = true
        savePanel.nameFieldLabel = String(localized: "Export As:")
        savePanel.nameFieldStringValue = settingName
        savePanel.allowedContentTypes = [ThemeManager.shared.fileType]
        
        Task {
            guard await savePanel.beginSheetModal(for: self.view.window!) == .OK else { return }
            
            do {
                try ThemeManager.shared.exportSetting(name: settingName, to: savePanel.url!, hidesExtension: savePanel.isExtensionHidden)
            } catch {
                self.presentError(error)
            }
        }
    }
    
    
    /// Imports theme files via the open panel.
    @IBAction func importTheme(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = String(localized: "Import")
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = [ThemeManager.shared.fileType]
        
        Task {
            guard await openPanel.beginSheetModal(for: self.view.window!) == .OK else { return }
            
            for url in openPanel.urls {
                self.importTheme(fileURL: url)
            }
        }
    }
    
    
    /// Shares the selected themes.
    @IBAction func shareTheme(_ sender: NSMenuItem) {
        
        let themeName = self.targetThemeName(for: sender)
        
        guard let url = ThemeManager.shared.urlForUserSetting(name: themeName) else { return }
        
        let picker = NSSharingServicePicker(items: [url])
        
        if let view = self.themeTableView?.clickedRowView {  // context menu
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minX)
            
        } else if let view = self.themeTableActionButton {  // action menu
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
    
    
    /// Opens the theme directory in the Application Support directory in the Finder where the selected theme exists.
    @IBAction func revealThemeInFinder(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        guard let url = ThemeManager.shared.urlForUserSetting(name: themeName) else { return }
        
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
    private var selectedThemeName: String {
        
        guard let tableView = self.themeTableView, tableView.selectedRow >= 0 else {
            return ThemeManager.shared.userDefaultSettingName
        }
        return self.themeNames[tableView.selectedRow]
    }
    
    
    /// Returns representedObject if sender is menu item, otherwise selection in the list table.
    ///
    /// - Parameter sender: The sender to test.
    /// - Returns: The setting name.
    private func targetThemeName(for sender: Any?) -> String {
        
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as! String
        }
        return self.selectedThemeName
    }
    
    
    private func representedSettingName(for menu: NSMenu?) -> String? {
        
        guard self.themeTableView?.menu == menu else {
            return self.selectedThemeName
        }
        
        guard let clickedRow = self.themeTableView?.clickedRow, clickedRow != -1 else { return nil }  // clicked blank area
        
        return self.themeNames[safe: clickedRow]
    }
    
    
    /// Sets the given theme to the editor.
    ///
    /// - Parameter name: The theme name.
    private func setTheme(name: String) {
        
        guard
            let theme = ThemeManager.shared.setting(name: name)
        else { return assertionFailure() }
        
        // update default theme setting
        let isDarkTheme = ThemeManager.shared.isDark(name: name)
        let usesDarkAppearance = ThemeManager.shared.usesDarkAppearance
        UserDefaults.standard[.pinsThemeAppearance] = (isDarkTheme != usesDarkAppearance)
        UserDefaults.standard[.theme] = name
        
        self.setTheme(theme, name: name)
    }
    
    
    /// Sets the given theme to theme view.
    ///
    /// - Parameters:
    ///   - theme: The theme to set to the view.
    ///   - name: The name of the theme.
    private func setTheme(_ theme: Theme, name: String) {
        
        let isBundled = ThemeManager.shared.state(of: name)?.isBundled == true
        
        let view = ThemeEditorView(theme, isBundled: isBundled) { theme in
            do {
                try ThemeManager.shared.save(setting: theme, name: name)
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
        
        self.themeViewContainer?.contentView = NSHostingView(rootView: view)
        self.isBundled = isBundled
    }
    
    
    /// Tries to delete the given theme.
    ///
    /// - Parameter name: The name of the theme to delete.
    private func deleteTheme(name: String) {
        
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
                try ThemeManager.shared.removeSetting(name: name)
                
            } catch {
                alert.window.orderOut(nil)
                NSSound.beep()
                await NSAlert(error: error).beginSheetModal(for: window)
                return
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
            self.presentError(error)
        }
    }
    
    
    /// Tries to import the theme files at the given URL.
    ///
    /// - Parameter fileURL: The file name of the theme.
    private func importTheme(fileURL: URL) {
        
        do {
            try ThemeManager.shared.importSetting(fileURL: fileURL)
        } catch {
            // ask for overwriting if a setting with the same name already exists
            self.presentError(error)
        }
    }
    
    
    /// Updates the theme table and selects the desired item.
    ///
    /// - Parameter selectingName: The item name to select.
    private func updateThemeList(bySelecting selectingName: String? = nil) {
        
        let themeName = selectingName ?? ThemeManager.shared.userDefaultSettingName
        
        self.themeNames = ThemeManager.shared.settingNames
        
        guard let tableView = self.themeTableView else { return }
        
        tableView.reloadData()
        
        let row = self.themeNames.firstIndex(of: themeName) ?? 0
        
        tableView.selectRowIndexes([row], byExtendingSelection: false)
        if selectingName != nil {
            tableView.scrollRowToVisible(row)
        }
    }
    
    
    /// Updates the selection of the theme table.
    private func updateThemeSelection() {
        
        let themeName = ThemeManager.shared.userDefaultSettingName
        let row = self.themeNames.firstIndex(of: themeName) ?? 0
        
        self.themeTableView?.selectRowIndexes([row], byExtendingSelection: false)
    }
}



// MARK: - Font Setting

extension NSUserInterfaceItemIdentifier {
    
    static let monospacedFontButton = Self("monospacedFontButton")
}


extension AppearancePaneController: NSFontChanging {
    
    // MARK: Font Changing Methods
    
    /// Restricts items to display in the font panel.
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        
        [.collection, .face, .size]
    }
    
    
    /// Returns the font selection in the font panel did update.
    func changeFont(_ sender: NSFontManager?) {
        
        guard let sender else { return assertionFailure() }
        
        let font = sender.convert(.systemFont(ofSize: 0))
        let target = self.fontPanelTarget
        
        if target == .monospaced, !font.isFixedPitch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = String(localized: "The selected font doesn’t seem to be monospaced.")
            alert.informativeText = String(localized: "Do you want to use it for the monospaced font?", comment: "“it” is the selected font.")
            alert.addButton(withTitle: String(localized: "OK"))
            alert.addButton(withTitle: String(localized: "Cancel"))
            
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        
        guard let data = try? font.archivedData else { return }
        
        UserDefaults.standard[.fontKey(for: target)] = data
    }
    
    
    
    // MARK: Action Messages
    
    /// Shows the font panel.
    @IBAction func showFonts(_ sender: NSButton) {
        
        self.fontPanelTarget = (sender.identifier == .monospacedFontButton) ? .monospaced : .standard
        let font = UserDefaults.standard.font(for: self.fontPanelTarget)
        
        NSFontManager.shared.setSelectedFont(font, isMultiple: false)
        NSFontManager.shared.orderFrontFontPanel(sender)
        NSFontManager.shared.target = self
    }
}



private extension NSTextField {
    
    /// Displays the font name and size in the manner of the given font setting.
    ///
    /// - Parameters:
    ///   - font: The font to display.
    func displayFontName(for font: NSFont) {
        
        let displayName = font.displayName ?? font.fontName
        let size = font.pointSize
        let maxDisplaySize = NSFont.systemFontSize(for: self.controlSize)
        
        self.stringValue = displayName + " " + size.formatted()
        self.toolTip = self.stringValue
        self.font = font.withSize(min(size, maxDisplaySize))
    }
}
