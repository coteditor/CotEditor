//
//  NSToolbarItem+Validatable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

protocol Validatable: AnyObject { }


extension Validatable where Self: NSToolbarItem {
    
    func validate() -> Bool {
        
        guard
            let validator = self.target
                ?? self.action.flatMap({ NSApp.target(forAction: $0, to: self.target, from: self) }) as AnyObject?
        else { return false }
        
        switch validator {
            case let validator as NSToolbarItemValidation:
                return validator.validateToolbarItem(self)
            case let validator as NSUserInterfaceValidations:
                return validator.validateUserInterfaceItem(self)
            default:
                return true
        }
    }
}


// MARK: -

final class MenuToolbarItem: NSMenuToolbarItem, Validatable {
    
    override func validate() {
        
        self.isEnabled = self.validate()
    }
}


final class ToolbarItemGroup: NSToolbarItemGroup, Validatable {
    
    override func validate() {
        
        self.isEnabled = self.validate()
    }
}
