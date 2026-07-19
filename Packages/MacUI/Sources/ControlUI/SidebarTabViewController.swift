//
//  SidebarTabViewController.swift
//  ControlUI
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-07-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

open class SidebarTabViewController: NSTabViewController {
    
    // MARK: Private Properties
    
    private lazy var segmentedControl = NSSegmentedControl()
    
    
    // MARK: Tab View Controller Methods
    
    open override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tabStyle = .unspecified
        
        self.segmentedControl.segmentDistribution = .fillEqually
        self.segmentedControl.controlSize = .large
        if #available(macOS 27, *) {
            self.segmentedControl.role = .tabs
        }
        self.segmentedControl.target = self.tabView
        self.segmentedControl.action = #selector(NSTabView.takeSelectedTabViewItemFromSender)
    }
    
    
    open override func viewWillAppear() {
        
        super.viewWillAppear()
        
        guard self.segmentedControl.segmentCount == 0 else { return }
        
        self.segmentedControl.segmentCount = self.tabViewItems.count - 1
        for (segment, item) in self.tabViewItems.enumerated() {
            self.segmentedControl.setImage(item.image, forSegment: segment)
            self.segmentedControl.setToolTip(item.label, forSegment: segment)
        }
        self.segmentedControl.selectedSegment = self.selectedTabViewItemIndex
    }
    
    
    open override var selectedTabViewItemIndex: Int {
        
        didSet {
            self.segmentedControl.selectedSegment = selectedTabViewItemIndex
        }
    }
    
    
    // MARK: Public Methods
    
    /// Creates an accessory view controller for switching panes.
    ///
    /// - Returns: An accessory view controller that displays the pane selection control.
    public func makeAccessoryViewController() -> NSSplitViewItemAccessoryViewController {
        
        let view = self.segmentedControl
        let containerView = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.leadingAnchor.constraint(equalToSystemSpacingAfter: containerView.leadingAnchor, multiplier: 0.5),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: containerView.trailingAnchor, multiplier: -0.5),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        // present the pane selector inside the tab view controller's accessibility group
        containerView.setAccessibilityChildren([])
        view.setAccessibilityParent(self.view)
        self.view.setAccessibilityChildren((view.accessibilityChildren() ?? []) + [self.tabView])
        
        let viewController = NSSplitViewItemAccessoryViewController()
        viewController.view = containerView
        viewController.automaticallyAppliesContentInsets = false
        if #available(macOS 26.1, *) {
            viewController.preferredScrollEdgeEffectStyle = .soft
        }
        
        return viewController
    }
}
