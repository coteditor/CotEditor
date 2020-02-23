//
//  ControlToolbarItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-06-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

class ControlToolbarItem: NSToolbarItem {
    
    // MARK: Toolbar Item Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // set menu for "Text Only" mode
        let item = NSMenuItem()
        item.title = self.label
        item.action = self.action
        item.target = self.target
        
        self.menuFormRepresentation = item
    }
    
    
    /// validate state of item
    override func validate() {
        
        self.control?.isEnabled = {
            guard
                let action = self.action,
                let validator = NSApp.target(forAction: action, to: self.target, from: self) as AnyObject?
                else { return false }
            
            switch validator {
                case let validator as NSToolbarItemValidation:
                    return validator.validateToolbarItem(self)
                case let validator as NSUserInterfaceValidations:
                    return validator.validateUserInterfaceItem(self)
                default:
                    return true
            }
        }()
    }
    
    
    
    // MARK: Public Methods
    
    final var control: NSControl? {
        
        return self.view as? NSControl
    }
    
}
