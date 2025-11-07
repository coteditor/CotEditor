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
import SwiftUI
import Combine
import Defaults

final class WindowContentViewController: NSSplitViewController, NSToolbarItemValidation {
    
    // MARK: Public Properties
    
    var document: DataDocument?  { didSet { self.updateDocument() } }
    var directoryDocument: DirectoryDocument?
    
    var documentViewController: DocumentViewController? { self.contentViewController.documentViewController }
    
    
    // MARK: Private Properties
    
    private var sidebarStateCache: Bool?
    private let statusBarModel: StatusBar.Model
    
    private var sidebarViewItem: NSSplitViewItem?
    @ViewLoading private var contentViewItem: NSSplitViewItem
    @ViewLoading private var inspectorViewItem: NSSplitViewItem
    
    private var versionBrowserEnterObservationTask: Task<Void, Never>?
    private var versionBrowserExitObservationTask: Task<Void, Never>?
    
    private var defaultsObserver: AnyCancellable?
    
    
    // MARK: Split View Controller Methods
    
    init(document: DataDocument?, directoryDocument: DirectoryDocument?) {
        
        assert(document != nil || directoryDocument != nil)
        
        self.document = document
        self.directoryDocument = directoryDocument
        self.statusBarModel = .init(document: document)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        
        self.view = HoleContentView()
        self.view.frame.size = NSSize(width: 640, height: 720)
        
        self.splitView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.splitView)
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let directoryDocument {
            let viewController = FileBrowserViewController(document: directoryDocument)
            let sidebarViewItem = NSSplitViewItem(sidebarWithViewController: viewController)
            self.addSplitViewItem(sidebarViewItem)
            self.sidebarViewItem = sidebarViewItem
        }
        
        let contentViewController = ContentViewController(document: self.document)
        self.contentViewItem = NSSplitViewItem(viewController: contentViewController)
        if #available(macOS 26, *) {
            let controller = NSSplitViewItemAccessoryViewController()
            controller.view = NSHostingView(rootView: VStack(spacing: 0) {
                Divider()
                StatusBar(model: self.statusBarModel)
            })
            if #available(macOS 26.1, *) {  // FB18972484
                controller.isHidden = !UserDefaults.standard[.showStatusBar]
            }
            controller.automaticallyAppliesContentInsets = false
            self.contentViewItem.addBottomAlignedAccessoryViewController(controller)
            
            self.addSplitViewItem(self.contentViewItem)
            
            // need to set `isHidden` after setting view item (2025-09, macOS 26, fixed in macOS 26.1, FB18972484)
            if #unavailable(macOS 26.1) {
                controller.isHidden = !UserDefaults.standard[.showStatusBar]
            }
            
        } else {
            let controller = NSHostingController(rootView: StatusBar(model: self.statusBarModel))
            let statusBarItem = NSSplitViewItem(viewController: controller)
            statusBarItem.isCollapsed = !UserDefaults.standard[.showStatusBar]
            self.contentViewController.splitViewItems.append(statusBarItem)
            
            self.addSplitViewItem(self.contentViewItem)
        }
        
        if self.directoryDocument != nil {
            contentViewController.view.setAccessibilityElement(true)
            contentViewController.view.setAccessibilityRole(.group)
            contentViewController.view.setAccessibilityLabel(self.document?.displayName ?? "")
        }
        
        let inspectorViewController = InspectorViewController(document: self.document)
        self.inspectorViewItem = NSSplitViewItem(inspectorWithViewController: inspectorViewController)
        self.inspectorViewItem.minimumThickness = 200
        self.inspectorViewItem.maximumThickness = NSSplitViewItem.unspecifiedDimension
        self.inspectorViewItem.isCollapsed = true
        self.inspectorViewItem.titlebarSeparatorStyle = .none
        self.addSplitViewItem(self.inspectorViewItem)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // -> Set the `autosaveName` first after the view is placed in the window.
        //    Otherwise, the last state won’t be applied (2025-07, macOS 26).
        // -> Need to set *both* identifier and autosaveName to make autosaving work.
        let autosaveName = (self.directoryDocument == nil) ? "WindowContentSplitView" : "DirectoryWindowContentSplitView"
        self.splitView.identifier = NSUserInterfaceItemIdentifier(autosaveName)
        self.splitView.autosaveName = autosaveName
        
        // keep open sidebar at the beginning
        self.sidebarViewItem?.isCollapsed = false
        
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
        
        // move focus to the editor
        // -> The editor doesn’t automatically receive focus
        //    when keyboard navigation is enabled in system settings. (2025-11, macOS 26)
        if let textView = self.documentViewController?.focusedTextView {
            self.view.window?.makeFirstResponder(textView)
        }
        
        // observe user defaults for status bar
        if #available(macOS 26, *) {
            let statusBarController = self.contentViewItem.bottomAlignedAccessoryViewControllers.first
            self.defaultsObserver = UserDefaults.standard.publisher(for: .showStatusBar)
                .sink { statusBarController?.animator().isHidden = !$0 }
        } else {
            let statusBarItem = self.contentViewController.splitViewItems.last
            self.defaultsObserver = UserDefaults.standard.publisher(for: .showStatusBar)
                .sink { statusBarItem?.animator().isCollapsed = !$0 }
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
        
        self.defaultsObserver?.cancel()
        self.defaultsObserver = nil
    }
    
    
    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        
        // reel responders from the ideal first responder in the content view
        // for when the actual first responder is on the sidebar/inspector
        if let endResponder = self.documentViewController?.focusedTextView,
           let responder = sequence(first: endResponder, next: \.nextResponder).first(where: { $0.responds(to: action) }) {
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
                (item as? NSMenuItem)?.toolTip = (self.sidebarViewItem == nil)
                    ? String(localized: "The sidebar is only available when a folder is opened as a document.",
                             table: "MainMenu", comment: "tooltip for the “Show Sidebar” menu item")
                    : nil
                return self.sidebarViewItem != nil
                
            case #selector(toggleSidebar):
                // The menu item is not validated when the responder has no sidebar (2025-03, macOS 15).
                (item as? NSMenuItem)?.title = self.sidebarViewItem?.isCollapsed == false
                    ? String(localized: "Hide Sidebar", table: "MainMenu")
                    : String(localized: "Show Sidebar", table: "MainMenu")
                (item as? NSMenuItem)?.toolTip = (self.sidebarViewItem == nil)
                    ? String(localized: "The sidebar is only available when a folder is opened as a document.",
                             table: "MainMenu", comment: "tooltip for the “Show Sidebar” menu item")
                    : nil
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
                
            case #selector(toggleStatusBar):
                (item as? NSMenuItem)?.title = UserDefaults.standard[.showStatusBar]
                    ? String(localized: "Hide Status Bar", table: "MainMenu")
                    : String(localized: "Show Status Bar", table: "MainMenu")
                
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
    
    
    /// Toggles the visibility of status bar with fancy animation (sync all documents).
    @IBAction func toggleStatusBar(_ sender: Any?) {
        
        UserDefaults.standard[.showStatusBar].toggle()
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
        
        if self.directoryDocument != nil {
            self.contentViewController.view.setAccessibilityLabel(self.document?.displayName ?? "")
        }
        
        self.statusBarModel.document = self.document
    }
}
