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
//  © 2016-2023 1024jp
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
    
    /// Provide custom image for selected tab view item.
    ///
    /// - Parameters:
    ///   - tabView: The tab view that sent the request.
    ///   - tabViewItem: The tab view item that requests selected image.
    /// - Returns: An image for selected tab, or `nil` for default behavior.
    func tabView(_ tabView: NSTabView, selectedImageForItem tabViewItem: NSTabViewItem) -> NSImage?
}


final class InspectorTabView: NSTabView {
    
    // MARK: Private Properties
    
    private let segmentedControl = InspectorTabSegmentedControl()
    private let separator = NSBox()
    private let controlOffset: CGFloat = 2
    private let segmentWidth: CGFloat = 30
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        self.tabViewType = .noTabsNoBorder
        
        self.separator.boxType = .separator
        
        // setup the private tab control
        self.segmentedControl.cell?.isBordered = false
        self.segmentedControl.target = self
        self.segmentedControl.action = #selector(didPressControl)
        
        // cover the entire area with an NSVisualEffectView as background
        let backgroundView = NSVisualEffectView()
        backgroundView.material = .windowBackground
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        // add control parts
        self.addSubview(self.segmentedControl)
        self.addSubview(self.separator)
    }
    
    
    
    // MARK: Tab View Methods
    
    override var contentRect: NSRect {
        
        // take off control space
        let offset = self.safeAreaInsets.top + self.controlHeight + 1  // +1 for border
        
        var rect = self.bounds
        rect.origin.y = offset
        rect.size.height -= offset
        
        return rect
    }
    
    
    /// update private control position
    override func layout() {
        
        self.segmentedControl.frame.origin = NSPoint(
            x: ((self.frame.width - self.segmentedControl.frame.width) / 2).rounded(.down),
            y: self.controlOffset + self.safeAreaInsets.top
        )
        
        self.separator.frame = NSRect(x: 0, y: self.safeAreaInsets.top + self.controlHeight, width: self.frame.width, height: 1)
        
        super.layout()
    }
    
    
    override func selectTabViewItem(at index: Int) {
        
        super.selectTabViewItem(at: index)
        
        self.segmentedControl.selectedSegment = index
    }
    
    
    override func addTabViewItem(_ tabViewItem: NSTabViewItem) {
        
        super.addTabViewItem(tabViewItem)
        
        self.rebuildSegmentedControl()
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
    
    /// The height of the control pane.
    private var controlHeight: CGFloat {
        
        self.segmentedControl.frame.height + self.controlOffset * 2
    }
    
    
    /// The private control was pressed.
    @objc private func didPressControl(_ sender: NSSegmentedControl) {
        
        self.selectTabViewItem(at: sender.indexOfSelectedItem)
    }
    
    
    /// Update the private control every time when the line-up of  tab items changed.
    private func rebuildSegmentedControl() {
        
        self.segmentedControl.segmentCount = self.numberOfTabViewItems
        
        for (segment, item) in self.tabViewItems.enumerated() {
            self.segmentedControl.setWidth(self.segmentWidth, forSegment: segment)
            self.segmentedControl.setToolTip(item.label, forSegment: segment)
            
            let selectedImage = (self.delegate as? any InspectorTabViewDelegate)?
                .tabView(self, selectedImageForItem: item)
            self.segmentedControl.setImage(item.image, selectedImage: selectedImage, forSegment: segment)
        }
        
        self.segmentedControl.sizeToFit()
    }
}
