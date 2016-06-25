/*
 
 FormatPaneController.swift
 
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

/// keys for styles controller
private enum StyleKey: String {
    case name
    case state
}

private let IsUTF8WithBOM = "UTF-8 with BOM"


class FormatPaneController: NSViewController, NSTableViewDelegate {

    // MARK: Private Properties
    
    @IBOutlet private weak var inOpenEncodingMenu: NSPopUpButton?
    @IBOutlet private weak var inNewEncodingMenu: NSPopUpButton?
    
    @IBOutlet private weak var stylesController: NSArrayController?
    @IBOutlet private weak var syntaxTableView: NSTableView?
    @IBOutlet private weak var syntaxTableMenu: NSMenu?
    @IBOutlet private weak var syntaxStylesDefaultPopup: NSPopUpButton?
    @IBOutlet private weak var syntaxStyleDeleteButton: NSButton?
    
    
    
    // MARK:
    // MARK: Creation
    
    deinit {
        NotificationCenter.default().removeObserver(self)
    }
    
    
    
    // MARK: View Controller Methods
    
    /// nib name
    override var nibName: String? {
        
        return "FormatPane"
    }
    
    
    // setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.syntaxTableView?.doubleAction = #selector(openSyntaxEditSheet)
        self.syntaxTableView?.target = self
        
        self.setupEncodingMenus()
        self.setupSyntaxStyleMenus()
        
        NotificationCenter.default().addObserver(self, selector: #selector(setupEncodingMenus), name: .CEEncodingListDidUpdate, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(setupSyntaxStyleMenus), name: .CESyntaxListDidUpdate, object: nil)
    }
    
    
    /// apply current state to menu items
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        let isContextualMenu = (menuItem.menu == self.syntaxTableMenu)
        
        var representedStyleName: String? = self.selectedStyleName
        if (isContextualMenu) {
            let clickedRow = self.syntaxTableView?.clickedRow ?? -1
            
            if clickedRow == -1 {  // clicked blank area
                representedStyleName = nil
            } else {
                representedStyleName = self.stylesController!.arrangedObjects[clickedRow][StyleKey.name.rawValue] as? String
            }
        }
        // set style name as representedObject to menu items whose action is related to syntax style
        if NSStringFromSelector(menuItem.action!).contains("Syntax") {
            menuItem.representedObject = representedStyleName
        }
        
        var isCustomized: ObjCBool = false
        var isBundled = false
        if let representedStyleName = representedStyleName {
            isBundled = CESyntaxManager.shared().isBundledSetting(representedStyleName, cutomized: &isCustomized)
        }
        
        guard let action = menuItem.action else { return false }
        
        // append targeet style name to menu titles
        switch action {
        case #selector(openSyntaxMappingConflictSheet(_:)):
            return CESyntaxManager.shared().existsMappingConflict()
            
        case #selector(openSyntaxEditSheet(_:)) where SyntaxEditSheetMode(rawValue: menuItem.tag) == .copy:
            if !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Duplicate “%@”", comment: ""), representedStyleName!)
            }
            menuItem.isHidden = (representedStyleName == nil)
            
        case #selector(deleteSyntaxStyle(_:)):
            menuItem.isHidden = (isBundled || representedStyleName == nil)
            
        case #selector(restoreSyntaxStyle(_:)):
            if !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Restore “%@”", comment: ""), representedStyleName!)
            }
            menuItem.isHidden = (!isBundled || representedStyleName == nil)
            return isCustomized.boolValue
            
        case #selector(exportSyntaxStyle(_:)):
            if !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Export “%@”…", comment: ""), representedStyleName!)
            }
            menuItem.isHidden = (representedStyleName == nil)
            return (!isBundled || isCustomized)
            
        case #selector(revealSyntaxStyleInFinder(_:)):
            if !isContextualMenu {
                menuItem.title = String(format: NSLocalizedString("Reveal “%@” in Finder", comment: ""), representedStyleName!)
            }
            return (!isBundled || isCustomized)
            
        default: break
        }
        
        return true
    }
        
    
    
    
    // MARK: Delegate
    
    /// selected syntax style in "Installed styles" list table did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let object = notification.object as? NSTableView where object == self.syntaxTableView else { return }
        
        self.validateRemoveSyntaxStyleButton()
    }
    
    
    /// set action on swiping style name
    @available(OSX 10.11, *)
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        
        guard edge == .trailing else { return [] }
        
        // get swiped style
        let styleName = self.stylesController!.arrangedObjects[row][StyleKey.name.rawValue] as! String
        
        // check whether style is deletable
        var isCustomized: ObjCBool = false
        let isBundled = CESyntaxManager.shared().isBundledSetting(styleName, cutomized: &isCustomized)
        
        // do nothing on undeletable style
        guard !isBundled || isCustomized else { return [] }
        
        if isCustomized {
            // Restore
            return [NSTableViewRowAction(style: .regular,
                                         title: NSLocalizedString("Restore", comment: ""),
                                         handler: { [weak self] (action: NSTableViewRowAction, row: Int) in
                                            self?.restoreSyntaxStyle(name: styleName)
                                            
                                            // finish swiped mode anyway
                                            tableView.rowActionsVisible = false
                })]
            
        } else {
            // Delete
            return [NSTableViewRowAction(style: .destructive,
                                         title: NSLocalizedString("Delete", comment: ""),
                                         handler: { [weak self] (action: NSTableViewRowAction, row: Int) in
                                            self?.deleteSyntaxStyle(name: styleName)
                })]
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// save also availability of UTF-8 BOM
    @IBAction func changeEncodingInNewDocument(_ sender: AnyObject?) {
        
        let withUTF8BOM = (self.inNewEncodingMenu?.selectedItem?.representedObject as? String) == IsUTF8WithBOM
        
        UserDefaults.standard().set(withUTF8BOM, forKey: CEDefaultSaveUTF8BOMKey)
    }
    
    
    /// recommend user to use "Auto-Detect" on changing encoding setting
    @IBAction func checkSelectedItemOfInOpenEncodingMenu(_ sender: AnyObject?) {
        
        guard let newTitle = self.inOpenEncodingMenu?.selectedItem?.title where newTitle != NSLocalizedString("Auto-Detect", comment: "") else { return }
        
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("Are you sure you want to change to “%@”?", comment: ""), newTitle)
        alert.informativeText = NSLocalizedString("The default “Auto-Detect” is recommended for most cases.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Revert to “Auto-Detect”", comment: ""))
        alert.addButton(withTitle: String(format: NSLocalizedString("Change to “%@”", comment: ""), newTitle))
        
        alert.beginSheetModal(for: self.view.window!) { (returnCode: NSModalResponse) in
            
            guard returnCode == NSAlertFirstButtonReturn else { return }
            
            UserDefaults.standard().set(CEAutoDetectEncoding, forKey: CEDefaultEncodingInOpenKey)
        }
    }
    
    
    /// show encoding list edit sheet
    @IBAction func openEncodingEditSheet(_ sender: AnyObject?) {
        
        self.presentViewControllerAsSheet(EncodingListViewController())
    }
    
    
    /// show syntax mapping conflict error sheet
    @IBAction func openSyntaxMappingConflictSheet(_ sender: AnyObject?) {
        
        self.presentViewControllerAsSheet(SyntaxMappingConflictsViewController())
    }
    
    
    /// show syntax style edit sheet
    @IBAction func openSyntaxEditSheet(_ sender: AnyObject?) {
        
        let styleName = self.targetStyleName(for: sender)
        let mode = SyntaxEditSheetMode(rawValue: sender?.tag ?? 0) ?? .edit
        
        guard let viewController = SyntaxEditViewController(style: styleName, mode: mode) else { return }
        
        self.presentViewControllerAsSheet(viewController)
    }
    
    
    /// delete selected syntax style
    @IBAction func deleteSyntaxStyle(_ sender: AnyObject?) {
        
        let styleName = self.targetStyleName(for: sender)
        
        self.deleteSyntaxStyle(name: styleName)
    }
    
    
    /// restore selected syntax style to original bundled one
    @IBAction func restoreSyntaxStyle(_ sender: AnyObject?) {
        
        let styleName = self.targetStyleName(for: sender)
        
        self.restoreSyntaxStyle(name: styleName)
    }
    
    
    /// export selected syntax style
    @IBAction func exportSyntaxStyle(_ sender: AnyObject?) {
        
        let styleName = self.targetStyleName(for: sender)
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.nameFieldLabel = NSLocalizedString("Export As:", comment: "")
        savePanel.nameFieldStringValue = styleName
        savePanel.allowedFileTypes = [CESyntaxManager.shared().filePathExtension()]
        
        savePanel.beginSheetModal(for: self.view.window!) { (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            _ = try? CESyntaxManager.shared().exportSetting(withName: styleName, to: savePanel.url!)
        }
    }
    
    
    /// import syntax style file via open panel
    @IBAction func importSyntaxStyle(_ sender: AnyObject?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = NSLocalizedString("", comment: "")
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = [CESyntaxManager.shared().filePathExtension(), "plist"]
        
        openPanel.beginSheetModal(for: self.view.window!) { [weak self] (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            self?.importSyntaxStyle(fileURL: openPanel.url!)
        }
    }
    
    
    /// open directory in Application Support in Finder where the selected style exists
    @IBAction func revealSyntaxStyleInFinder(_ sender: AnyObject?) {
        
        let styleName = self.targetStyleName(for: sender)
        
        guard let url = CESyntaxManager.shared().urlForUserSetting(withName: styleName) else { return }
        
        NSWorkspace.shared().activateFileViewerSelecting([url])
    }
    
    
    
    // MARK: Private Methods
    
    /// build encodings menus
    func setupEncodingMenus() {
        
        guard let inOpenMenu = self.inOpenEncodingMenu?.menu,
            let inNewMenu = self.inNewEncodingMenu?.menu else { return }
        
        let menuItems = CEEncodingManager.shared().encodingMenuItems
        
        inOpenMenu.removeAllItems()
        inNewMenu.removeAllItems()
        
        let autoDetectItem = NSMenuItem(title: NSLocalizedString("Auto-Detect", comment: ""), action: nil, keyEquivalent: "")
        autoDetectItem.tag = CEAutoDetectEncoding
        inOpenMenu.addItem(autoDetectItem)
        inOpenMenu.addItem(NSMenuItem.separator())
        
        let UTF8Int = Int(String.Encoding.utf8.rawValue)
        for item in menuItems {
            inOpenMenu.addItem(item.copy() as! NSMenuItem)
            inNewMenu.addItem(item.copy() as! NSMenuItem)
            
            // add "UTF-8 with BOM" item only to "In New" menu
            if item.tag == UTF8Int {
                let bomItem = NSMenuItem(title: NSString.localizedNameOfUTF8EncodingWithBOM(), action: nil, keyEquivalent: "")
                bomItem.tag = UTF8Int
                bomItem.representedObject = IsUTF8WithBOM
                inNewMenu.addItem(bomItem)
            }
        }
        
        // select menu item for the current setting manually although Cocoa-Bindings are used on these menus
        //   -> Because items were actually added after Cocoa-Binding selected the item.
        let inOpenEncoding = UserDefaults.standard().integer(forKey: CEDefaultEncodingInOpenKey)
        let inNewEncoding = UserDefaults.standard().integer(forKey: CEDefaultEncodingInNewKey)
        self.inOpenEncodingMenu?.selectItem(withTag: inOpenEncoding)
        
        if (inNewEncoding == UTF8Int) {
            var index = inNewMenu.indexOfItem(withRepresentedObject: IsUTF8WithBOM)
            
            // -> The normal "UTF-8" is just above "UTF-8 with BOM".
            if !UserDefaults.standard().bool(forKey: CEDefaultSaveUTF8BOMKey) {
                index -= 1
            }
            self.inNewEncodingMenu?.selectItem(at: index)
        } else {
            self.inNewEncodingMenu?.selectItem(withTag: inNewEncoding)
        }
    }
    
    
    /// build sytnax style menus
    func setupSyntaxStyleMenus() {
        
        let styleNames = CESyntaxManager.shared().styleNames
        let noneStyle = NSLocalizedString("None", comment: "")
        
        var hoge = [[String: AnyObject]]()
        for styleName in styleNames {
            var isCustomized: ObjCBool = false
            let isBundled = CESyntaxManager.shared().isBundledSetting(styleName, cutomized: &isCustomized)
            
            hoge.append([StyleKey.name.rawValue: styleName,
                         StyleKey.state.rawValue: (!isBundled || isCustomized)])
        }
        
        // update installed style list table
        self.stylesController?.content = hoge
        self.validateRemoveSyntaxStyleButton()
        self.syntaxTableView?.reloadData()
        
        // update default style popup menu
        if let popup = self.syntaxStylesDefaultPopup {
            popup.removeAllItems()
            popup.addItem(withTitle: noneStyle)
            popup.menu?.addItem(NSMenuItem.separator())
            popup.addItems(withTitles: styleNames)
            
            // select menu item for the current setting manually although Cocoa-Bindings are used on this menu
            //   -> Because items were actually added after Cocoa-Binding selected the item.
            var selectedStyle = UserDefaults.standard().string(forKey: CEDefaultSyntaxStyleKey)!
            if !styleNames.contains(selectedStyle) {
                selectedStyle = noneStyle
            }
            popup.selectItem(withTitle: selectedStyle)
        }
    }
    
    
    /// return syntax style name which is currently selected in the list table
    private dynamic var selectedStyleName: String {
        
        guard let stylesController = self.stylesController?.selectedObjects.first as? [String: AnyObject] else {
            return UserDefaults.standard().string(forKey: CEDefaultSyntaxStyleKey)!
        }
        return stylesController[StyleKey.name.rawValue] as! String
    }
    
    
    /// return representedObject if sender is menu item, otherwise selection in the list table
    private func targetStyleName(for sender: AnyObject?) -> String {
        
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as! String
        }
        return self.selectedStyleName
    }
    
    
    /// update button that deletes syntax style
    private func validateRemoveSyntaxStyleButton() {
        
        let isDeletable = CESyntaxManager.shared().isBundledSetting(self.selectedStyleName, cutomized: nil)
        
        self.syntaxStyleDeleteButton?.isEnabled = isDeletable
    }
    
    
    /// try to delete given syntax style
    private func deleteSyntaxStyle(name: String) {
        
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("Are you sure you want to delete “%@” syntax style?", comment: ""), name)
        alert.informativeText = NSLocalizedString("This action cannot be undone.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        
        let window = self.view.window!
        alert.beginSheetModal(for: window) { (returnCode: NSModalResponse) in
            
            guard returnCode == NSAlertSecondButtonReturn else {  // cancelled
                // flush swipe action for in case if this deletion was invoked by swiping the style name
                if #available(OSX 10.11, *) {
                    self.syntaxTableView?.rowActionsVisible = false
                }
                return
            }
            
            do {
                try CESyntaxManager.shared().removeSetting(withName: name)
                
            } catch let error as NSError {
                alert.window.orderOut(nil)
                NSBeep()
                NSAlert(error: error).beginSheetModal(for: window, completionHandler: nil)
                return
            }
            
            AudioServicesPlaySystemSound(.moveToTrash)
        }
    }
    
    
    /// try to restore given syntax style
    private func restoreSyntaxStyle(name: String) {
        
        do {
            try CESyntaxManager.shared().restoreSetting(withName: name)
        } catch let error as NSError {
            self.presentError(error)
        }
        
    }
    
    
    /// try to import syntax style file at given URL
    private func importSyntaxStyle(fileURL: URL) {
        
        do {
            try CESyntaxManager.shared().importSetting(withFileURL: fileURL)
        } catch let error as NSError {
            // ask for overwriting if a setting with the same name already exists
            self.presentError(error)
        }
        
    }
}
