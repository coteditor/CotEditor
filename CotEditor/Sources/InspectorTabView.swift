//
//  InspectorTabView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-31.
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

import Cocoa

final class InspectorTabView: NSTabView {
    
    // MARK: Public Properties
    
    let segmentedControl = NSSegmentedControl()
    
    
    // MARK: Private Properties
    
    private let controlHeight: CGFloat = 28.0
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        self.tabViewType = .noTabsNoBorder
        
        // setup segmented control
        self.segmentedControl.cell = SwitcherSegmentedCell()
        self.segmentedControl.segmentStyle = .texturedSquare
        self.segmentedControl.frame.origin.y = floor((self.controlHeight - self.segmentedControl.intrinsicContentSize.height) / 2)
        self.addSubview(self.segmentedControl)
        
        self.rebuildSegmentedControl()
    }
    
    
    
    // MARK: Tab View Methods
    
    /// take off control space
    override var contentRect: NSRect {
        
        var rect = self.bounds
        rect.origin.y = self.controlHeight + 1  // +1 for border
        rect.size.height -= self.controlHeight + 1
        
        return rect
    }
    
    
    /// reposition control manually
    override var frame: NSRect {
        
        didSet {
            self.invalidateControlPosition()
        }
    }
    
    
    /// draw border below control
    override func draw(_ dirtyRect: NSRect) {
        
        NSGraphicsContext.saveGraphicsState()
        
        // draw background
        if self.drawsBackground {
            NSColor.windowBackgroundColor.setFill()
            dirtyRect.fill()
            
        } else {
            super.draw(dirtyRect)
        }
        
        let strokeRect = NSRect(x: dirtyRect.minX, y: self.controlHeight, width: dirtyRect.width, height: 1)
        NSColor.gridColor.setFill()
        strokeRect.fill()
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    /// select also the private control
    override func selectTabViewItem(at index: Int) {
        
        super.selectTabViewItem(at: index)
        self.invalidateControlSelection()
    }
    
    
    /// select also the private control
    override func addTabViewItem(_ tabViewItem: NSTabViewItem) {
        
        super.addTabViewItem(tabViewItem)
        self.invalidateControlSelection()
    }
    
    
    /// update the private control
    override func insertTabViewItem(_ tabViewItem: NSTabViewItem, at index: Int) {
        
        super.insertTabViewItem(tabViewItem, at: index)
        self.rebuildSegmentedControl()
    }
    
    
    /// update the private control
    override func removeTabViewItem(_ tabViewItem: NSTabViewItem) {
        
        super.removeTabViewItem(tabViewItem)
        self.rebuildSegmentedControl()
    }
    
    
    
    // MARK: Private Methods
    
    /// update selection of the private control
    private func invalidateControlSelection() {
        
        guard let selectedItem = self.selectedTabViewItem else { return }
        
        let index = self.indexOfTabViewItem(selectedItem)
        
        guard index != NSNotFound else { return }
        
        guard self.numberOfTabViewItems == self.segmentedControl.segmentCount else {
            return self.rebuildSegmentedControl()  // This method will be invoked again in `rebuildSegmentedControl`.
        }
        
        self.segmentedControl.selectedSegment = index
    }
    
    
    /// update private control position
    private func invalidateControlPosition() {
        
        self.segmentedControl.frame.origin.x = floor((self.frame.width - self.segmentedControl.frame.width) / 2)
    }
    
    
    /// update the private control every time when tab item line-up changed
    private func rebuildSegmentedControl() {
        
        self.segmentedControl.segmentCount = self.numberOfTabViewItems
        
        // set tabViewItem values to control buttons
        for (index, item) in self.tabViewItems.enumerated() {
            self.segmentedControl.setImage(item.image, forSegment: index)
            (self.segmentedControl.cell as! NSSegmentedCell).setToolTip(item.label.localized, forSegment: index)
        }
        
        self.segmentedControl.sizeToFit()
        self.invalidateControlPosition()
        self.invalidateControlSelection()
    }
    
}
