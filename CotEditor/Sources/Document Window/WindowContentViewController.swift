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
import SwiftUI

final class WindowContentViewController: NSSplitViewController, NSToolbarItemValidation {
    
    // MARK: Public Properties
    
    var document: DataDocument?  { didSet { self.updateDocument() } }
    var directoryDocument: DirectoryDocument?
    
    var documentViewController: DocumentViewController? { self.contentViewController.documentViewController }
    
    
    // MARK: Private Properties
    
    private var sidebarStateCache: Bool?
    
    private var sidebarViewItem: NSSplitViewItem?
    @ViewLoading private var contentViewItem: NSSplitViewItem
    @ViewLoading private var inspectorViewItem: NSSplitViewItem
    
    private var windowObserver: NSKeyValueObservation?
    private var versionBrowserEnterObservationTask: Task<Void, Never>?
    private var versionBrowserExitObservationTask: Task<Void, Never>?
    
    
    // MARK: Split View Controller Methods
    
    init(document: DataDocument?, directoryDocument: DirectoryDocument?) {
        
        assert(document != nil || directoryDocument != nil)
        
        self.document = document
        self.directoryDocument = directoryDocument
        
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
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // -> Need to set *both* identifier and autosaveName to make autosaving work.
        let autosaveName = (self.directoryDocument == nil) ? "WindowContentSplitView" : "DirectoryWindowContentSplitView"
        self.splitView.identifier = NSUserInterfaceItemIdentifier(autosaveName)
        self.splitView.autosaveName = autosaveName
        
        if let directoryDocument {
            let viewController = FileBrowserViewController(document: directoryDocument)
            let sidebarViewItem = NSSplitViewItem(sidebarWithViewController: viewController)
            self.addSplitViewItem(sidebarViewItem)
            self.sidebarViewItem = sidebarViewItem
        }
        
        let contentViewController = ContentViewController(document: self.document)
        self.contentViewItem = NSSplitViewItem(viewController: contentViewController)
        self.addSplitViewItem(self.contentViewItem)
        
        let inspectorViewController = InspectorViewController(document: self.document)
        self.inspectorViewItem = NSSplitViewItem(inspectorWithViewController: inspectorViewController)
        self.inspectorViewItem.minimumThickness = NSSplitViewItem.unspecifiedDimension
        self.inspectorViewItem.maximumThickness = NSSplitViewItem.unspecifiedDimension
        self.inspectorViewItem.isCollapsed = true
        self.inspectorViewItem.titlebarSeparatorStyle = .line
        self.addSplitViewItem(self.inspectorViewItem)
        
        // adopt the visibility of the inspector from the last change
        self.windowObserver = self.view.observe(\.window, options: .new) { [weak self] (_, change) in
            MainActor.assumeIsolated {
                if let window = change.newValue, window != nil {
                    self?.restoreAutosavingState()
                }
            }
        }
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // forcibly collapse sidebar while version browse
        if let sidebarViewItem, let window = self.view.window {
            self.versionBrowserEnterObservationTask = Task {
                for await _ in NotificationCenter.default.notifications(named: NSWindow.willEnterVersionBrowserNotification, object: window).map(\.name) {
                    self.sidebarStateCache = sidebarViewItem.isCollapsed
                    sidebarViewItem.isCollapsed = true
                }
            }
            self.versionBrowserExitObservationTask = Task {
                for await _ in NotificationCenter.default.notifications(named: NSWindow.didExitVersionBrowserNotification, object: window).map(\.name) {
                    self.sidebarStateCache = nil
                    sidebarViewItem.isCollapsed = false
                }
            }
        }
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.versionBrowserEnterObservationTask?.cancel()
        self.versionBrowserEnterObservationTask = nil
        self.versionBrowserExitObservationTask?.cancel()
        self.versionBrowserExitObservationTask = nil
        
        if let sidebarStateCache {
            self.sidebarViewItem?.isCollapsed = sidebarStateCache
            self.sidebarStateCache = nil
        }
    }
    
    
    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        
        // reel responders from the ideal first responder in the content view
        // for when the actual first responder is on the sidebar/inspector
        let endResponder = self.documentViewController?.focusedTextView ?? self.contentViewController
        if let responder = sequence(first: endResponder, next: \.nextResponder).first(where: { $0.responds(to: action) }) {
            return responder
        } else {
            return super.supplementalTarget(forAction: action, sender: sender)
        }
    }
    
    
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        
        switch item.action {
            case #selector(toggleSidebar):
                // validation of `toggleSidebar` is implemented in `validateToolbarItem`
                return self.sidebarStateCache == nil
            default:
                break
        }
        
        return true
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(showFileBrowser):
                (item as? NSMenuItem)?.state = (self.sidebarViewItem?.isCollapsed == true) ? .on : .off
                return self.sidebarViewItem != nil
                
            case #selector(toggleSidebar):
                (item as? NSMenuItem)?.title = self.sidebarViewItem?.isCollapsed == false
                    ? String(localized: "Hide Sidebar", table: "MainMenu")
                    : String(localized: "Show Sidebar", table: "MainMenu")
                return self.sidebarStateCache == nil
                
            case #selector(toggleInspector):
                (item as? NSMenuItem)?.title = self.inspectorViewItem.isCollapsed == false
                    ? String(localized: "Hide Inspector", table: "MainMenu")
                    : String(localized: "Show Inspector", table: "MainMenu")
                
            case #selector(showDocumentInspector):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .document) ? .on : .off
                
            case #selector(showOutlineInspector):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .outline) ? .on : .off
                
            case #selector(showWarningsInspector):
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
        
        self.inspectorViewItem.animator().isCollapsed = false
        self.inspectorViewController.selectedTabViewItemIndex = pane.rawValue
    }
    
    
    // MARK: Action Messages
    
    /// Moves the focus to the editor.
    ///
    /// - Note: The selector name should be the same as one in `DocumentViewController`.
    @IBAction func focusNextEditor(_ sender: Any?) {
        
        self.focusEditor()
    }
    
    
    /// Moves the focus to the editor.
    ///
    /// - Note: The selector name should be the same as one in `DocumentViewController`.
    @IBAction func focusPreviousEditor(_ sender: Any?) {
        
        self.focusEditor()
    }
    
    
    /// Moves the focus to the file browser.
    @IBAction func showFileBrowser(_ sender: Any?) {
        
        guard
            let sidebarViewItem,
            let viewController = sidebarViewItem.viewController as? FileBrowserViewController
        else { return assertionFailure() }
        
        sidebarViewItem.animator().isCollapsed = false
        self.view.window?.makeFirstResponder(viewController.outlineView)
    }
    
    
    /// Shows the document inspector pane.
    @IBAction func showDocumentInspector(_ sender: Any?) {
        
        self.showInspector(pane: .document)
    }
    
    
    /// Shows the outline pane.
    @IBAction func showOutlineInspector(_ sender: Any?) {
        
        self.showInspector(pane: .outline)
    }
    
    
    /// Shows the warnings pane.
    @IBAction func showWarningsInspector(_ sender: Any?) {
        
        self.showInspector(pane: .warnings)
    }
    
    
    // MARK: Private Methods
    
    /// The view controller for the content view.
    private var contentViewController: ContentViewController {
        
        self.contentViewItem.viewController as! ContentViewController
    }
    
    
    /// The view controller for the inspector.
    private var inspectorViewController: InspectorViewController {
        
        self.inspectorViewItem.viewController as! InspectorViewController
    }
    
    
    /// Returns whether the given pane in the inspector is currently shown.
    ///
    /// - Parameter pane: The inspector pane to check.
    /// - Returns: `true` when the pane is currently visible.
    private func isInspectorShown(pane: InspectorPane) -> Bool {
        
        !self.inspectorViewItem.isCollapsed && (self.inspectorViewController.selectedPane == pane)
    }
    
    
    /// Moves the focus to the editor.
    private func focusEditor() {
        
        guard let textView = self.documentViewController?.focusedTextView else { return }
        
        self.view.window?.makeFirstResponder(textView)
    }
    
    
    /// Updates the document in children.
    private func updateDocument() {
        
        self.contentViewController.document = self.document
        self.inspectorViewController.document = self.document
    }
}
