//
//  WindowContentViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

import Combine
import Cocoa

final class WindowContentViewController: NSSplitViewController {
    
    // MARK: Private Properties
    
    private var sidebarObserver: AnyCancellable?
    private var sidebarSelectionObserver: AnyCancellable?
    
    @IBOutlet private weak var documentViewItem: NSSplitViewItem?
    @IBOutlet private weak var sidebarViewItem: NSSplitViewItem?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    /// setup view
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.restoreAutosavingState()
        
        // set behavior to glow window size on sidebar toggling rather than opening sidebar inward
        self.sidebarViewItem?.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
        self.sidebarObserver = self.sidebarViewItem?.publisher(for: \.isCollapsed, options: .initial)
            .sink { [weak self] _ in self?.invalidateRestorableState() }
        
        // synchronize sidebar pane among window tabs
        self.sidebarSelectionObserver = self.sidebarViewController?.publisher(for: \.selectedTabViewItemIndex)
            .sink { [weak self] (tabViewIndex) in
                self?.siblings.filter { $0 != self }
                    .forEach { $0.sidebarViewController?.selectedTabViewItemIndex = tabViewIndex }
            }
    }
    
    
    /// view is ready to display
    override func viewDidAppear() {
        
        // note: This method will not be invoked on window tab change.
        
        super.viewDidAppear()
        
        // adjust sidebar visibility if this new window was just added to an existing window
        if let other = self.siblings.first(where: { $0 != self }), other.isSidebarShown {
            self.sidebarThickness = other.sidebarThickness
            self.setSidebarShown(other.isSidebarShown, index: other.sidebarViewController!.selectedTabIndex)
        }
    }
    
    
    /// deliver represented object to child view controllers
    override var representedObject: Any? {
        
        didSet {
            for viewController in self.children {
                viewController.representedObject = representedObject
            }
        }
    }
    
    
    /// disable toggling sidebar in the tab overview mode
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleInspector):
                let title = self.isSidebarShown ? "Hide Inspector" : "Show Inspector"
                (item as? NSMenuItem)?.title = title.localized
            
            case #selector(getInfo):
                (item as? NSMenuItem)?.state = self.isSidebarShown(index: .documentInspector) ? .on : .off
                return self.canToggleSidebar
            
            case #selector(toggleOutlineMenu):
                (item as? NSMenuItem)?.state = self.isSidebarShown(index: .outline) ? .on : .off
                return self.canToggleSidebar
            
            case #selector(toggleWarningsPane):
                (item as? NSMenuItem)?.state = self.isSidebarShown(index: .warnings) ? .on : .off
                return self.canToggleSidebar
            
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
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
    
    /// toggle visibility of inspector
    @IBAction func toggleInspector(_ sender: Any?) {
        
        NSAnimationContext.current.withAnimation {
            self.isSidebarShown.toggle()
        }
    }
    
    
    /// toggle visibility of document inspector
    @IBAction func getInfo(_ sender: Any?) {
        
        self.toggleVisibilityOfSidebarTabItem(index: .documentInspector)
    }
    
    
    /// toggle visibility of outline menu view
    @IBAction func toggleOutlineMenu(_ sender: Any?) {
        
        self.toggleVisibilityOfSidebarTabItem(index: .outline)
    }
    
    
    /// toggle visibility of incompatible characters list view
    @IBAction func toggleWarningsPane(_ sender: Any?) {
        
        self.toggleVisibilityOfSidebarTabItem(index: .warnings)
    }
    
    
    
    // MARK: Private Methods
    
    /// split view item to view controller
    private var sidebarViewController: SidebarViewController? {
        
        self.sidebarViewItem?.viewController as? SidebarViewController
    }
    
    
    /// sidebar thickness
    private var sidebarThickness: CGFloat {
        
        get { self.sidebarViewController?.view.frame.width ?? 0 }
        set { self.sidebarViewController?.view.frame.size.width = max(newValue, 0) }
    }
    
    
    /// whether sidebar is opened
    private var isSidebarShown: Bool {
        
        get {
            return self.sidebarViewItem?.isCollapsed == false
        }
        
        set {
            guard newValue != self.isSidebarShown else { return }
            
            // close sidebar inward if it opened so (because of insufficient space to open outward)
            let currentWidth = self.splitView.frame.width
            NSAnimationContext.current.completionHandler = { [weak self] in
                guard let self = self else { return }
                
                if newValue {
                    if self.splitView.frame.width == currentWidth {  // opened inward
                        self.siblings.forEach {
                            $0.sidebarViewItem?.collapseBehavior = .preferResizingSiblingsWithFixedSplitView
                        }
                    }
                } else {
                    // reset sidebar collapse behavior anyway
                    self.siblings.forEach {
                        $0.sidebarViewItem?.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
                    }
                }
                
                // sync sidebar thickness among tabbed windows
                self.siblings.filter { $0 != self }
                    .forEach { $0.sidebarThickness = self.sidebarThickness }
            }
            
            // update current tab possibly with an animation
            self.sidebarViewItem?.isCollapsed = !newValue
            // and then update background tabs
            self.siblings.filter { $0 != self }
                .forEach { $0.sidebarViewItem?.isCollapsed = !newValue }
        }
    }
    
    
    /// set visibility and tab of sidebar
    private func setSidebarShown(_ shown: Bool, index: SidebarViewController.TabIndex? = nil, animate: Bool = false) {
        
        NSAnimationContext.current.withAnimation(animate) {
            self.isSidebarShown = shown
        }
        
        if let index = index {
            self.siblings.forEach { sibling in
                sibling.sidebarViewController!.selectedTabViewItemIndex = index.rawValue
            }
        }
    }
    
    
    /// whether the given pane in the sidebar is currently shown
    private func isSidebarShown(index: SidebarViewController.TabIndex) -> Bool {
        
        return self.isSidebarShown && (self.sidebarViewController?.selectedTabViewItemIndex == index.rawValue)
    }
    
    
    /// toggle visibility of pane in sidebar
    private func toggleVisibilityOfSidebarTabItem(index: SidebarViewController.TabIndex) {
        
        self.setSidebarShown(!self.isSidebarShown(index: index), index: index, animate: true)
    }
    
    
    /// whether sidebar state can be toggled
    private var canToggleSidebar: Bool {
        
        guard self.isViewLoaded else { return false }
        
        // cannot toggle in the tab overview mode
        if let tabGroup = self.view.window?.tabGroup {
            return !tabGroup.isOverviewVisible
        }
        
        return true
    }
    
    
    /// window content view controllers in all tabs in the same window
    private var siblings: [WindowContentViewController] {
        
        guard self.isViewLoaded else { return [] }
        
        return self.view.window?.tabbedWindows?.compactMap { ($0.windowController?.contentViewController as? WindowContentViewController) } ?? [self]
    }
    
}
