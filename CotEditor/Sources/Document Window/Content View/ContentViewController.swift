//
//  ContentViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

final class ContentViewController: NSSplitViewController {
    
    // MARK: Public Properties
    
    var document: DataDocument?  { didSet { self.updateDocument(from: oldValue) } }
    
    var documentViewController: DocumentViewController? {
        
        self.documentViewItem.viewController as? DocumentViewController
    }
    
    
    // MARK: Private Properties
    
    @ViewLoading private var documentViewItem: NSSplitViewItem
    @ViewLoading private var statusBarItem: NSSplitViewItem
    private lazy var statusBarModel = StatusBar.Model(document: self.document as? Document)
    
    private var defaultsObserver: AnyCancellable?
    
    
    // MARK: Lifecycle
    
    init(document: DataDocument?) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // add hidden view for toolbar area
        // -> To avoid the line number view goes under the toolbar when the text orientation is vertical
        //    and the navigation bar is hidden. (2024-07, macOS 14)
        let safeAreaView = NSVisualEffectView()
        safeAreaView.material = .windowBackground
        let safeAreaViewController = NSViewController()
        safeAreaViewController.view = safeAreaView
        let safeAreaViewItem = NSSplitViewItem(viewController: safeAreaViewController)
        
        // set document view
        self.documentViewItem = NSSplitViewItem(viewController: self.createDocumentViewController())
        
        // set status bar
        self.statusBarItem = NSSplitViewItem(viewController: StatusBarController(model: self.statusBarModel))
        self.statusBarItem.isCollapsed = !UserDefaults.standard[.showStatusBar]
        
        self.splitView.isVertical = false
        self.splitViewItems = [safeAreaViewItem, self.documentViewItem, self.statusBarItem]
        
        let constraint = safeAreaView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: -1)
        constraint.priority = .defaultHigh
        constraint.isActive = true
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // observe user defaults
        self.statusBarItem.isCollapsed = !UserDefaults.standard[.showStatusBar]
        self.defaultsObserver = UserDefaults.standard.publisher(for: .showStatusBar, initial: false)
            .sink { [weak self] in self?.statusBarItem.animator().isCollapsed = !$0 }
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.defaultsObserver?.cancel()
        self.defaultsObserver = nil
    }
    
    
    // MARK: Split View Controller Methods
    
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        // avoid showing draggable cursor for the status bar boundary
        .zero
    }
    
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleStatusBar):
                (item as? NSMenuItem)?.title = !self.statusBarItem.isCollapsed
                    ? String(localized: "Hide Status Bar", table: "MainMenu")
                    : String(localized: "Show Status Bar", table: "MainMenu")
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    // MARK: Action Messages
    
    /// Toggles the visibility of status bar with fancy animation (sync all documents).
    @IBAction func toggleStatusBar(_ sender: Any?) {
        
        UserDefaults.standard[.showStatusBar].toggle()
    }
    
    
    // MARK: Private Methods
    
    /// Updates the document in children.
    private func updateDocument(from oldDocument: DataDocument?) {
        
        guard oldDocument != self.document else { return }
        
        self.documentViewItem = NSSplitViewItem(viewController: self.createDocumentViewController())
        self.splitViewItems[1] = self.documentViewItem
        
        self.statusBarModel.updateDocument(to: self.document as? Document)
    }
    
    
    /// Creates a new view controller with the current document.
    private func createDocumentViewController() -> sending NSViewController {
        
        switch self.document {
            case let document as Document:
                DocumentViewController(document: document)
            case let document as PreviewDocument:
                NSHostingController(rootView: FilePreviewView(item: document))
            case .none:
                NSHostingController(rootView: NoDocumentView())
            default:
                preconditionFailure()
        }
    }
}
