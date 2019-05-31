//
//  StatableMenuToolbarItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-06-18.
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

final class StatableMenuToolbarItem: StatableToolbarItem {

    @IBOutlet private weak var segmentMenu: NSMenu?
    
    
    
    // MARK: -
    // MARK: Toolbar Item Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        let segmentedControl = self.segmentedControl!
        
        // set menu to the last segment
        if #available(macOS 10.13, *) {
            segmentedControl.setShowsMenuIndicator(true, forSegment: 1)
            segmentedControl.setMenu(self.segmentMenu, forSegment: 1)
        } else {
            // use normal button if the menu indicator is not supported
            let image = segmentedControl.image(forSegment: 0)!
            let button = NSButton(title: "", image: image, target: self.target, action: self.action)
            button.frame.size = NSSize(width: 38, height: 24)
            button.bezelStyle = .texturedRounded
            self.view = button
            self.minSize.width = 44
            self.maxSize.width = 44
        }
        
        // set menu for "Text Only" mode
        let item = NSMenuItem()
        item.title = self.label
        item.action = segmentedControl.action
        
        self.menuFormRepresentation = item
    }
    
    
    override var image: NSImage? {
        
        get {
            if #available(macOS 10.13, *) { } else {
                return (self.control as? NSButton)?.image
            }
            
            return self.segmentedControl?.image(forSegment: 0)
        }
        
        set {
            if #available(macOS 10.13, *) { } else {
                (self.control as? NSButton)?.image = newValue
            }
            
            self.segmentedControl?.setImage(newValue, forSegment: 0)
        }
    }
    
    
    
    // MARK: Private Methods
    
    private var segmentedControl: NSSegmentedControl? {
        
        return self.view as? NSSegmentedControl
    }
    
}



final class DropdownSegmentedControlCell: NSSegmentedCell {
    
    // MARK: Segmented Cell Methods
    
    /// return `nil` for the last segment to popup context menu immediately when user clicked
    override var action: Selector? {
        
        get {
            guard self.menu(forSegment: self.selectedSegment) == nil else { return nil }
            
            return super.action
        }
        
        set {
            super.action = newValue
        }
    }
    
}
