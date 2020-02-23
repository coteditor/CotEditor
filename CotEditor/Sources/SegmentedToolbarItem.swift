//
//  SegmentedToolbarItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-06-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2019 1024jp
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

final class SegmentedToolbarItem: ControlToolbarItem {
    
    // MARK: Private Properties
    
    @IBOutlet private var menu: NSMenu?
    
    
    
    // MARK: -
    // MARK: Toolbar Item Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // set menu for "Text Only" mode
        let item = NSMenuItem()
        item.title = self.label
        item.submenu = self.menu
        
        self.menuFormRepresentation = item
    }
    
    
    /// validate each segmented action using corresponding menu items
    override func validate() {
        
        super.validate()
        
        guard
            let segmentedControl = self.segmentedControl,
            let menu = self.menuFormRepresentation?.submenu
            else { return }
        
        for (segment, item) in menu.items.enumerated() {
            guard
                let action = item.action,
                let validator = NSApp.target(forAction: action, to: item.target, from: item) as AnyObject?
                else { continue }
            
            let isValid: Bool = {
                switch validator {
                case let validator as NSUserInterfaceValidations:
                    return validator.validateUserInterfaceItem(item)
                default:
                    return validator.validateMenuItem(item)
                }
            }()
            
            segmentedControl.setEnabled(isValid, forSegment: segment)
        }
    }
    
    
    
    // MARK: Public Methods
    
    var segmentedControl: NSSegmentedControl? {
        
        return self.view as? NSSegmentedControl
    }
    
}
