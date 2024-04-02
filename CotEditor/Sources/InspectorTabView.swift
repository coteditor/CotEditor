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
//  © 2016-2024 1024jp
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

protocol InspectorTabViewDelegate: NSTabViewDelegate {
    
    /// Provides custom image for selected tab view item.
    ///
    /// - Parameters:
    ///   - tabView: The tab view that sent the request.
    ///   - tabViewItem: The tab view item that requests selected image.
    /// - Returns: An image for selected tab, or `nil` for default behavior.
    @MainActor func tabView(_ tabView: NSTabView, selectedImageForItem tabViewItem: NSTabViewItem) -> NSImage?
}


final class InspectorTabView: NSTabView {
    
    // MARK: Private Properties
    
    private let segmentedControl = InspectorTabSegmentedControl()
    private let controlOffset: CGFloat = 2
    private let segmentWidth: CGFloat = 30
    
    
    
    // MARK: Lifecycle
    
    override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        
        self.tabViewType = .noTabsNoBorder
        
        // setup the private tab control
        self.segmentedControl.cell?.isBordered = false
        self.segmentedControl.target = self
        self.segmentedControl.action = #selector(takeSelectedTabViewItemFromSender)
        
        // add control parts
        self.segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.segmentedControl)
        NSLayoutConstraint.activate([
            self.segmentedControl.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: self.controlOffset),
            self.segmentedControl.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            self.segmentedControl.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: self.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            self.segmentedControl.trailingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: self.safeAreaLayoutGuide.trailingAnchor, multiplier: 1),
        ])
        
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: self.segmentedControl.bottomAnchor, constant: self.controlOffset),
            separator.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        let windowSeparator = NSBox()
        windowSeparator.boxType = .separator
        windowSeparator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(windowSeparator)
        NSLayoutConstraint.activate([
            windowSeparator.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            windowSeparator.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            windowSeparator.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Tab View Methods
    
    override var contentRect: NSRect {
        
        // take off control space
        let controlHeight = self.segmentedControl.frame.height + self.controlOffset * 2
        let offset = self.safeAreaInsets.top + controlHeight + 1  // +1 for border
        
        var rect = self.bounds
        rect.origin.y = offset
        rect.size.height -= offset
        
        return rect
    }
    
    
    override func layout() {
        
        super.layout()
        
        self.selectedTabViewItem?.view?.frame = self.contentRect
    }
    
    
    override func selectTabViewItem(at index: Int) {
        
        super.selectTabViewItem(at: index)
        
        self.segmentedControl.selectedSegment = index
    }
    
    
    override func insertTabViewItem(_ tabViewItem: NSTabViewItem, at index: Int) {
        
        super.insertTabViewItem(tabViewItem, at: index)
        
        self.rebuildSegmentedControl()
    }
    
    
    override func removeTabViewItem(_ tabViewItem: NSTabViewItem) {
        
        super.removeTabViewItem(tabViewItem)
        
        self.rebuildSegmentedControl()
    }
    
    
    
    // MARK: Private Methods
    
    /// Updates the private control every time when the line-up of tab items changed.
    private func rebuildSegmentedControl() {
        
        self.segmentedControl.segmentCount = self.numberOfTabViewItems
        
        for (segment, item) in self.tabViewItems.enumerated() {
            let selectedImage = (self.delegate as? any InspectorTabViewDelegate)?
                .tabView(self, selectedImageForItem: item)
            self.segmentedControl.setImage(item.image, selectedImage: selectedImage, forSegment: segment)
            self.segmentedControl.setToolTip(item.label, forSegment: segment)
            self.segmentedControl.setWidth(self.segmentWidth, forSegment: segment)
        }
    }
}
