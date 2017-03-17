/*
 
 BatchReplacementListViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-03-17.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
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

final class BatchReplacementListViewController: NSViewController {
    
    @IBOutlet private weak var tableView: NSTableView?
    
    private var mainViewController: NSViewController? {
        
        return (self.parent as? BatchReplacementSplitViewController)?.mainViewController
    }
    
    
    
    // MARK: Action Messages
    
    /// add setting
    @IBAction func addSetting(_ sender: Any?) {
        
        guard let tableView = self.tableView else { return }
        
        ReplacementManager.shared.createUntitledSetting { (settingName: String, error: Error?) in
            let settingNames = ReplacementManager.shared.settingNames
            let row = settingNames.index(of: settingName) ?? 0
            
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }
    
    
    /// duplicate selected setting
    @IBAction func duplicateSetting(_ sender: Any?) {
        
        guard let settingName = self.targetSettingName(for: sender) else { return }
        
        try? ReplacementManager.shared.duplicateSetting(name: settingName)
    }
    
    
    /// rename selected setting
    @IBAction func renameSetting(_ sender: Any?) {
        
        guard
            let settingName = self.targetSettingName(for: sender),
            let row = ReplacementManager.shared.settingNames.index(of: settingName)
            else { return }
        
        self.tableView?.editColumn(0, row: row, with: nil, select: false)
    }
    
    
    /// remove selected setting
    @IBAction func deleteSetting(_ sender: Any?) {
        
        guard let settingName = self.targetSettingName(for: sender) else { return }
        
        self.deleteSetting(name: settingName)
    }
    
    
    /// export selected setting
    @IBAction func exportSetting(_ sender: Any?) {
        
        guard let settingName = self.targetSettingName(for: sender) else { return }
       
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.nameFieldLabel = NSLocalizedString("Export As:", comment: "")
        savePanel.nameFieldStringValue = settingName
        savePanel.allowedFileTypes = []
        
        savePanel.beginSheetModal(for: self.view.window!) { (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            try? ReplacementManager.shared.exportSetting(name: settingName, to: savePanel.url!)
        }
    }
    
    
    /// import a setting file
    @IBAction func importSetting(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = NSLocalizedString("Import", comment: "")
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = [ReplacementManager.shared.filePathExtension]
        
        openPanel.beginSheetModal(for: self.view.window!) { [weak self] (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            self?.importSetting(fileURL: openPanel.url!)
        }
    }
    
    
    /// open directory in Application Support in Finder where the selected setting exists
    @IBAction func revealSettingInFinder(_ sender: Any?) {
        
        guard
            let settingName = self.targetSettingName(for: sender),
            let url = ReplacementManager.shared.urlForUserSetting(name: settingName)
            else { return }
        
        NSWorkspace.shared().activateFileViewerSelecting([url])
    }
    
    
    /// reload all setting files in Application Support
    @IBAction func reloadAllSettings(_ sender: Any?) {
        
        ReplacementManager.shared.updateCache()
    }
    
    
    
    // MARK: Private Methods
    
    /// return theme name which is currently selected in the list table
    private dynamic var selectedSettingName: String? {
        
        let index = self.tableView?.selectedRow ?? 0
        
        return ReplacementManager.shared.settingNames[safe: index]
    }
    
    
    /// return representedObject if sender is menu item, otherwise selection in the list table
    private func targetSettingName(for sender: Any?) -> String? {
        
        if let menuItem = sender as? NSMenuItem {
            return menuItem.representedObject as? String
        }
        return self.selectedSettingName
    }
    
    
    /// try to delete given setting
    private func deleteSetting(name: String) {
        
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("Are you sure you want to delete “%@”?", comment: ""), name)
        alert.informativeText = NSLocalizedString("This action cannot be undone.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        
        let window = self.view.window!
        alert.beginSheetModal(for: window) { (returnCode: NSModalResponse) in
            
            guard returnCode == NSAlertSecondButtonReturn else { return }  // cancelled
            
            do {
                try ReplacementManager.shared.removeSetting(name: name)
                
            } catch {
                alert.window.orderOut(nil)
                NSBeep()
                NSAlert(error: error).beginSheetModal(for: window)
                return
            }
            
            AudioServicesPlaySystemSound(.moveToTrash)
        }
    }
    
    
    /// try to import setting file at given URL
    private func importSetting(fileURL: URL) {
        
        do {
            try ReplacementManager.shared.importSetting(fileURL: fileURL)
        } catch {
            // ask for overwriting if a setting with the same name already exists
            self.presentError(error)
        }
    }
    
}
