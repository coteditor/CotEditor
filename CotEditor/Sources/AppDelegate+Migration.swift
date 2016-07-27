/*
 
 AppDelegate+Migration.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-23.
 
 ------------------------------------------------------------------------------
 
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

extension AppDelegate {
    
    // MARK: Public Methods
    
    /// migrate user settings from CotEditor v1.x if needed
    func migrateIfNeeded() {
        
        let lastVersion = UserDefaults.standard.string(forKey: DefaultKey.lastVersion)
        let keybindingURL = MenuKeyBindingManager.shared.userSettingDirectoryURL
        let existsKeybindingDir = keybindingURL.isReachable  // KeyBindings dir was invariably made on the previous versions.
        
        if lastVersion == nil && existsKeybindingDir {
            self.migrateToVersion2()
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// perform migration from CotEditor 1.x to 2.0
    private func migrateToVersion2() {
        
        // show migration window
        let windowController = MigrationWindowController()
        self.migrationWindowController = windowController
        windowController.showWindow(self)
        
        // reset menu keybindings setting
        windowController.update(informative: "Restoring menu key bindings settings…")
        windowController.didResetKeyBindings = MenuKeyBindingManager.shared.resetKeyBindings()
        windowController.progressIndicator()
        
        // migrate coloring setting
        windowController.update(informative: "Migrating coloring settings…")
        windowController.didMigrateTheme = ThemeManager.shared.migrateTheme()
        windowController.progressIndicator()
        
        // migrate syntax styles to modern style
        windowController.update(informative: "Migrating user syntax settings…")
        CESyntaxManager.shared().migrateStyles { success in
            windowController.didMigrateSyntaxStyles = success
            
            windowController.update(informative: "Migration finished.")
            windowController.finishMigration()
        }
    }
    
}
