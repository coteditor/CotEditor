//
//  KeyBindingItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

import struct Foundation.Selector
import AppKit.NSTreeNode

final class KeyBindingItem {
    
    // MARK: Public Properties
    
    let action: Selector
    var shortcut: Shortcut?
    let defaultShortcut: Shortcut
    
    
    init(action: Selector, shortcut: Shortcut?, defaultShortcut: Shortcut) {
        
        self.action = action
        self.shortcut = shortcut
        self.defaultShortcut = defaultShortcut
    }
    
}



// MARK: -

final class NamedTreeNode: NSTreeNode {
    
    // MARK: Public Properties
    
    let name: String
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(name: String, representedObject: Any? = nil) {
        
        self.name = name
        
        super.init(representedObject: representedObject)
    }
    
}
