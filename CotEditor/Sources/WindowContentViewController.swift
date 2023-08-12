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

final class WindowContentViewController: NSSplitViewController {
    
    // MARK: Public  Properties
    
    private(set) lazy var documentViewController = DocumentViewController()
    
    
    // MARK: Private Properties
    
    private lazy var inspectorViewController = InspectorViewController()
    private weak var inspectorViewItem: NSSplitViewItem?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    override func loadView() {
        
        self.view = HoleContentView()
        self.view.addSubview(self.splitView)
        
        self.splitView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: self.splitView.topAnchor),
            self.view.bottomAnchor.constraint(equalTo: self.splitView.bottomAnchor),
            self.view.leadingAnchor.constraint(equalTo: self.splitView.leadingAnchor),
            self.view.trailingAnchor.constraint(equalTo: self.splitView.trailingAnchor),
        ])
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // -> Need to set *both* identifier and autosaveName to make autosaving work.
        self.splitView.identifier = NSUserInterfaceItemIdentifier("windowContentSplitView")
        self.splitView.autosaveName = "windowContentSplitView"
        
        self.addChild(self.documentViewController)
        
        let inspectorViewItem: NSSplitViewItem
        if #available(macOS 14, *) {
            inspectorViewItem = NSSplitViewItem(inspectorWithViewController: self.inspectorViewController)
            inspectorViewItem.minimumThickness = NSSplitViewItem.unspecifiedDimension
            inspectorViewItem.maximumThickness = NSSplitViewItem.unspecifiedDimension
        } else {
            inspectorViewItem = NSSplitViewItem(viewController: self.inspectorViewController)
            inspectorViewItem.holdingPriority = .init(261)
            inspectorViewItem.canCollapse = true
        }
        inspectorViewItem.isCollapsed = true
        self.addSplitViewItem(inspectorViewItem)
        self.inspectorViewItem = inspectorViewItem
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleInspector):
                (item as? NSMenuItem)?.title = self.isInspectorShown
                    ? String(localized: "Hide Inspector")
                    : String(localized: "Show Inspector")
                
            case #selector(getInfo):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .document) ? .on : .off
                
            case #selector(toggleOutlineMenu):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .outline) ? .on : .off
                
            case #selector(toggleWarningsPane):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .warnings) ? .on : .off
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Public Methods
    
    /// Open the desired inspector pane.
    ///
    /// - Parameter pane: The inspector pane to open.
    func showInspector(pane: InspectorPane) {
        
        self.setInspectorShown(true, pane: pane)
    }
    
    
    
    // MARK: Action Messages
    
    /// Toggle visibility of the inspector.
    @IBAction override func toggleInspector(_ sender: Any?) {
        
        if #available(macOS 14, *) {
            super.toggleInspector(sender)
        } else {
            self.inspectorViewItem?.animator().isCollapsed.toggle()
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
    
    /// Whether the inspector is opened.
    private var isInspectorShown: Bool {
        
        self.inspectorViewItem?.isCollapsed == false
    }
    
    
    /// Set the visibility of the inspector and switch pane with animation.
    ///
    /// - Parameters:
    ///   - shown: The boolean flag whether to open or close the pane.
    ///   - pane: The inspector pane to change visibility.
    private func setInspectorShown(_ shown: Bool, pane: InspectorPane) {
        
        self.inspectorViewItem!.animator().isCollapsed = !shown
        self.inspectorViewController.selectedTabViewItemIndex = pane.rawValue
    }
    
    
    /// Whether the given pane in the inspector is currently shown.
    ///
    /// - Parameter pane: The inspector pane to check.
    /// - Returns: `true` when the pane is currently visible.
    private func isInspectorShown(pane: InspectorPane) -> Bool {
        
        self.isInspectorShown && (self.inspectorViewController.selectedPane == pane)
    }
    
    
    /// Toggle visibility of pane in the inspector.
    ///
    /// - Parameter pane: The inspector pane to toggle visibility.
    private func toggleVisibilityOfInspector(pane: InspectorPane) {
        
        self.setInspectorShown(!self.isInspectorShown(pane: pane), pane: pane)
    }
}
