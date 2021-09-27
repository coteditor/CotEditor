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
//  © 2014-2021 1024jp
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

final class AppearancePaneController: NSViewController, NSMenuItemValidation, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, NSMenuDelegate, ThemeViewControllerDelegate {
    
    // MARK: Private Properties
    
    private var themeNames = [String]()
    private var themeViewController: ThemeViewController?
    @objc private dynamic var isBundled = false
    
    private var themeManagerObservers: Set<AnyCancellable> = []
    
    @IBOutlet private weak var fontField: AntialiasingTextField?
    @IBOutlet private weak var lineHeightField: NSTextField?
    
    @IBOutlet private weak var barCursorButton: NSButton?
    @IBOutlet private weak var thickBarCursorButton: NSButton?
    @IBOutlet private weak var blockCursorButton: NSButton?
    
    @IBOutlet private weak var defaultAppearanceButton: NSButton?
    @IBOutlet private weak var lightAppearanceButton: NSButton?
    @IBOutlet private weak var darkAppearanceButton: NSButton?
    
    @IBOutlet private weak var themeTableView: NSTableView?
    @IBOutlet private var themeTableMenu: NSMenu?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // register droppable types
        self.themeTableView?.registerForDraggedTypes([.URL])
        
        // set initial value as field's placeholder
        self.lineHeightField?.bindNullPlaceholderToUserDefaults()
        
