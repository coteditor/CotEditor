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
import Combine

final class ContentViewController: NSSplitViewController {
    
    // MARK: Public Properties
    
    var document: Document {
        
        didSet {
            self.documentViewController.document = document
            self.statusBarModel.document = document
        }
    }
    
    private(set) lazy var documentViewController = DocumentViewController(document: self.document)
    
    
    // MARK: Private Properties
    
    private lazy var statusBarModel = StatusBar.Model(document: self.document)
    @ViewLoading private var statusBarItem: NSSplitViewItem
    
    private var defaultsObserver: AnyCancellable?
    
    
    // MARK: Lifecycle
    
    init(document: Document) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.splitView.isVertical = false
        
        self.addChild(self.documentViewController)
        
        // set status bar
        let statusBarItem = NSSplitViewItem(viewController: StatusBarController(model: self.statusBarModel))
        statusBarItem.isCollapsed = !UserDefaults.standard[.showStatusBar]
        self.addSplitViewItem(statusBarItem)
        self.statusBarItem = statusBarItem
        
        // observe user defaults
        self.defaultsObserver = UserDefaults.standard.publisher(for: .showStatusBar, initial: false)
            .sink { [weak self] in self?.statusBarItem.animator().isCollapsed = !$0 }
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
}
