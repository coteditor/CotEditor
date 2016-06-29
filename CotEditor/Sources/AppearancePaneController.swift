/*
 
 AppearancePaneController.swift
 
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
import AudioToolbox

class AppearancePaneController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, ThemeViewControllerDelegate {
    
    // MARK: Private Properties
    
    private dynamic let invisibleSpaces: [String] = Invisible.spaces
    private dynamic let invisibleTabs: [String] = Invisible.tabs
    private dynamic let invisibleNewLines: [String] = Invisible.newLines
    private dynamic let invisibleFullWidthSpaces: [String] = Invisible.fullWidthSpaces
    
    private var themeViewController: ThemeViewController?
    private var themeNames = [String]()
    private dynamic var isBundled = false
    
    @IBOutlet private weak var fontField: AntialiasingTextField?
    @IBOutlet private weak var themeTableView: NSTableView?
    @IBOutlet private weak var box: NSBox?
    @IBOutlet private weak var themeTableMenu: NSMenu?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default().removeObserver(self)
    }
    
    
    override var nibName: String? {
        
        return "AppearancePane"
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.setupFontFamilyNameAndSize()
        
        self.setupThemeList()
        
        // register droppable types
        self.themeTableView?.register(forDraggedTypes: [kUTTypeFileURL as String])
        
        // select default theme
        let themeName = UserDefaults.standard().string(forKey: CEDefaultThemeKey)!
        let row = self.themeNames.index(of: themeName) ?? 0
        self.themeTableView?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        
        // observe theme list change
        NotificationCenter.default().addObserver(self, selector: #selector(setupThemeList), name: .CEThemeListDidUpdate, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(themeDidUpdate), name: .CEThemeDidUpdate, object: nil)
    }
    
    
    /// apply current state to menu items
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextualMenu = (menuItem.menu == self.themeTableMenu)
        
        var representedTheme: String? = self.selectedThemeName
        if (isContextualMenu) {
            let clickedRow = self.themeTableView?.clickedRow ?? -1
            
            if clickedRow == -1 {  // clicked blank area
                representedTheme = nil
            } else {
                representedTheme = self.themeNames[clickedRow]
            }
        }
        menuItem.representedObject = representedTheme
        
        var isCustomized: ObjCBool = false
        var isBundled = false
        if let representedTheme = representedTheme {
            isBundled = CEThemeManager.shared().isBundledSetting(representedTheme, cutomized: &isCustomized)
        }
        
        guard let action = menuItem.action else { return false }
        
        switch action {
        case #selector(addTheme), #selector(importTheme(_:)):
            menuItem.isHidden = (isContextualMenu && representedTheme != nil)
            
        case #selector(renameTheme(_:)):
            if !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Rename “%@”…", comment: ""), representedTheme!)
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
            return isCustomized.boolValue
            
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
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
        return self.themeNames[row]
    }
    
    
    /// validate when dragged items come to tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        
        // get file URLs from pasteboard
        let pboard = info.draggingPasteboard()
        let objects = pboard.readObjects(forClasses: [NSURL.self],
                                         options: [NSPasteboardURLReadingFileURLsOnlyKey: true,
                                                   NSPasteboardURLReadingContentsConformToTypesKey: [CEUTTypeTheme]])
        
        guard let urls = objects where !urls.isEmpty else { return [] }
        
        // highlight text view itself
        tableView.setDropRow(-1, dropOperation: .on)
        
        // show number of theme files
        info.numberOfValidItemsForDrop = urls.count
        
        return .copy
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        
        info.enumerateDraggingItems([], for: tableView, classes: [NSURL.self],
                                    searchOptions: [NSPasteboardURLReadingFileURLsOnlyKey: true,
                                                    NSPasteboardURLReadingContentsConformToTypesKey: [CEUTTypeTheme]]) { [weak self]
                                                        (draggingItem: NSDraggingItem, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                                                        
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
        CEThemeManager.shared().saveThemeDictionary(theme, name: self.selectedThemeName, completionHandler: nil)
    }
    
    
    // NSTableViewDelegate  < themeTableView
    
    /// selection of theme table did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let object = notification.object as? NSTableView where object == self.themeTableView else { return }
        
        let themeName = self.selectedThemeName
        let themeDict = CEThemeManager.shared().themeDictionary(withName: themeName)
        let isBundled = CEThemeManager.shared().isBundledSetting(themeName, cutomized: nil)
        
        // update default theme setting
        // -> skip on the first time because, at the time point, the settings are not yet applied.
        if self.themeViewController != nil {
            let oldThemeName = UserDefaults.standard().string(forKey: CEDefaultThemeKey)!
            
            UserDefaults.standard().set(themeName, forKey: CEDefaultThemeKey)
            
            // update theme of the current document windows
            //   -> [caution] The theme list of the theme manager can not be updated yet at this point.
            NotificationCenter.default().post(name: .CEThemeDidUpdate, object: self, userInfo: [CEOldNameKey: oldThemeName,
                                                                                                CENewNameKey: themeName])
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
        let isBundled = CEThemeManager.shared().isBundledSetting(themeName, cutomized: nil)
        
        view.textField?.isEditable = isBundled
    }
    
    
    /// theme nama was edited
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        
        // finish if empty (The original name will be restored automatically)
        guard let newName = fieldEditor.string where !newName.isEmpty else { return true }
        
        let oldName = self.selectedThemeName
        
        do {
            try CEThemeManager.shared().renameSetting(withName: oldName, toName: newName)
            
        } catch let error as NSError {
            // revert name
            fieldEditor.string = oldName
            
            // show alert
            NSAlert(error: error).beginSheetModal(for: self.view.window!, completionHandler: nil)
            return false
        }
        
        return true
    }
    
    
    /// set action on swiping theme name
    @available(OSX 10.11, *)
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        
        guard edge == .trailing else { return [] }
        
        // get swiped theme
        let themeName = self.themeNames[row]
        
        // check whether theme is deletable
        var isCustomized: ObjCBool = false
        let isBundled = CEThemeManager.shared().isBundledSetting(themeName, cutomized: &isCustomized)
        
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
    
    /// show font panel
    @IBAction func showFonts(_ sender: AnyObject?) {
        
        guard let font = NSFont(name: UserDefaults.standard().string(forKey: CEDefaultFontNameKey)!,
                                size: CGFloat(UserDefaults.standard().double(forKey: CEDefaultFontSizeKey))) else { return }
        
        self.view.window?.makeFirstResponder(self)
        NSFontManager.shared().setSelectedFont(font, isMultiple: false)
        NSFontManager.shared().orderFrontFontPanel(sender)
    }
    
    
    /// font in font panel did update
    @IBAction override func changeFont(_ sender: AnyObject?) {
        
        guard let fontManager = sender as? NSFontManager else { return }
        
        let newFont = fontManager.convert(NSFont.systemFont(ofSize: 0))
        
        UserDefaults.standard().set(newFont.fontName, forKey: CEDefaultFontNameKey)
        UserDefaults.standard().set(newFont.pointSize, forKey: CEDefaultFontSizeKey)
        
        self.setupFontFamilyNameAndSize()
    }
    
    
    /// update font name field with new setting
    @IBAction func updateFontField(_ sender: AnyObject?) {
        
        self.setupFontFamilyNameAndSize()
    }
    
    
    /// add theme
    @IBAction func addTheme(_ sender: AnyObject?) {
        
        guard let tableView = self.themeTableView else { return }
        
        CEThemeManager.shared().createUntitledTheme { (themeName: String, error: NSError?) in
            let themeNames = CEThemeManager.shared().themeNames
            let row = themeNames.index(of: themeName) ?? 0
            
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }
    
    
    /// duplicate selected theme
    @IBAction func duplicateTheme(_ sender: AnyObject?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        _ = try? CEThemeManager.shared().duplicateSetting(withName: themeName)
    }
    
    
    /// start renaming theme
    @IBAction func renameTheme(_ sender: AnyObject?) {
        
        let themeName = self.targetThemeName(for: sender)
        let row = self.themeNames.index(of: themeName) ?? 0
        
        self.themeTableView?.editColumn(0, row: row, with: nil, select: false)
    }
    
    
    /// delete selected theme
    @IBAction func deleteTheme(_ sender: AnyObject?) {
     
        let themeName = self.targetThemeName(for: sender)
        
        self.deleteTheme(name: themeName)
    }
    
    
    /// restore selected theme to original bundled one
    @IBAction func restoreTheme(_ sender: AnyObject?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        self.restoreTheme(name: themeName)
    }
    
    
    /// export selected theme
    @IBAction func exportTheme(_ sender: AnyObject?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.nameFieldLabel = NSLocalizedString("Export As:", comment: "")
        savePanel.nameFieldStringValue = themeName
        savePanel.allowedFileTypes = [CEThemeManager.shared().filePathExtension()]
        
        savePanel.beginSheetModal(for: self.view.window!) { (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            _ = try? CEThemeManager.shared().exportSetting(withName: themeName, to: savePanel.url!)
        }
    }
    
    
    /// import theme file via open panel
    @IBAction func importTheme(_ sender: AnyObject?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = NSLocalizedString("", comment: "")
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = [CEThemeManager.shared().filePathExtension()]
        
        openPanel.beginSheetModal(for: self.view.window!) { [weak self] (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            self?.importTheme(fileURL: openPanel.url!)
        }
    }
    
    
    /// open directory in Application Support in Finder where the selected theme exists
    @IBAction func revealThemeInFinder(_ sender: AnyObject?) {
        
        let themeName = self.targetThemeName(for: sender)
        
        guard let url = CEThemeManager.shared().urlForUserSetting(withName: themeName) else { return }
        
        NSWorkspace.shared().activateFileViewerSelecting([url])
    }
    
    
    
    // MARK: Private Methods
    
    /// display font name and size in the font field
    private func setupFontFamilyNameAndSize() {
        
        let name = UserDefaults.standard().string(forKey: CEDefaultFontNameKey)!
        let size = CGFloat(UserDefaults.standard().double(forKey: CEDefaultFontSizeKey))
        let shouldAntiailias = UserDefaults.standard().bool(forKey: CEDefaultShouldAntialiasKey)
        
        guard let font = NSFont(name: name, size: size),
            let displayFont = NSFont(name: name, size: min(size, 13.0)),
            let fontField = self.fontField else { return }
        
        fontField.stringValue = font.displayName! + " " + String(size)
        fontField.font = displayFont
        fontField.disablesAntialiasing = !shouldAntiailias
    }
    
    

    /// return theme name which is currently selected in the list table
    private dynamic var selectedThemeName: String {
        
        guard let tableView = self.themeTableView else {
            return UserDefaults.standard().string(forKey: CEDefaultThemeKey)!
        }
        return self.themeNames[tableView.selectedRow]
    }
    
    
    /// return representedObject if sender is menu item, otherwise selection in the list table
    private func targetThemeName(for sender: AnyObject?) -> String {
        
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as! String
        }
        return self.selectedThemeName
    }
    
    
    /// refresh theme view if current displayed theme was restored
    func themeDidUpdate(_ notification: Notification) {
        
        let bundledTheme = CEThemeManager.shared().themeDictionary(withName: self.selectedThemeName)
        
        if bundledTheme! == (self.themeViewController?.theme)! {
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
        alert.beginSheetModal(for: window) { (returnCode: NSModalResponse) in
            
            guard returnCode == NSAlertSecondButtonReturn else {  // cancelled
                // flush swipe action for in case if this deletion was invoked by swiping the theme name
                if #available(OSX 10.11, *) {
                    self.themeTableView?.rowActionsVisible = false
                }
                return
            }
            
            do {
                try CEThemeManager.shared().removeSetting(withName: name)
                
            } catch let error as NSError {
                alert.window.orderOut(nil)
                NSBeep()
                NSAlert(error: error).beginSheetModal(for: window, completionHandler: nil)
                return
            }
            
            AudioServicesPlaySystemSound(.moveToTrash)
        }
    }
    
    
    /// try to restore given theme
    private func restoreTheme(name: String) {
        
        do {
            try CEThemeManager.shared().restoreSetting(withName: name)
        } catch let error as NSError {
            self.presentError(error)
        }
    }
    
    
    /// try to import theme file at given URL
    private func importTheme(fileURL: URL) {
        
        do {
            try CEThemeManager.shared().importSetting(withFileURL: fileURL)
        } catch let error as NSError {
            // ask for overwriting if a setting with the same name already exists
            self.presentError(error)
        }
    }
    
    
    /// update theme list
    func setupThemeList() {
        
        self.themeNames = CEThemeManager.shared().themeNames
        self.themeTableView?.reloadData()
    }
    
}
