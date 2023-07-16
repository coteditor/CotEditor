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
import Combine

final class WindowContentViewController: NSSplitViewController {
    
    // MARK: Private Properties
    
    private var inspectorObserver: AnyCancellable?
    private var inspectorSelectionObserver: AnyCancellable?
    
    @IBOutlet private weak var documentViewItem: NSSplitViewItem?
    @IBOutlet private weak var inspectorViewItem: NSSplitViewItem?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.restoreAutosavingState()
        
        // set behavior to glow window size on inspector toggling rather than opening inspector inward
        self.inspectorViewItem?.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
        self.inspectorObserver = self.inspectorViewItem?.publisher(for: \.isCollapsed, options: .initial)
            .sink { [weak self] _ in self?.invalidateRestorableState() }
        
        // synchronize inspector pane among window tabs
        self.inspectorSelectionObserver = self.inspectorViewController?.publisher(for: \.selectedTabViewItemIndex)
            .sink { [weak self] (tabViewIndex) in
                self?.siblings.filter { $0 != self }
                    .forEach { $0.inspectorViewController?.selectedTabViewItemIndex = tabViewIndex }
            }
    }
    
    
    override func viewDidAppear() {
        
        // note: This method will not be invoked on window tab change.
        
        super.viewDidAppear()
        
        // adjust inspector visibility if this new window was just added to an existing window
        if let other = self.siblings.first(where: { $0 != self }), other.isInspectorShown {
            self.inspectorThickness = other.inspectorThickness
            self.setInspectorShown(other.isInspectorShown, pane: other.inspectorViewController!.selectedPane)
        }
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        // disable toggling inspector in the tab overview mode
        switch item.action {
            case #selector(toggleInspector):
                (item as? NSMenuItem)?.title = self.isInspectorShown
                    ? String(localized: "Hide Inspector")
                    : String(localized: "Show Inspector")
                
            case #selector(getInfo):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .document) ? .on : .off
                return self.canToggleInspector
                
            case #selector(toggleOutlineMenu):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .outline) ? .on : .off
                return self.canToggleInspector
                
            case #selector(toggleWarningsPane):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .warnings) ? .on : .off
                return self.canToggleInspector
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Public Methods
    
    /// deliver editor to outer view controllers
    var documentViewController: DocumentViewController? {
        
        self.documentViewItem?.viewController as? DocumentViewController
    }
    
    
    /// Open the desired inspector pane.
    ///
    /// - Parameter pane: The inspector pane to open.
    func showInspector(pane: InspectorPane) {
        
        self.setInspectorShown(true, pane: pane, animate: true)
    }
    
    
    
    // MARK: Action Messages
    
    /// Toggle visibility of the inspector.
    @IBAction func toggleInspector(_ sender: Any?) {
        
        NSAnimationContext.current.withAnimation {
            self.isInspectorShown.toggle()
        }
    }
    
    
    /// Toggle visibility of the document inspector pane.
    @IBAction func getInfo(_ sender: Any?) {
        
        self.toggleVisibilityOfInspector(pane: .document)
    }
    
    
    /// Toggle visibility of the outline pane.
    @IBAction func toggleOutlineMenu(_ sender: Any?) {
        
        self.toggleVisibilityOfInspector(pane: .outline)
    }
    
    
    /// Toggle visibility of warnings pane.
    @IBAction func toggleWarningsPane(_ sender: Any?) {
        
        self.toggleVisibilityOfInspector(pane: .warnings)
    }
    
    
    
    // MARK: Private Methods
    
    /// split view item to view controller
    private var inspectorViewController: InspectorViewController? {
        
        self.inspectorViewItem?.viewController as? InspectorViewController
    }
    
    
    /// inspector thickness
    private var inspectorThickness: CGFloat {
        
        get { self.inspectorViewController?.view.frame.width ?? 0 }
        set { self.inspectorViewController?.view.frame.size.width = max(newValue, 0) }
    }
    
    
    /// whether inspector is opened
    private var isInspectorShown: Bool {
        
        get {
            self.inspectorViewItem?.isCollapsed == false
        }
        
        set {
            guard newValue != self.isInspectorShown else { return }
            
            // close inspector inward if it opened so (because of insufficient space to open outward)
            let currentWidth = self.splitView.frame.width
            NSAnimationContext.current.completionHandler = { [weak self] in
                guard let self else { return }
                
                if newValue {
                    if self.splitView.frame.width == currentWidth {  // opened inward
                        self.siblings.forEach {
                            $0.inspectorViewItem?.collapseBehavior = .preferResizingSiblingsWithFixedSplitView
                        }
                    }
                } else {
                    // reset inspector collapse behavior anyway
                    self.siblings.forEach {
                        $0.inspectorViewItem?.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
                    }
                }
                
                // sync inspector thickness among tabbed windows
                self.siblings.filter { $0 != self }
                    .forEach { $0.inspectorThickness = self.inspectorThickness }
            }
            
            // update current tab possibly with an animation
            self.inspectorViewItem?.isCollapsed = !newValue
            // and then update background tabs
            self.siblings.filter { $0 != self }
                .forEach { $0.inspectorViewItem?.isCollapsed = !newValue }
        }
    }
    
    
    /// set visibility of the inspector and switch pane
    private func setInspectorShown(_ shown: Bool, pane: InspectorPane? = nil, animate: Bool = false) {
        
        NSAnimationContext.current.withAnimation(animate) {
            self.isInspectorShown = shown
        }
        
        if let pane {
            self.siblings.forEach { sibling in
                sibling.inspectorViewController!.selectedTabViewItemIndex = pane.rawValue
            }
        }
    }
    
    
    /// whether the given pane in the inspector is currently shown
    private func isInspectorShown(pane: InspectorPane) -> Bool {
        
        self.isInspectorShown && (self.inspectorViewController?.selectedPane == pane)
    }
    
    
    /// toggle visibility of pane in the inspector
    private func toggleVisibilityOfInspector(pane: InspectorPane) {
        
        self.setInspectorShown(!self.isInspectorShown(pane: pane), pane: pane, animate: true)
    }
    
    
    /// whether inspector state can be toggled
    private var canToggleInspector: Bool {
        
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
