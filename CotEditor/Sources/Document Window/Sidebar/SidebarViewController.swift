//
//  SidebarViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-14.
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

import AppKit
import SwiftUI
import ControlUI

enum SidebarPane: Int, CaseIterable {
    
    case fileBrowser
    case find
}


final class SidebarViewController: SidebarTabViewController {
    
    // MARK: Public Properties
    
    var document: DirectoryDocument
    var selectedPane: SidebarPane  { SidebarPane(rawValue: self.selectedTabViewItemIndex) ?? .fileBrowser }
    
    
    // MARK: Lifecycle
    
    init(document: DirectoryDocument) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set identifier for pane restoration
        self.tabView.identifier = NSUserInterfaceItemIdentifier("SidebarTabView")
        
        self.tabViewItems = SidebarPane.allCases.map { pane in
            let item = NSTabViewItem(viewController: pane.viewController(document: self.document))
            item.image = NSImage(systemSymbolName: pane.systemImage, accessibilityDescription: pane.label)
            item.label = pane.label
            return item
        }
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(String(localized: "Sidebar", table: "Document", comment: "accessibility label"))
    }
}


extension SidebarPane {
    
    var label: String {
        
        switch self {
            case .fileBrowser:
                String(localized: "SidebarPane.fileBrowser.label",
                       defaultValue: "File Browser", table: "Document")
            case .find:
                String(localized: "SidebarPane.find.label",
                       defaultValue: "Find", table: "Document")
        }
    }
}


private extension SidebarPane {
    
    var systemImage: String {
        
        switch self {
            case .fileBrowser: "folder"
            case .find: "magnifyingglass"
        }
    }
    
    
    @MainActor func viewController(document: DirectoryDocument) -> sending NSViewController {
        
        switch self {
            case .fileBrowser:
                FileBrowserViewController(document: document)
            case .find:
                NSHostingController(rootView: FolderFindView(model: FolderFinder(document: document)))
        }
    }
}
