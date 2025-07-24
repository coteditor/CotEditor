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

import AppKit

@available(macOS, deprecated: 26, message: "Use normal NSSegmentedControl.")
public protocol InspectorTabViewDelegate: NSTabViewDelegate {
    
    /// Provides custom image for selected tab view item.
    ///
    /// - Parameters:
    ///   - tabView: The tab view that sent the request.
    ///   - tabViewItem: The tab view item that requests selected image.
    /// - Returns: An image for selected tab, or `nil` for default behavior.
    @MainActor func tabView(_ tabView: NSTabView, selectedImageForItem tabViewItem: NSTabViewItem) -> NSImage?
}


public final class InspectorTabView: NSTabView {
    
    // MARK: Private Properties
    
    private let segmentedControl: NSSegmentedControl
    
    @available(macOS, deprecated: 26)
    private let controlOffset: CGFloat = 2
    
    
    // MARK: Lifecycle
    
    public override init(frame frameRect: NSRect) {
        
        if #available(macOS 26, *) {
            self.segmentedControl = NSSegmentedControl()
            self.segmentedControl.controlSize = .large
            self.segmentedControl.selectedSegment = 1
        } else {
            self.segmentedControl = InspectorTabSegmentedControl()
            self.segmentedControl.cell?.isBordered = false
        }
        
        super.init(frame: frameRect)
        
        self.wantsLayer = true
        self.tabViewType = .noTabsNoBorder
        
        // setup the private tab control
        self.segmentedControl.target = self
        self.segmentedControl.action = #selector(takeSelectedTabViewItemFromSender)
        
        // add control parts
        self.segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.segmentedControl)
        
        if #available(*, macOS 26) {
            NSLayoutConstraint.activate([
                self.segmentedControl.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
                self.segmentedControl.leadingAnchor.constraint(equalToSystemSpacingAfter: self.safeAreaLayoutGuide.leadingAnchor, multiplier: 1 / 2),
                self.segmentedControl.trailingAnchor.constraint(equalToSystemSpacingAfter: self.safeAreaLayoutGuide.trailingAnchor, multiplier: -1 / 2),
            ])
        } else {
            NSLayoutConstraint.activate([
                self.segmentedControl.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: self.controlOffset),
                self.segmentedControl.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
                self.segmentedControl.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: self.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
                self.segmentedControl.trailingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: self.safeAreaLayoutGuide.trailingAnchor, multiplier: 1),
            ])
        }
        
        guard #unavailable(macOS 26) else { return }
        
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: self.segmentedControl.bottomAnchor, constant: self.controlOffset),
            separator.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        // draw titlebar separator by myself
        // instead of setting `.separator` to split view item's `titlebarSeparatorStyle` property
        // to avoid the separator being aligned to the bottom of the tab bar (macOS 15 2025-04, FB17317262)
        let titlebarSeparator = NSBox()
        titlebarSeparator.boxType = .separator
        titlebarSeparator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titlebarSeparator)
        NSLayoutConstraint.activate([
            titlebarSeparator.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            titlebarSeparator.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            titlebarSeparator.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: Tab View Methods
    
    public override var contentRect: NSRect {
        
        // take off control space
        var offset = self.safeAreaInsets.top + self.segmentedControl.frame.height
        if #unavailable(macOS 26) {
            offset += self.controlOffset * 2 + 1  // +1 for border
        }
        
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
            if let segmentedControl = self.segmentedControl as? InspectorTabSegmentedControl {
                let segmentWidth: CGFloat = 30
                let selectedImage = (self.delegate as? any InspectorTabViewDelegate)?
                    .tabView(self, selectedImageForItem: item)
                segmentedControl.setImage(item.image, selectedImage: selectedImage, forSegment: segment)
                self.segmentedControl.setWidth(segmentWidth, forSegment: segment)
            } else {
                self.segmentedControl.setImage(item.image, forSegment: segment)
            }
            self.segmentedControl.setToolTip(item.label, forSegment: segment)
        }
        
        if let item = self.selectedTabViewItem, let index = self.tabViewItems.firstIndex(of: item) {
            self.segmentedControl.selectedSegment = index
        }
    }
}
