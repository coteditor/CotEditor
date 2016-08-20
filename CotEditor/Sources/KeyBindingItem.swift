/*
 
 KeyBindingItem.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-22.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

import Foundation
import AppKit.NSTreeNode

final class KeyBindingItem: NSObject {
    
    // MARK: Public Properties
    
    let selector: String
    var keySpecChars: String?
    let defaultShortcut: Shortcut
    
    /// printable representation of the shortcut key
    var printableKey: String? {
        
        guard let keySpecChars = self.keySpecChars else { return nil }
        
        return Shortcut(keySpecChars: keySpecChars).description
    }
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init(selector: String, keySpecChars: String?, defaultShortcut: Shortcut) {
        
        self.selector = selector
        self.keySpecChars = keySpecChars
        self.defaultShortcut = defaultShortcut
        
        super.init()
    }
    
}




// MARK:

final class NamedTreeNode: NSTreeNode {
    
    // MARK: Public Properties
    
    let name: String
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init(name: String, representedObject: Any?) {
        
        self.name = name
        
        super.init(representedObject: representedObject)
    }
    
}
