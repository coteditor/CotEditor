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
//  © 2014-2020 1024jp
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

import Cocoa
import AudioToolbox

/// keys for styles controller
private enum StyleKey: String {
    case name
    case state
}


private let isUTF8WithBOMFlag = "UTF-8 with BOM"


final class FormatPaneController: NSViewController, NSMenuItemValidation, NSTableViewDelegate, NSTableViewDataSource {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var inOpenEncodingMenu: NSPopUpButton?
    @IBOutlet private weak var inNewEncodingMenu: NSPopUpButton?
    
    @IBOutlet private var stylesController: NSArrayController?
    @IBOutlet private var syntaxTableMenu: NSMenu?
    @IBOutlet private weak var syntaxTableView: NSTableView?
    @IBOutlet private weak var syntaxStylesDefaultPopup: NSPopUpButton?
    @IBOutlet private weak var syntaxStyleDeleteButton: NSButton?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.syntaxTableView?.doubleAction = #selector(editSyntaxStyle)
        self.syntaxTableView?.target = self
        
        self.syntaxTableView?.registerForDraggedTypes([.URL])
    }
    
    
    /// apply current settings to UI
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.setupEncodingMenus()
        self.setupSyntaxStyleMenus()
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupEncodingMenus), name: didUpdateSettingListNotification, object: EncodingManager.shared)
        NotificationCenter.default.addObserver(self, selector: #selector(setupSyntaxStyleMenus), name: didUpdateSettingListNotification, object: SyntaxManager.shared)
        NotificationCenter.default.addObserver(self, selector: #selector(setupSyntaxStyleMenus), name: didUpdateSettingNotification, object: SyntaxManager.shared)
    }
    
    
    /// stop observations for UI update
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        NotificationCenter.default.removeObserver(self, name: didUpdateSettingListNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: didUpdateSettingNotification, object: nil)
    }
    
    
    
    // MARK: Menu Item Validation
    
    /// apply current state to menu items
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextualMenu = (menuItem.menu == self.syntaxTableMenu)
        
        let representedSettingName: String? = {
            guard isContextualMenu else {
                return self.selectedStyleName
            }
            
            guard let clickedRow = self.syntaxTableView?.clickedRow, clickedRow != -1 else { return nil }  // clicked blank area
            
            guard let arrangedObjects = self.stylesController!.arrangedObjects as? [[String: Any]] else { return nil }
            
            return arrangedObjects[clickedRow][StyleKey.name.rawValue] as? String
        }()
        
        // set style name as representedObject to menu items whose action is related to syntax style
        if NSStringFromSelector(menuItem.action!).contains("Syntax") {
            menuItem.representedObject = representedSettingName
        }
        
        let itemSelected = (representedSettingName != nil)
        let isBundled: Bool
        let isCustomized: Bool
        if let representedSettingName = representedSettingName {
            isBundled = SyntaxManager.shared.isBundledSetting(name: representedSettingName)
            isCustomized = SyntaxManager.shared.isCustomizedBundledSetting(name: representedSettingName)
        } else {
            (isBundled, isCustomized) = (false, false)
        }
        
        // append target setting name to menu titles
        switch menuItem.action {
            case #selector(openSyntaxMappingConflictSheet(_:)):
                return SyntaxManager.shared.mappingConflicts.contains { !$0.value.isEmpty }
            
            case #selector(duplicateSyntaxStyle(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Duplicate “%@”".localized, name)
                }
                menuItem.isHidden = !itemSelected
            
            case #selector(deleteSyntaxStyle(_:)):
                menuItem.isHidden = (isBundled || !itemSelected)
            
            case #selector(restoreSyntaxStyle(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Restore “%@”".localized, name)
                }
                menuItem.isHidden = (!isBundled || !itemSelected)
                return isCustomized
            
            case #selector(exportSyntaxStyle(_:)):
                if let name = representedSettingName, !isContextualMenu {
                    menuItem.title = String(format: "Export “%@”…".localized, name)
                }
                menuItem.isHidden = !itemSelected
                return (!isBundled || isCustomized)
            
            case #selector(revealSyntaxStyleInFinder(_:)):
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
    
    
    
    // MARK: Delegate & Data Source
    
    /// selected syntax style in "Installed styles" list table did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard notification.object as? NSTableView == self.syntaxTableView else { return }
        
        self.validateRemoveSyntaxStyleButton()
    }
    
    
    /// set action on swiping style name
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        
        guard edge == .trailing else { return [] }
        
        // get swiped style
        let arrangedObjects = self.stylesController!.arrangedObjects as! [[String: Any]]
        let styleName = arrangedObjects[row][StyleKey.name.rawValue] as! String
        
        // check whether style is deletable
        let isBundled = SyntaxManager.shared.isBundledSetting(name: styleName)
        let isCustomized = SyntaxManager.shared.isCustomizedBundledSetting(name: styleName)
        
        // do nothing on undeletable style
        guard !isBundled || isCustomized else { return [] }
        
        if isCustomized {
            // Restore
            return [NSTableViewRowAction(style: .regular,
                                         title: "Restore".localized,
                                         handler: { [weak self] (action: NSTableViewRowAction, row: Int) in
                                            self?.restoreSyntaxStyle(name: styleName)
                                            
                                            // finish swiped mode anyway
                                            tableView.rowActionsVisible = false
                })]
            
        } else {
            // Delete
            return [NSTableViewRowAction(style: .destructive,
                                         title: "Delete".localized,
                                         handler: { [weak self] (action: NSTableViewRowAction, row: Int) in
                                            self?.deleteSyntaxStyle(name: styleName)
                })]
        }
    }
    
    
    /// validate when dragged items come to tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        // get file URLs from pasteboard
        let pboard = info.draggingPasteboard
        let urls = pboard.readObjects(forClasses: [NSURL.self],
                                      options: [.urlReadingFileURLsOnly: true])?
            .compactMap { $0 as? URL }
            .filter { SyntaxManager.shared.filePathExtensions.contains($0.pathExtension) } ?? []
        
        guard !urls.isEmpty else { return [] }
        
        // highlight text view itself
        tableView.setDropRow(-1, dropOperation: .on)
        
        // show number of acceptable files
        info.numberOfValidItemsForDrop = urls.count
        
        return .copy
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        info.enumerateDraggingItems(for: tableView, classes: [NSURL.self],
                                    searchOptions: [.urlReadingFileURLsOnly: true])
        { [unowned self] (draggingItem: NSDraggingItem, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            
            guard
                let fileURL = draggingItem.item as? URL,
                SyntaxManager.shared.filePathExtensions.contains(fileURL.pathExtension)
                else { return }
            
            self.importSyntaxStyle(fileURL: fileURL)
        }
        
        AudioServicesPlaySystemSound(.volumeMount)
        
        return true
    }
    
    
    
    // MARK: Action Messages
    
    /// save also availability of UTF-8 BOM
    @IBAction func changeEncodingInNewDocument(_ sender: Any?) {
        
        let withUTF8BOM = (self.inNewEncodingMenu?.selectedItem?.representedObject as? String) == isUTF8WithBOMFlag
        
        UserDefaults.standard[.saveUTF8BOM] = withUTF8BOM
    }
    
    
    /// recommend user to use "Auto-Detect" on changing encoding setting
    @IBAction func checkSelectedItemOfInOpenEncodingMenu(_ sender: Any?) {
        
        guard let newTitle = self.inOpenEncodingMenu?.selectedItem?.title, newTitle != "Auto-Detect".localized else { return }
        
        let alert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to change to “%@”?".localized, newTitle)
        alert.informativeText = "The default “Auto-Detect” is recommended for most cases.".localized
        alert.addButton(withTitle: "Revert to “Auto-Detect”".localized)
        alert.addButton(withTitle: String(format: "Change to “%@”".localized, newTitle))
        
        alert.beginSheetModal(for: self.view.window!) { (returnCode: NSApplication.ModalResponse) in
            guard returnCode == .alertFirstButtonReturn else { return }
            
            UserDefaults.standard[.encodingInOpen] = String.Encoding.autoDetection.rawValue
        }
    }
    
    
    /// show syntax mapping conflict error sheet
    @IBAction func openSyntaxMappingConflictSheet(_ sender: Any?) {
        
        let viewController = NSViewController.instantiate(storyboard: "SyntaxMappingConflictsView")
        
        self.presentAsSheet(viewController)
    }
    
    
    /// show syntax style edit sheet
    @IBAction func editSyntaxStyle(_ sender: Any?) {
        
        let styleName = self.targetStyleName(for: sender)
        let viewController = SyntaxEditViewController.instantiate(storyboard: "SyntaxEditView")
        viewController.mode = .edit(styleName)
        
        self.presentAsSheet(viewController)
    }
    
    
    /// show syntax style edit sheet in copy mode
    @IBAction func duplicateSyntaxStyle(_ sender: Any?) {
        
        let styleName = self.targetStyleName(for: sender)
        let viewController = SyntaxEditViewController.instantiate(storyboard: "SyntaxEditView")
        viewController.mode = .copy(styleName)
        
        self.presentAsSheet(viewController)
    }
    
    
    /// show syntax style edit sheet in new mode
    @IBAction func createSyntaxStyle(_ sender: Any?) {
        
        let viewController = SyntaxEditViewController.instantiate(storyboard: "SyntaxEditView")
        
        self.presentAsSheet(viewController)
    }
    
    
    /// delete selected syntax style
    @IBAction func deleteSyntaxStyle(_ sender: Any?) {
        
        let styleName = self.targetStyleName(for: sender)
        
        self.deleteSyntaxStyle(name: styleName)
    }
    
    
    /// restore selected syntax style to original bundled one
    @IBAction func restoreSyntaxStyle(_ sender: Any?) {
        
        let styleName = self.targetStyleName(for: sender)
        
        self.restoreSyntaxStyle(name: styleName)
    }
    
    
    /// export selected syntax style
    @IBAction func exportSyntaxStyle(_ sender: Any?) {
        
        let settingName = self.targetStyleName(for: sender)
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.nameFieldLabel = "Export As:".localized
        savePanel.nameFieldStringValue = settingName
        savePanel.allowedFileTypes = [SyntaxManager.shared.filePathExtension]
        
        savePanel.beginSheetModal(for: self.view.window!) { [unowned self] (result: NSApplication.ModalResponse) in
            guard result == .OK else { return }
            
            do {
                try SyntaxManager.shared.exportSetting(name: settingName, to: savePanel.url!, hidesExtension: savePanel.isExtensionHidden)
            } catch {
                self.presentError(error)
            }
        }
    }
    
    
    /// import syntax style file via open panel
    @IBAction func importSyntaxStyle(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Import".localized
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = SyntaxManager.shared.filePathExtensions + ["plist"]
        
        openPanel.beginSheetModal(for: self.view.window!) { [unowned self] (result: NSApplication.ModalResponse) in
            guard result == .OK else { return }
            
            for url in openPanel.urls {
                self.importSyntaxStyle(fileURL: url)
            }
        }
    }
    
    
    /// open directory in Application Support in Finder where the selected style exists
    @IBAction func revealSyntaxStyleInFinder(_ sender: Any?) {
        
        let styleName = self.targetStyleName(for: sender)
        
        guard let url = SyntaxManager.shared.urlForUserSetting(name: styleName) else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    
    @IBAction func reloadAllStyles(_ sender: Any?) {
        
        SyntaxManager.shared.updateCache()
    }
    
    
    
    // MARK: Private Methods
    
    /// build encodings menus
    @objc private func setupEncodingMenus() {
        
        guard
            let inOpenMenu = self.inOpenEncodingMenu?.menu,
            let inNewMenu = self.inNewEncodingMenu?.menu
            else { return assertionFailure() }
        
        let menuItems = EncodingManager.shared.createEncodingMenuItems()
        
        inOpenMenu.removeAllItems()
        inNewMenu.removeAllItems()
        
        let autoDetectItem = NSMenuItem(title: "Auto-Detect".localized, action: nil, keyEquivalent: "")
        autoDetectItem.tag = Int(String.Encoding.autoDetection.rawValue)
        inOpenMenu.addItem(autoDetectItem)
        inOpenMenu.addItem(.separator())
        
        let utf8Int = Int(String.Encoding.utf8.rawValue)
        for item in menuItems {
            inOpenMenu.addItem(item)
            inNewMenu.addItem(item.copy() as! NSMenuItem)
            
            // add "UTF-8 with BOM" item only to "In New" menu
            if item.tag == utf8Int {
                let bomItem = NSMenuItem(title: String.localizedName(of: .utf8, withUTF8BOM: true), action: nil, keyEquivalent: "")
                bomItem.tag = utf8Int
                bomItem.representedObject = isUTF8WithBOMFlag
                inNewMenu.addItem(bomItem)
            }
        }
        
        // select menu item for the current setting manually although Cocoa-Bindings are used on these menus
        // -> Because items were actually added after Cocoa-Binding selected the item.
        let inOpenEncoding = UserDefaults.standard[.encodingInOpen]
        let inNewEncoding = UserDefaults.standard[.encodingInNew]
        self.inOpenEncodingMenu?.selectItem(withTag: Int(inOpenEncoding))
        
        if Int(inNewEncoding) == utf8Int {
            let UTF8WithBomIndex = inNewMenu.indexOfItem(withRepresentedObject: isUTF8WithBOMFlag)
            let index = UserDefaults.standard[.saveUTF8BOM] ? UTF8WithBomIndex : UTF8WithBomIndex - 1
            // -> The normal "UTF-8" locates just above "UTF-8 with BOM".
            
            self.inNewEncodingMenu?.selectItem(at: index)
        } else {
            self.inNewEncodingMenu?.selectItem(withTag: Int(inNewEncoding))
        }
    }
    
    
    /// build sytnax style menus
    @objc private func setupSyntaxStyleMenus() {
        
        let styleNames = SyntaxManager.shared.settingNames
        
        let styleStates: [[String: Any]] = styleNames.map { styleName in
            let isBundled = SyntaxManager.shared.isBundledSetting(name: styleName)
            let isCustomized = SyntaxManager.shared.isCustomizedBundledSetting(name: styleName)
            
            return [StyleKey.name.rawValue: styleName,
                    StyleKey.state.rawValue: (!isBundled || isCustomized)]
        }
        
        // update installed style list table
        self.stylesController?.content = styleStates
        self.validateRemoveSyntaxStyleButton()
        self.syntaxTableView?.reloadData()
        
        // update default style popup menu
        if let popup = self.syntaxStylesDefaultPopup {
            popup.removeAllItems()
            popup.addItem(withTitle: BundledStyleName.none)
            popup.menu?.addItem(.separator())
            popup.addItems(withTitles: styleNames)
            
            // select menu item for the current setting manually although Cocoa-Bindings are used on this menu
            // -> Because items were actually added after Cocoa-Binding selected the item.
            let defaultStyle = UserDefaults.standard[.syntaxStyle]!
            let selectedStyle = styleNames.contains(defaultStyle) ? defaultStyle : BundledStyleName.none
            
            popup.selectItem(withTitle: selectedStyle)
        }
    }
    
    
    /// return syntax style name which is currently selected in the list table
    @objc private dynamic var selectedStyleName: String {
        
        guard let styleInfo = self.stylesController?.selectedObjects.first as? [String: Any] else {
            return UserDefaults.standard[.syntaxStyle]!
        }
        return styleInfo[StyleKey.name.rawValue] as! String
    }
    
    
    /// return representedObject if sender is menu item, otherwise selection in the list table
    private func targetStyleName(for sender: Any?) -> String {
        
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as! String
        }
        return self.selectedStyleName
    }
    
    
    /// update button that deletes syntax style
    private func validateRemoveSyntaxStyleButton() {
        
        self.syntaxStyleDeleteButton?.isEnabled = !SyntaxManager.shared.isBundledSetting(name: self.selectedStyleName)
    }
    
    
    /// try to delete given syntax style
    private func deleteSyntaxStyle(name: String) {
        
        let alert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to delete “%@” syntax style?".localized, name)
        alert.informativeText = "This action cannot be undone.".localized
        alert.addButton(withTitle: "Cancel".localized)
        alert.addButton(withTitle: "Delete".localized)
        
        let window = self.view.window!
        alert.beginSheetModal(for: window) { [unowned self] (returnCode: NSApplication.ModalResponse) in
            
            guard returnCode == .alertSecondButtonReturn else {  // cancelled
                // flush swipe action for in case if this deletion was invoked by swiping the style name
                self.syntaxTableView?.rowActionsVisible = false
                return
            }
            
            do {
                try SyntaxManager.shared.removeSetting(name: name)
                
            } catch {
                alert.window.orderOut(nil)
                NSSound.beep()
                NSAlert(error: error).beginSheetModal(for: window)
                return
            }
            
            AudioServicesPlaySystemSound(.moveToTrash)
        }
    }
    
    
    /// try to restore given syntax style
    private func restoreSyntaxStyle(name: String) {
        
        do {
            try SyntaxManager.shared.restoreSetting(name: name)
        } catch {
            self.presentError(error)
        }
    }
    
    
    /// try to import syntax style file at given URL
    private func importSyntaxStyle(fileURL: URL) {
        
        do {
            if fileURL.pathExtension == "plist" {
                try SyntaxManager.shared.importLegacyStyle(fileURL: fileURL)
            } else {
                try SyntaxManager.shared.importSetting(fileURL: fileURL)
            }
        } catch {
            // ask for overwriting if a setting with the same name already exists
            self.presentError(error)
        }
    }
    
}