        self.themeNames = ThemeManager.shared.settingNames
    }
    
    
    /// apply current settings to UI
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.setupFontFamilyNameAndSize()
        
        // select one of cursor type radio buttons
        switch UserDefaults.standard[.cursorType] {
            case .bar:
                self.barCursorButton?.state = .on
            case .thickBar:
                self.thickBarCursorButton?.state = .on
            case .block:
                self.blockCursorButton?.state = .on
        }
        
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
        self.themeManagerObservers.removeAll()
        ThemeManager.shared.$settingNames
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateThemeList() }
            .store(in: &self.themeManagerObservers)
        ThemeManager.shared.didUpdateSetting
            .sink { [weak self] _ in
                guard
                    let self = self,
                    let latestTheme = ThemeManager.shared.setting(name: self.selectedThemeName),
                    latestTheme.name == self.themeViewController?.theme?.name
                    else { return }
                
                self.themeViewController?.theme = latestTheme
            }
            .store(in: &self.themeManagerObservers)
    }
    
    
    /// stop observations for UI update
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.themeManagerObservers.removeAll()
        
    }
    
    
    /// set delegate to ThemeViewController
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        if let destinationController = segue.destinationController as? ThemeViewController {
            self.themeViewController = destinationController
            destinationController.delegate = self
        }
    }
    
    
    
    // MARK: User Interface Validation
    
    /// apply current state to menu items
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextualMenu = (menuItem.menu == self.themeTableMenu)
        
        let representedSettingName = self.representedSettingName(for: menuItem.menu)
        menuItem.representedObject = representedSettingName
        
        let itemSelected = (representedSettingName != nil)
        let isBundled: Bool
        let isCustomized: Bool
        if let representedSettingName = representedSettingName {
            isBundled = ThemeManager.shared.isBundledSetting(name: representedSettingName)
            isCustomized = ThemeManager.shared.isCustomizedBundledSetting(name: representedSettingName)
        } else {
            (isBundled, isCustomized) = (false, false)
        }
        
        // append target setting name to menu titles
        switch menuItem.action {
            case #selector(addTheme), #selector(importTheme(_:)):
                menuItem.isHidden = (isContextualMenu && itemSelected)
            
            case #selector(renameTheme(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Rename “%@”".localized, name)
                }
                menuItem.isHidden = !itemSelected
                return !isBundled
            
            case #selector(duplicateTheme(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Duplicate “%@”".localized, name)
                }
                menuItem.isHidden = !itemSelected
            
            case #selector(deleteTheme(_:)):
                menuItem.isHidden = (isBundled || !itemSelected)
            
            case #selector(restoreTheme(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Restore “%@”".localized, name)
                }
                menuItem.isHidden = (!isBundled || !itemSelected)
                return isCustomized
            
            case #selector(exportTheme(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Export “%@”…".localized, name)
                }
                menuItem.isHidden = !itemSelected
                return (!isBundled || isCustomized)
            
            case #selector(revealThemeInFinder(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Reveal “%@” in Finder".localized, name)
                }
                return (!isBundled || isCustomized)
            
            case nil:
                return false
            
            default:
                break
        }
        
        return true
    }
    
    
    
    // MARK: Data Source
    
    /// number of themes
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return self.themeNames.count
    }
    
    
    /// content of table cell
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        return self.themeNames[safe: row]
    }
    
    
    /// validate when dragged items come to tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        // get file URLs from pasteboard
        let pboard = info.draggingPasteboard
        let objects = pboard.readObjects(forClasses: [NSURL.self],
                                         options: [.urlReadingFileURLsOnly: true,
                                                   .urlReadingContentsConformToTypes: [DocumentType.theme.utType]])
        
        guard let urls = objects, !urls.isEmpty else { return [] }
        
        // highlight text view itself
        tableView.setDropRow(-1, dropOperation: .on)
        
        // show number of acceptable files
        info.numberOfValidItemsForDrop = urls.count
        
        return .copy
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        info.enumerateDraggingItems(for: tableView, classes: [NSURL.self],
                                    searchOptions: [.urlReadingFileURLsOnly: true,
                                                    .urlReadingContentsConformToTypes: [DocumentType.theme.utType]])
        { [unowned self] (draggingItem, _, _) in
            
            guard let fileURL = draggingItem.item as? URL else { return }
            
            self.importTheme(fileURL: fileURL)
        }
        
        AudioServicesPlaySystemSound(.volumeMount)
        
        return true
    }
    
    
    
    // MARK: Delegate
    
    // ThemeViewControllerDelegate
    
    /// theme did update
    func didUpdate(theme: Theme) {
        
        do {
            try ThemeManager.shared.save(setting: theme, name: self.selectedThemeName)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    // NSTableViewDelegate  < themeTableView
    
    /// selection of theme table did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard notification.object as? NSTableView == self.themeTableView else { return }
        
        self.setTheme(name: self.selectedThemeName)
    }
    
    
    /// set if table cell is editable
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        guard let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView else { return }
        
        let themeName = self.themeNames[row]
        let isBundled = ThemeManager.shared.isBundledSetting(name: themeName)
        
        view.textField?.isSelectable = false
        view.textField?.isEditable = !isBundled
    }
    
    
    /// set action on swiping theme name
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        
        guard edge == .trailing else { return [] }
        
        // get swiped theme
        let themeName = self.themeNames[row]
        
        // check whether theme is deletable
        let isBundled = ThemeManager.shared.isBundledSetting(name: themeName)
        let isCustomized = ThemeManager.shared.isCustomizedBundledSetting(name: themeName)
        
        // do nothing on undeletable theme
        guard !isBundled || isCustomized else { return [] }
        
        if isCustomized {
            // Restore
            return [NSTableViewRowAction(style: .regular,
                                         title: "Restore".localized,
                                         handler: { [weak self] (_, _) in
                                            self?.restoreTheme(name: themeName)
                                            
                                            // finish swiped mode anyway
                                            tableView.rowActionsVisible = false
                                         })]
            
        } else {
            // Delete
            return [NSTableViewRowAction(style: .destructive,
                                         title: "Delete".localized,
                                         handler: { [weak self] (_, _) in
                                            self?.deleteTheme(name: themeName)
                                         })]
        }
    }
    
    // NSTextFieldDelegate
    
    /// theme name was edited
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
    
    
    // NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        
        // create share menu dynamically
        if let shareMenuItem = menu.items.compactMap({ $0 as? ShareMenuItem }).first {
            let settingName = self.representedSettingName(for: menu) ?? self.selectedThemeName
            
            shareMenuItem.sharingItems = ThemeManager.shared.urlForUserSetting(name: settingName).flatMap { [$0] }
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// A radio button of documentConflictOption was clicked
    @IBAction func updateCursorTypeSetting(_ sender: NSButton) {
        
        UserDefaults.standard[.cursorType] = CursorType(rawValue: sender.tag)!
    }
    
    
    /// A radio button of documentAppearance was clicked
    @IBAction func updateAppearanceSetting(_ sender: NSButton) {
        
        UserDefaults.standard[.documentAppearance] = AppearanceMode(rawValue: sender.tag)!
        
        
        let themeName = ThemeManager.shared.userDefaultSettingName
        let row = self.themeNames.firstIndex(of: themeName) ?? 0
        
        self.themeTableView?.selectRowIndexes([row], byExtendingSelection: false)
    }
    
    
    /// add theme
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
    
    
    /// duplicate selected theme
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
    
    
    /// start renaming theme
    @IBAction func renameTheme(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        let row = self.themeNames.firstIndex(of: themeName) ?? 0
        
        self.themeTableView?.editColumn(0, row: row, with: nil, select: false)
    }
    
    
    /// delete selected theme
    @IBAction func deleteTheme(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        self.deleteTheme(name: themeName)
    }
    
    
    /// restore selected theme to original bundled one
    @IBAction func restoreTheme(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        self.restoreTheme(name: themeName)
    }
    
    
    /// export selected theme
    @IBAction func exportTheme(_ sender: Any?) {
        
        let settingName = self.targetThemeName(for: sender)
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.isExtensionHidden = true
        savePanel.nameFieldLabel = "Export As:".localized
        savePanel.nameFieldStringValue = settingName
        savePanel.allowedFileTypes = [ThemeManager.shared.filePathExtension]
        
        savePanel.beginSheetModal(for: self.view.window!) { [unowned self] (result: NSApplication.ModalResponse) in
            guard result == .OK else { return }
            
            do {
                try ThemeManager.shared.exportSetting(name: settingName, to: savePanel.url!, hidesExtension: savePanel.isExtensionHidden)
            } catch {
                self.presentError(error)
            }
        }
    }
    
    
    /// import theme file via open panel
    @IBAction func importTheme(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Import".localized
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = [ThemeManager.shared.filePathExtension]
        
        openPanel.beginSheetModal(for: self.view.window!) { [unowned self] (result: NSApplication.ModalResponse) in
            guard result == .OK else { return }
            
            for url in openPanel.urls {
                self.importTheme(fileURL: url)
            }
        }
    }
    
    
    /// open directory in Application Support in Finder where the selected theme exists
    @IBAction func revealThemeInFinder(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        guard let url = ThemeManager.shared.urlForUserSetting(name: themeName) else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    
    @IBAction func reloadAllThemes(_ sender: Any?) {
        
        ThemeManager.shared.reloadCache()
    }
    
    
    
    // MARK: Private Methods
    
    /// return theme name which is currently selected in the list table
    private var selectedThemeName: String {
        
        guard let tableView = self.themeTableView, tableView.selectedRow >= 0 else {
            return ThemeManager.shared.userDefaultSettingName
        }
        return self.themeNames[tableView.selectedRow]
    }
    
    
    /// return representedObject if sender is menu item, otherwise selection in the list table
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
    
    
    /// set given theme
    private func setTheme(name: String) {
        
        let theme = ThemeManager.shared.setting(name: name)
        let isBundled = ThemeManager.shared.isBundledSetting(name: name)
        
        // update default theme setting
        let isDarkTheme = ThemeManager.shared.isDark(name: name)
        let usesDarkAppearance = ThemeManager.shared.usesDarkAppearance
        UserDefaults.standard[.pinsThemeAppearance] = (isDarkTheme != usesDarkAppearance)
        UserDefaults.standard[.theme] = name
        
        self.themeViewController?.theme = theme
        self.themeViewController?.isBundled = isBundled
        self.themeViewController?.view.setAccessibilityLabel(name)
        
        self.isBundled = isBundled
    }
    
    
    /// try to delete given theme
    private func deleteTheme(name: String) {
        
        let alert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to delete “%@” theme?".localized, name)
        alert.informativeText = "This action cannot be undone.".localized
        alert.addButton(withTitle: "Cancel".localized)
        alert.addButton(withTitle: "Delete".localized)
        alert.buttons.last?.hasDestructiveAction = true
        
        let window = self.view.window!
        alert.beginSheetModal(for: window) { [weak self] (returnCode: NSApplication.ModalResponse) in
            
            guard returnCode == .alertSecondButtonReturn else {  // cancelled
                // flush swipe action for in case if this deletion was invoked by swiping the theme name
                self?.themeTableView?.rowActionsVisible = false
                return
            }
            
            do {
                try ThemeManager.shared.removeSetting(name: name)
                
            } catch {
                alert.window.orderOut(nil)
                NSSound.beep()
                NSAlert(error: error).beginSheetModal(for: window)
                return
            }
            
            AudioServicesPlaySystemSound(.moveToTrash)
        }
    }
    
    
    /// try to restore given theme
    private func restoreTheme(name: String) {
        
        do {
            try ThemeManager.shared.restoreSetting(name: name)
        } catch {
            self.presentError(error)
        }
    }
    
    
    /// try to import theme file at given URL
    private func importTheme(fileURL: URL) {
        
        do {
            try ThemeManager.shared.importSetting(fileURL: fileURL)
        } catch {
            // ask for overwriting if a setting with the same name already exists
            self.presentError(error)
        }
    }
    
    
    /// update theme list
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
    
    
    /// update selection of theme table
    private func updateThemeSelection() {
        
        let themeName = ThemeManager.shared.userDefaultSettingName
        let row = self.themeNames.firstIndex(of: themeName) ?? 0
        
        self.themeTableView?.selectRowIndexes([row], byExtendingSelection: false)
    }
    
}



// MARK: - Font Setting

extension AppearancePaneController: NSFontChanging {
    
    // MARK: View Controller Methods
    
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        // detach a possible font panel's target set in `showFonts()`
        if NSFontManager.shared.target === self {
            NSFontManager.shared.target = nil
        }
    }
    
    
    
    // MARK: Font Changing Methods
    
    /// restrict items in the font panel toolbar
    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        
        return [.collection, .face, .size]
    }
    
    
    
    // MARK: Action Messages
    
    /// show font panel
    @IBAction func showFonts(_ sender: Any?) {
        
        let name = UserDefaults.standard[.fontName]
        let size = UserDefaults.standard[.fontSize]
        let font = NSFont(name: name, size: size) ?? NSFont.userFont(ofSize: size)!
        
        NSFontManager.shared.setSelectedFont(font, isMultiple: false)
        NSFontManager.shared.orderFrontFontPanel(sender)
        NSFontManager.shared.target = self
    }
    
    
    /// font in font panel did update
    @IBAction func changeFont(_ sender: NSFontManager?) {
        
        guard let sender = sender else { return assertionFailure() }
        
        let newFont = sender.convert(.systemFont(ofSize: 0))
        
        UserDefaults.standard[.fontName] = newFont.fontName
        UserDefaults.standard[.fontSize] = newFont.pointSize
        
        self.setupFontFamilyNameAndSize()
    }
    
    
    /// update font name field with new setting
    @IBAction func updateFontField(_ sender: Any?) {
        
        self.setupFontFamilyNameAndSize()
    }
    
    
    
    // MARK: Private Methods
    
    /// display font name and size in the font field
    private func setupFontFamilyNameAndSize() {
        
        let name = UserDefaults.standard[.fontName]
        let size = UserDefaults.standard[.fontSize]
        let shouldAntiailias = UserDefaults.standard[.shouldAntialias]
        let maxDisplaySize = NSFont.systemFontSize(for: .regular)
        
        guard
            let font = NSFont(name: name, size: size),
            let displayFont = NSFont(name: name, size: min(size, maxDisplaySize)),
            let fontField = self.fontField
            else { return }
        
        let displayName = font.displayName ?? font.fontName
        
        fontField.stringValue = displayName + " " + String.localizedStringWithFormat("%g", size)
        fontField.font = displayFont
        fontField.disablesAntialiasing = !shouldAntiailias
    }
    
}
