//
//  NSValidatedUserInterfaceItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2020 1024jp
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

protocol StatableItem: AnyObject {
    
    var state: NSControl.StateValue { get set }
}

extension NSMenuItem: StatableItem { }



extension NSValidatedUserInterfaceItem {
    
    var toolTip: String? {
        
        get {
            switch self {
                case let item as NSMenuItem:
                    return item.toolTip
                case let item as NSToolbarItem:
                    return item.toolTip
                case let item as NSCustomTouchBarItem:
                    return item.toolTip
                default:
                    // -> Only NSMenuItem and NSToolbarItem inherit NSValidatedUserInterfaceItem.
                    preconditionFailure()
            }
        }
        
        set {
            switch self {
                case let item as NSMenuItem:
                    item.toolTip = newValue
                case let item as NSToolbarItem:
                    item.toolTip = newValue
                case let item as NSCustomTouchBarItem:
                    item.toolTip = newValue
                default:
                    preconditionFailure()
            }
        }
    }
    
}
