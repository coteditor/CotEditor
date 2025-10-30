//
//  SettingsWindow.swift
//  ControlUI
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2025 1024jp
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

final class SettingsWindow: NSWindow {
    
    // MARK: Window Methods
    
    override var canBecomeMain: Bool {
        
        if #available(macOS 26, *) {
            true  // workaround ShareLink issue (2025-08, macOS 26, FB19287270)
        } else {
            false
        }
    }
    
    
    override func cancelOperation(_ sender: Any?) {
    
        self.close()
    }
    
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        switch menuItem.action {
            case #selector(toggleToolbarShown):
                return false
                
            default:
                return super.validateMenuItem(menuItem)
        }
    }
}
