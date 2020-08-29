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

final class StatableMenuToolbarItem: NSToolbarItem, StatableItem, Validatable {
    
    // MARK: Public Properties
    
    var state: NSControl.StateValue = .on  { didSet { self.invalidateImage() } }
    var stateImages: [NSControl.StateValue: NSImage] = [:]  { didSet { self.invalidateImage() } }
    
    
    // MARK: Private Properties
    
    private let segmentedControl: NSSegmentedControl
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init(itemIdentifier: NSToolbarItem.Identifier) {
        
        self.segmentedControl = DropdownSegmentedControl()
        self.segmentedControl.trackingMode = .momentary
        self.segmentedControl.segmentCount = 2
        self.segmentedControl.setShowsMenuIndicator(true, forSegment: 1)
        self.segmentedControl.setWidth(15, forSegment: 1)
        
        super.init(itemIdentifier: itemIdentifier)
        
        self.view = self.segmentedControl
        self.menuFormRepresentation = NSMenuItem()
    }
    
    
    
    // MARK: Toolbar Item Methods
    
    override func validate() {
        
        self.segmentedControl.isEnabled = self.validate()
    }
    
    
    override var image: NSImage? {
        
        get { self.segmentedControl.image(forSegment: 0) }
        set { self.segmentedControl.setImage(newValue, forSegment: 0) }
    }
    
    
    override var label: String {
        
        didSet {
            self.menuFormRepresentation?.title = label
        }
    }
    
    
    override var action: Selector? {
        
        didSet {
            self.segmentedControl.action = action
            self.menuFormRepresentation?.action = action
        }
    }
    
    
    
    // MARK: Public Methods
    
    var menu: NSMenu? {
        
        get { self.segmentedControl.menu(forSegment: 1) }
        set { self.segmentedControl.setMenu(newValue, forSegment: 1) }
    }
    
    
    
    // MARK: Private Methods
    
    private func invalidateImage() {
        
        assert(self.state != .mixed)
        
        self.image = self.stateImages[self.state]
        self.menuFormRepresentation?.image = self.image
    }
    
}



final private class DropdownSegmentedControl: NSSegmentedControl {
    
    // MARK: Segmented Control Methods
    
    override class var cellClass: AnyClass? {
        
        get { DropdownSegmentedControlCell.self }
        set { _ = newValue }
    }
    
}



final private class DropdownSegmentedControlCell: NSSegmentedCell {
    
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
