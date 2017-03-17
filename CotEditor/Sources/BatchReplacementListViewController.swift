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

final class BatchReplacementListViewController: NSViewController {
    
    @IBOutlet private weak var tableView: NSTableView?
    
    private var mainViewController: NSViewController? {
        
        return (self.parent as? BatchReplacementSplitViewController)?.mainViewController
    }
    
    
    
    // MARK: Action Messages
    
    /// add setting
    @IBAction func addSetting(_ sender: Any?) {
        
    }
    
    
    /// duplicate selected setting
    @IBAction func duplicateSetting(_ sender: Any?) {
        
    }
    
    
    /// remove selected setting
    @IBAction func removeSetting(_ sender: Any?) {
        
    }
    
    
    /// export selected setting
    @IBAction func exportSetting(_ sender: Any?) {
       
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.nameFieldLabel = NSLocalizedString("Export As:", comment: "")
        savePanel.nameFieldStringValue = ""
        savePanel.allowedFileTypes = []
        
        savePanel.beginSheetModal(for: self.view.window!) { (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
        }
    }
    
    
    /// import a setting file
    @IBAction func importSetting(_ sender: Any?) {
        
        let openPanel = NSOpenPanel()
        openPanel.prompt = NSLocalizedString("Import", comment: "")
        openPanel.resolvesAliases = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = []
        
        openPanel.beginSheetModal(for: self.view.window!) { (result: Int) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
        }
    }
    
    
    /// open directory in Application Support in Finder where the selected setting exists
    @IBAction func revealSettingInFinder(_ sender: Any?) {
        
    }
    
    
    /// reload all setting files in Application Support
    @IBAction func reloadAllSettings(_ sender: Any?) {
        
    }
    
}
