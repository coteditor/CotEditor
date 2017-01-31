/*
 
 WindowContentViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-05.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class WindowContentViewController: NSSplitViewController, TabViewControllerDelegate {
    
    // MARK: Private Properties
    
    private var isSynchronizingTabs = false
    
    @IBOutlet private weak var documentViewItem: NSSplitViewItem?
    @IBOutlet private weak var sidebarViewItem: NSSplitViewItem?
    
    
    
    // MARK:
    // MARK: Split View Controller Methods
    
    /// setup view
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // workaround for OS X Yosemite (on macOS 10.12 SDK)
        if NSAppKitVersionNumber < Double(NSAppKitVersionNumber10_11) {
            self.splitView.delegate = self
        }
        
        // -> needs layer to mask rounded window corners
        //                to redraw line number view background by thickness increase
        self.view.wantsLayer = true
        
        // set behavior to glow window size on sidebar toggling rather than opening sidebar indraw (only on El Capitan or later)
        if #available(macOS 10.11, *) {
            self.sidebarViewItem?.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
        }
        
        if Defaults[.sidebarWidth] >= 100 {
            self.sidebarThickness = Defaults[.sidebarWidth]
        }
        self.isSidebarShown = Defaults[.showDocumentInspector]
        
        self.sidebarViewController?.delegate = self
    }
    
    
    /// view is ready to display
    override func viewDidAppear() {
        
        // note: This method will not be invoked on window tab change.
        
        super.viewDidAppear()
        
        // adjust sidebar visibility if this new window was just added to an existing window
        if let other = self.siblings.first(where: { $0 != self }) {
            self.sidebarThickness = other.sidebarThickness
            self.setSidebarShown(other.isSidebarShown, index: other.sidebarViewController!.selectedTabIndex)
        }
    }
    
    
    /// deliver represented object to child view controllers
    override var representedObject: Any? {
        
        didSet {
            for viewController in self.childViewControllers {
                viewController.representedObject = representedObject
            }
        }
    }
    
    
    /// divider position did change
    override func splitViewDidResizeSubviews(_ notification: Notification) {
        
        if #available(macOS 10.11, *) {
            // -> Calling super's method crashes the app on Yosemite.
            super.splitViewDidResizeSubviews(notification)
        }
        
        if notification.userInfo?["NSSplitViewDividerIndex"] != nil {  // check wheter the change coused by user's divider dragging
            // store current sidebar width
            if self.isSidebarShown {
                Defaults[.sidebarWidth] = self.sidebarThickness
            }
            
            // sync divider position among window tabs
            if !self.isSynchronizingTabs,
                let position = self.documentViewController?.view.frame.width
            {
                self.isSynchronizingTabs = true
                
                self.siblings.lazy
                    .filter { $0 != self }
                    .forEach { $0.splitView.setPosition(position, ofDividerAt: 0) }
                
                self.isSynchronizingTabs = false
            }
        }
    }
    
    
    
    // MARK: Sidebar View Controller Delegate
    
    /// synchronize sidebar pane among window tabs
    func tabViewController(_ viewController: NSTabViewController, didSelect tabViewIndex: Int) {
        
        guard !self.isSynchronizingTabs else { return }
        
        self.isSynchronizingTabs = true
        
        self.siblings.lazy
            .filter { $0 != self }
            .forEach { $0.sidebarViewController?.selectedTabViewItemIndex = tabViewIndex }
        
        self.isSynchronizingTabs = false
    }
    
    
    
    // MARK: Public Methods
    
    /// deliver editor to outer view controllers
    var documentViewController: DocumentViewController? {
        
        return self.documentViewItem?.viewController as? DocumentViewController
    }
    
    
    /// display desired sidebar pane
    func showSidebarPane(index: SidebarViewController.TabIndex) {
        
        self.setSidebarShown(true, index: index, animate: true)
    }
    
    
    
    // MARK: Action Messages
    
    /// toggle visibility of document inspector
    @IBAction func getInfo(_ sender: Any?) {
        
        self.toggleVisibilityOfSidebarTabItem(index: .documentInspector)
    }
    
    
    /// toggle visibility of incompatible characters list view
    @IBAction func toggleIncompatibleCharList(_ sender: Any?) {
        
        self.toggleVisibilityOfSidebarTabItem(index: .incompatibleCharacters)
    }
    
    
    
    // MARK: Private Methods
    
    /// split view item to view controller
    private var sidebarViewController: SidebarViewController? {
        
        return self.sidebarViewItem?.viewController as? SidebarViewController
    }
    
    
    /// sidebar thickness
    private var sidebarThickness: CGFloat {
        
        get {
            return self.sidebarViewController?.view.frame.width ?? 0
        }
        set {
            self.sidebarViewController?.view.frame.size.width = max(newValue, 0)  // avoid having a negative value
        }
    }
    
    
    /// whether sidebar is opened
    private var isSidebarShown: Bool {
        
        get {
            return !(self.sidebarViewItem?.isCollapsed ?? true)
        }
        set (shown) {
            // workaround for OS X Yosemite (on macOS 10.12 SDK)
            guard #available(macOS 10.11, *) else {
                guard self.sidebarViewItem?.isCollapsed == shown,
                    let window = self.view.window else { return }
                
                let maxPosition = self.splitView.maxPossiblePositionOfDivider(at: 0)
                
                NSAnimationContext.current().withAnimation(false) {
                    self.sidebarViewItem?.isCollapsed = !shown
                }
                
                guard !window.styleMask.contains(.fullScreen) else { return }
                
                // don't adjust window size on the initial setting
                if window.isVisible {
                    // update window size manually
                    let sidebarThickness = self.sidebarThickness + self.splitView.dividerThickness
                    var windowFrame = window.frame
                    windowFrame.size.width += shown ? sidebarThickness : -sidebarThickness
                    window.setFrame(windowFrame, display: false)
                }
                
                if shown {
                    let position = maxPosition - (window.isVisible ? 0 : self.sidebarThickness)
                    self.splitView.setPosition(position, ofDividerAt: 0)
                    self.splitView.adjustSubviews()
                }
                
                return
            }
            
            // update current tab possibly with an animation
            self.sidebarViewItem?.isCollapsed = !shown
            
            // and then update background tabs
            self.siblings.lazy
                .filter { $0 != self }
                .forEach {
                    $0.sidebarViewItem?.isCollapsed = !shown
                    $0.sidebarThickness = self.sidebarThickness
            }
        }
    }
    
    
    /// set visibility and tab of sidebar
    private func setSidebarShown(_ shown: Bool, index: SidebarViewController.TabIndex? = nil, animate: Bool = false) {
        
        if let index = index {
            self.siblings.forEach { sibling in
                sibling.sidebarViewController!.selectedTabViewItemIndex = index.rawValue
            }
        }
        
        guard NSAppKitVersionNumber >= Double(NSAppKitVersionNumber10_11) else {
            self.isSidebarShown = shown
            return
        }
        
        NSAnimationContext.current().withAnimation(animate) {
            self.isSidebarShown = shown
        }
    }
    
    
    /// toggle visibility of pane in sidebar
    private func toggleVisibilityOfSidebarTabItem(index: SidebarViewController.TabIndex) {
        
        let shown = !self.isSidebarShown || (index.rawValue != self.sidebarViewController!.selectedTabViewItemIndex)
        
        self.setSidebarShown(shown, index: index, animate: true)
    }
    
    
    /// window content view controllers in all tabs in the same window
    private var siblings: [WindowContentViewController]  {
        
        if #available(macOS 10.12, *) {
            return self.view.window?.tabbedWindows?.flatMap { ($0.windowController?.contentViewController as? WindowContentViewController) } ?? [self]
        } else {
            return [self]
        }
    }
    
}
