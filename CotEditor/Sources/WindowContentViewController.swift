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

protocol DocumentOwner: NSViewController {
    
    var document: Document { get set }
}


final class WindowContentViewController: NSSplitViewController, DocumentOwner {
    
    // MARK: Public Properties
    
    var document: Document  { didSet { self.updateDocument() } }
    
    private(set) lazy var documentViewController = DocumentViewController(document: self.document)
    
    
    // MARK: Private Properties
    
    private lazy var inspectorViewController = InspectorViewController(document: self.document)
    
    private var windowObserver: NSKeyValueObservation?
    
    
    
    // MARK: Split View Controller Methods
    
    init(document: Document) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        
        self.view = HoleContentView()
        self.view.frame.size = NSSize(width: 640, height: 720)
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
        self.splitView.identifier = NSUserInterfaceItemIdentifier("WindowContentSplitView")
        self.splitView.autosaveName = "WindowContentSplitView"
        
        self.addChild(self.documentViewController)
        
        let inspectorViewItem = NSSplitViewItem(inspectorWithViewController: self.inspectorViewController)
        inspectorViewItem.minimumThickness = NSSplitViewItem.unspecifiedDimension
        inspectorViewItem.maximumThickness = NSSplitViewItem.unspecifiedDimension
        inspectorViewItem.isCollapsed = true
        self.addSplitViewItem(inspectorViewItem)
        
        // adopt the visibility of the inspector from the last change
        self.windowObserver = self.view.observe(\.window) { [weak self] (_, _)  in
            self?.restoreAutosavingState()
        }
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
    
    /// Opens the desired inspector pane.
    ///
    /// - Parameter pane: The inspector pane to open.
    func showInspector(pane: InspectorPane) {
        
        self.setInspectorShown(true, pane: pane)
    }
    
    
    
    // MARK: Action Messages
    
    /// Toggles visibility of the inspector.
    @IBAction override func toggleInspector(_ sender: Any?) {
        
        if #available(macOS 14, *) {
            super.toggleInspector(sender)
        } else {
            self.inspectorViewItem?.animator().isCollapsed.toggle()
        }
    }
    
    
    /// Toggles visibility of the document inspector pane.
    @IBAction func getInfo(_ sender: Any?) {
        
        self.toggleVisibilityOfInspector(pane: .document)
    }
    
    
    /// Toggles visibility of the outline pane.
    @IBAction func toggleOutlineMenu(_ sender: Any?) {
        
        self.toggleVisibilityOfInspector(pane: .outline)
    }
    
    
    /// Toggles visibility of warnings pane.
    @IBAction func toggleWarningsPane(_ sender: Any?) {
        
        self.toggleVisibilityOfInspector(pane: .warnings)
    }
    
    
    
    // MARK: Private Methods
    
    /// The split view item for the inspector.
    private var inspectorViewItem: NSSplitViewItem? {
        
        self.splitViewItem(for: self.inspectorViewController)
    }
    
    
    /// Whether the inspector is opened.
    private var isInspectorShown: Bool {
        
        self.inspectorViewItem?.isCollapsed == false
    }
    
    
    /// Sets the visibility of the inspector and switch pane with animation.
    ///
    /// - Parameters:
    ///   - shown: The boolean flag whether to open or close the pane.
    ///   - pane: The inspector pane to change visibility.
    private func setInspectorShown(_ shown: Bool, pane: InspectorPane) {
        
        self.inspectorViewItem!.animator().isCollapsed = !shown
        self.inspectorViewController.selectedTabViewItemIndex = pane.rawValue
    }
    
    
    /// Returns whether the given pane in the inspector is currently shown.
    ///
    /// - Parameter pane: The inspector pane to check.
    /// - Returns: `true` when the pane is currently visible.
    private func isInspectorShown(pane: InspectorPane) -> Bool {
        
        self.isInspectorShown && (self.inspectorViewController.selectedPane == pane)
    }
    
    
    /// Toggles visibility of pane in the inspector.
    ///
    /// - Parameter pane: The inspector pane to toggle visibility.
    private func toggleVisibilityOfInspector(pane: InspectorPane) {
        
        self.setInspectorShown(!self.isInspectorShown(pane: pane), pane: pane)
    }
    
    
    /// Updates the document in children.
    private func updateDocument() {
        
        self.documentViewController.document = self.document
        self.inspectorViewController.document = self.document
    }
}
