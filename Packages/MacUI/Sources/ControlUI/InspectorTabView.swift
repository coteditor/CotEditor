//
//  InspectorTabView.swift
//  InspectorTabView
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-31.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2025 1024jp
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

public import AppKit

public final class InspectorTabView: NSTabView {
    
    // MARK: Private Properties
    
    private let segmentedControl: NSSegmentedControl
    
    
    // MARK: Lifecycle
    
    public override init(frame frameRect: NSRect) {
        
        self.segmentedControl = NSSegmentedControl()
        self.segmentedControl.controlSize = .large
        self.segmentedControl.selectedSegment = 1
        
        super.init(frame: frameRect)
        
        self.wantsLayer = true
        self.tabViewType = .noTabsNoBorder
        
        // setup the private tab control
        self.segmentedControl.target = self
        self.segmentedControl.action = #selector(takeSelectedTabViewItemFromSender)
        
        // add control parts
        self.segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.segmentedControl)
        
        NSLayoutConstraint.activate([
            self.segmentedControl.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            self.segmentedControl.leadingAnchor.constraint(equalToSystemSpacingAfter: self.safeAreaLayoutGuide.leadingAnchor, multiplier: 1 / 2),
            self.segmentedControl.trailingAnchor.constraint(equalToSystemSpacingAfter: self.safeAreaLayoutGuide.trailingAnchor, multiplier: -1 / 2),
        ])
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: Tab View Methods
    
    public override var contentRect: NSRect {
        
        // take off control space
        let offset = self.safeAreaInsets.top + self.segmentedControl.frame.height
        var rect = self.bounds
        rect.origin.y = offset
        rect.size.height -= offset
        
        return rect
    }
    
    
    public override func layout() {
        
        super.layout()
        
        self.selectedTabViewItem?.view?.frame = self.contentRect
    }
    
    
    public override func selectTabViewItem(at index: Int) {
        
        super.selectTabViewItem(at: index)
        
        self.segmentedControl.selectedSegment = index
    }
    
    
    public override func insertTabViewItem(_ tabViewItem: NSTabViewItem, at index: Int) {
        
        super.insertTabViewItem(tabViewItem, at: index)
        
        self.rebuildSegmentedControl()
    }
    
    
    public override func removeTabViewItem(_ tabViewItem: NSTabViewItem) {
        
        super.removeTabViewItem(tabViewItem)
        
        self.rebuildSegmentedControl()
    }
    
    
    // MARK: Private Methods
    
    /// Updates the private control every time when the line-up of tab items changed.
    private func rebuildSegmentedControl() {
        
        self.segmentedControl.segmentCount = self.numberOfTabViewItems
        
        for (segment, item) in self.tabViewItems.enumerated() {
            self.segmentedControl.setImage(item.image, forSegment: segment)
            self.segmentedControl.setToolTip(item.label, forSegment: segment)
        }
        
        if let item = self.selectedTabViewItem, let index = self.tabViewItems.firstIndex(of: item) {
            self.segmentedControl.selectedSegment = index
        }
    }
}
