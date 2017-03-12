/*
 
 AppearancePaneController.swift
 
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
import AudioToolbox

final class AppearancePaneController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, ThemeViewControllerDelegate {
    
    // MARK: Private Properties
    
    private dynamic let invisibleSpaces: [String] = Invisible.spaces
    private dynamic let invisibleTabs: [String] = Invisible.tabs
    private dynamic let invisibleNewLines: [String] = Invisible.newLines
    private dynamic let invisibleFullWidthSpaces: [String] = Invisible.fullWidthSpaces
    
    private var themeViewController: ThemeViewController?
    private var themeNames = [String]()
    private dynamic var isBundled = false
    
    @IBOutlet fileprivate private(set) weak var fontField: AntialiasingTextField?
    @IBOutlet private weak var themeTableView: NSTableView?
    @IBOutlet private weak var box: NSBox?
    @IBOutlet private var themeTableMenu: NSMenu?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // register droppable types
        self.themeTableView?.register(forDraggedTypes: [kUTTypeFileURL as String])
        
        self.themeNames = ThemeManager.shared.themeNames
        
        // observe theme list change
        NotificationCenter.default.addObserver(self, selector: #selector(setupThemeList), name: .ThemeListDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidUpdate), name: .ThemeDidUpdate, object: nil)
    }
    
    
    /// apply current settings to UI
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.setupFontFamilyNameAndSize()
        
        let themeName = UserDefaults.standard[.theme]!
        let row = self.themeNames.index(of: themeName) ?? 0
        self.themeTableView?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }
    
    
    /// apply current state to menu items
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextualMenu = (menuItem.menu == self.themeTableMenu)
        
        let representedTheme: String? = {
            guard isContextualMenu else {
                return self.selectedThemeName
            }
            let clickedRow = self.themeTableView?.clickedRow ?? -1
            
            guard clickedRow != -1 else { return nil }  // clicked blank area
            
            return self.themeNames[safe: clickedRow]
        }()
        menuItem.representedObject = representedTheme
        
        var isBundled = false
        var isCustomized = false
        if let representedTheme = representedTheme {
            isBundled = ThemeManager.shared.isBundledSetting(name: representedTheme)
            isCustomized = ThemeManager.shared.isCustomizedBundledSetting(name: representedTheme)
        }
        
        guard let action = menuItem.action else { return false }
        
        switch action {
        case #selector(addTheme), #selector(importTheme(_:)):
            menuItem.isHidden = (isContextualMenu && representedTheme != nil)
            
        case #selector(renameTheme(_:)):
            if !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Rename “%@”", comment: ""), representedTheme!)
            }
            menuItem.isHidden = (representedTheme == nil)
            return !isBundled
            
        case #selector(duplicateTheme(_:)):
            if !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Duplicate “%@”", comment: ""), representedTheme!)
            }
            menuItem.isHidden = (representedTheme == nil)
            
        case #selector(deleteTheme(_:)):
            menuItem.isHidden = (isBundled || representedTheme == nil)
            
        case #selector(restoreTheme(_:)):
            if !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Restore “%@”", comment: ""), representedTheme!)
            }
            menuItem.isHidden = (!isBundled || representedTheme == nil)
            return isCustomized
            
        case #selector(exportTheme(_:)):
            if !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Export “%@”…", comment: ""), representedTheme!)
            }
            menuItem.isHidden = (representedTheme == nil)
            return (!isBundled || isCustomized)
            
        case #selector(revealThemeInFinder(_:)):
            if !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Reveal “%@” in Finder", comment: ""), representedTheme!)
            }
            return (!isBundled || isCustomized)
            
        default: break
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
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        
        // get file URLs from pasteboard
        let pboard = info.draggingPasteboard()
        let objects = pboard.readObjects(forClasses: [NSURL.self],
                                         options: [NSPasteboardURLReadingFileURLsOnlyKey: true,
                                                   NSPasteboardURLReadingContentsConformToTypesKey: [DocumentType.theme.UTType]])
        
        guard let urls = objects, !urls.isEmpty else { return [] }
        
        // highlight text view itself
        tableView.setDropRow(-1, dropOperation: .on)
        
        // show number of theme files
        info.numberOfValidItemsForDrop = urls.count
        
        return .copy
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        
        info.enumerateDraggingItems(for: tableView, classes: [NSURL.self],
                                    searchOptions: [NSPasteboardURLReadingFileURLsOnlyKey: true,
                                                    NSPasteboardURLReadingContentsConformToTypesKey: [DocumentType.theme.UTType]])
        { [weak self] (draggingItem: NSDraggingItem, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            
            guard let fileURL = draggingItem.item as? URL else { return }
            
            self?.importTheme(fileURL: fileURL)
        }
        
        return true
    }
    
    
    
    // MARK: Delegate
    
    // ThemeViewControllerDelegate
    
    /// theme did update
    func didUpdate(theme: ThemeDictionary) {
        
        // save
        ThemeManager.shared.save(themeDictionary: theme, name: self.selectedThemeName)
    }
    
    
    // NSTableViewDelegate  < themeTableView
    
    /// selection of theme table did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let object = notification.object as? NSTableView, object == self.themeTableView else { return }
        
        let themeName = self.selectedThemeName
        let themeDict = ThemeManager.shared.themeDictionary(name: themeName)
        let isBundled = ThemeManager.shared.isBundledSetting(name: themeName)
        
        // update default theme setting
        if let oldThemeName = UserDefaults.standard[.theme], oldThemeName != themeName {
            UserDefaults.standard[.theme] = themeName
            
            // update theme of the current document windows
            //   -> [caution] The theme list of the theme manager can not be updated yet at this point.
            NotificationCenter.default.post(name: .ThemeDidUpdate,
                                            object: self,
                                            userInfo: [SettingFileManager.NotificationKey.old: oldThemeName,
                                                       SettingFileManager.NotificationKey.new: themeName])
        }
        
        let themeViewController = ThemeViewController()
        themeViewController.delegate = self
        themeViewController.theme = themeDict
        themeViewController.isBundled = isBundled
        self.themeViewController = themeViewController
        self.box?.contentView = themeViewController.view
        
        self.isBundled = isBundled
    }
    
    
    /// set if table cell is editable
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        guard let view = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView else { return }
        
        let themeName = self.themeNames[row]
        let isBundled = ThemeManager.shared.isBundledSetting(name: themeName)
        
        view.textField?.isEditable = !isBundled
    }
    
    
    /// theme nama was edited
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        // finish if empty (The original name will be restored automatically)
        guard let newName = fieldEditor.string, !newName.isEmpty else { return true }
        
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
        
        return true
    }
    
    
    /// set action on swiping theme name
    @available(macOS 10.11, *)
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        
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
                                         title: NSLocalizedString("Restore", comment: ""),
                                         handler: { [weak self] (action: NSTableViewRowAction, row: Int) in
                                            self?.restoreTheme(name: themeName)
                                            
                                            // finish swiped mode anyway
                                            tableView.rowActionsVisible = false
                })]
            
        } else {
            // Delete
            return [NSTableViewRowAction(style: .destructive,
                                         title: NSLocalizedString("Delete", comment: ""),
                                         handler: { [weak self] (action: NSTableViewRowAction, row: Int) in
                                            self?.deleteTheme(name: themeName)
                })]
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// add theme
    @IBAction func addTheme(_ sender: Any?) {
        
        guard let tableView = self.themeTableView else { return }
        
        ThemeManager.shared.createUntitledTheme { (themeName: String, error: Error?) in
            let themeNames = ThemeManager.shared.themeNames
            let row = themeNames.index(of: themeName) ?? 0
            
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }
    
    
    /// duplicate selected theme
    @IBAction func duplicateTheme(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        try? ThemeManager.shared.duplicateSetting(name: themeName)
    }
    
    
    /// start renaming theme
    @IBAction func renameTheme(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        let row = self.themeNames.index(of: themeName) ?? 0
        
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
        
        let themeName = self.targetThemeName(for: sender)
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.nameFieldLabel = NSLocalizedString("Export As:", comment: "")
        savePanel.nameFieldStringValue = themeName
        savePanel.allowedFileTypes = [ThemeManager.shared.filePathExtension]
        
        savePanel.beginSheetModal(for: self.view.window!) { (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            try? ThemeManager.shared.exportSetting(name: themeName, to: savePanel.url!)
        }
    }
    
    
    /// import theme file via open panel
    @IBAction func importTheme(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = NSLocalizedString("Import", comment: "")
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = [ThemeManager.shared.filePathExtension]
        
        openPanel.beginSheetModal(for: self.view.window!) { [weak self] (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            self?.importTheme(fileURL: openPanel.url!)
        }
    }
    
    
    /// open directory in Application Support in Finder where the selected theme exists
    @IBAction func revealThemeInFinder(_ sender: Any?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        guard let url = ThemeManager.shared.urlForUserSetting(name: themeName) else { return }
        
        NSWorkspace.shared().activateFileViewerSelecting([url])
    }
    
    
    @IBAction func reloadAllThemes(_ sender: AnyObject?) {
        
        ThemeManager.shared.updateCache()
    }
    
    
    
    // MARK: Private Methods
    
    /// return theme name which is currently selected in the list table
    private dynamic var selectedThemeName: String {
        
        guard let tableView = self.themeTableView else {
            return UserDefaults.standard[.theme]!
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
    
    
    /// refresh theme view if current displayed theme was restored
    @objc private func themeDidUpdate(_ notification: Notification) {
        
        guard
            let bundledTheme = ThemeManager.shared.themeDictionary(name: self.selectedThemeName),
            let newTheme = self.themeViewController?.theme else { return }
        
        if bundledTheme == newTheme {
            self.themeViewController?.theme = bundledTheme
        }
    }
    
    
    /// try to delete given theme
    private func deleteTheme(name: String) {
        
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("Are you sure you want to delete “%@” theme?", comment: ""), name)
        alert.informativeText = NSLocalizedString("This action cannot be undone.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        
        let window = self.view.window!
        alert.beginSheetModal(for: window) { [weak self] (returnCode: NSModalResponse) in
            
            guard returnCode == NSAlertSecondButtonReturn else {  // cancelled
                // flush swipe action for in case if this deletion was invoked by swiping the theme name
                if #available(macOS 10.11, *) {
                    self?.themeTableView?.rowActionsVisible = false
                }
                return
            }
            
            do {
                try ThemeManager.shared.removeSetting(name: name)
                
            } catch {
                alert.window.orderOut(nil)
                NSBeep()
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
    @objc private func setupThemeList() {
        
        let themeName = UserDefaults.standard[.theme]!
        
        self.themeNames = ThemeManager.shared.themeNames
        self.themeTableView?.reloadData()
        
        let row = self.themeNames.index(of: themeName) ?? 0
        self.themeTableView?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }
    
}



// MARK: - Font Setting

extension AppearancePaneController {
    
    // MARK: Action Messages
    
    /// show font panel
    @IBAction func showFonts(_ sender: Any?) {
        
        guard let font = NSFont(name: UserDefaults.standard[.fontName]!,
                                size: UserDefaults.standard[.fontSize]) else { return }
        
        self.view.window?.makeFirstResponder(self)
        NSFontManager.shared().setSelectedFont(font, isMultiple: false)
        NSFontManager.shared().orderFrontFontPanel(sender)
    }
    
    
    /// font in font panel did update
    @IBAction override func changeFont(_ sender: Any?) {
        
        guard let fontManager = sender as? NSFontManager else { return }
        
        let newFont = fontManager.convert(.systemFont(ofSize: 0))
        
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
    fileprivate func setupFontFamilyNameAndSize() {
        
        let name = UserDefaults.standard[.fontName]!
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
