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
//  © 2016-2021 1024jp
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

protocol InspectorTabViewDelegate: NSTabViewDelegate {
    
    /// Provide custom image for selected tab view item.
    ///
    /// - Parameters:
    ///   - tabView: The tab view that sent the request.
    ///   - selectedImageForItem: The tab view item that requests selected image.
    /// - Returns: An image for selected tab, or `nil` for default behavior.
    func tabView(_ tabView: NSTabView, selectedImageForItem: NSTabViewItem) -> NSImage?
}


final class InspectorTabView: NSTabView {
    
    // MARK: Public Properties
    
    let segmentedControl: NSSegmentedControl
    
    
    // MARK: Private Properties
    
    private let separator: NSBox
    private let controlHeight: CGFloat = 28
    private let segmentWidth: CGFloat = 30
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init?(coder: NSCoder) {
        
        self.segmentedControl = InspectorTabSegmentedControl()
        self.segmentedControl.segmentStyle = .texturedSquare
        
        self.separator = NSBox()
        self.separator.boxType = .separator
        
        super.init(coder: coder)
        
        self.tabViewType = .noTabsNoBorder
        
        // cover the entire area with an NSVisualEffectView as background
        let backgroundView = NSVisualEffectView()
        backgroundView.material = .windowBackground
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            self.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            self.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
        ])
        
        // add control parts
        self.addSubview(self.segmentedControl)
        self.addSubview(self.separator)
    }
    
    
    
    // MARK: Tab View Methods
    
    /// take off control space
    override var contentRect: NSRect {
        
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
            y: ((self.controlHeight - self.segmentedControl.intrinsicContentSize.height) / 2).rounded(.down) + self.safeAreaInsets.top
        )
        
        self.separator.frame = NSRect(x: 0, y: self.safeAreaInsets.top + self.controlHeight, width: self.frame.width, height: 1)
        
        super.layout()
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
    
    
    /// update the private control every time when tab item line-up changed
    private func rebuildSegmentedControl() {
        
        self.segmentedControl.segmentCount = self.numberOfTabViewItems
        
        // set tabViewItem values to control buttons
        for (segment, item) in self.tabViewItems.enumerated() {
            self.segmentedControl.setWidth(self.segmentWidth, forSegment: segment)
            self.segmentedControl.setToolTip(item.label, forSegment: segment)
            
            let selectedImage = (self.delegate as? any InspectorTabViewDelegate)?.tabView(self, selectedImageForItem: item)
                ?? item.selectedImage
            (self.segmentedControl as? InspectorTabSegmentedControl)?
                .setImage(item.image, selectedImage: selectedImage, forSegment: segment)
        }
        
        self.segmentedControl.sizeToFit()
        self.invalidateControlSelection()
    }
    
}


private extension NSTabViewItem {
    
    var selectedImage: NSImage? {
        
        return self.image?.withSymbolConfiguration(.init(pointSize: 0, weight: .bold))
    }
    
}
