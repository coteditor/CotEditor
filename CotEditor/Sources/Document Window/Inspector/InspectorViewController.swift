//
//  InspectorViewController.swift
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
import Defaults
import ControlUI

enum InspectorPane: Int, CaseIterable {
    
    case document
    case outline
    case warnings
}


final class InspectorViewController: NSTabViewController {
    
    // MARK: Public Properties
    
    var document: DataDocument?  { didSet { self.updateDocument() } }
    var selectedPane: InspectorPane { InspectorPane(rawValue: self.selectedTabViewItemIndex) ?? .document }
    
    
    // MARK: Lifecycle
    
    init(document: DataDocument? = nil) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        
        let tabView = InspectorTabView()
        let view = NSView()
        view.addSubview(tabView)
        
        tabView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: tabView.topAnchor),
            view.bottomAnchor.constraint(equalTo: tabView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: tabView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tabView.trailingAnchor),
        ])
        
        self.tabView = tabView
        self.view = view
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set identifier for pane restoration
        self.tabView.identifier = NSUserInterfaceItemIdentifier("InspectorTabView")
        
        self.tabViewItems = InspectorPane.allCases.map { pane in
            let item = NSTabViewItem(viewController: pane.viewController(document: self.document))
            item.image = pane.image()
            item.label = pane.name
            return item
        }
        
        // select last used pane
        self.selectedTabViewItemIndex = UserDefaults.standard[.selectedInspectorPaneIndex]
        
        // restore thickness first when the view is loaded
        let width = UserDefaults.standard[.sidebarWidth]
        if width > 0 {
            self.view.frame.size.width = width
        }
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(String(localized: "Inspector", table: "Document", comment: "accessibility label"))
    }
    
    
    // MARK: Tab View Controller Methods
    
    override var selectedTabViewItemIndex: Int {
        
        didSet {
            // ignore initial setting that select 0
            guard oldValue != -1 else { return }
            
            UserDefaults.standard[.selectedInspectorPaneIndex] = selectedTabViewItemIndex
        }
    }
    
    
    override func viewDidLayout() {
        
        super.viewDidLayout()
        
        if !self.view.inLiveResize, self.view.frame.width > 0 {
            UserDefaults.standard[.sidebarWidth] = self.view.frame.width
        }
    }
    
    
    // MARK: Private Methods
    
    /// Updates the document in children.
    private func updateDocument() {
        
        for item in self.tabViewItems {
            switch item.viewController {
                case let viewController as DocumentInspectorViewController:
                    viewController.model.document = self.document
                case let viewController as OutlineInspectorViewController:
                    viewController.model.document = self.document as? Document
                case let viewController as WarningInspectorViewController:
                    viewController.model.document = self.document as? Document
                default:
                    preconditionFailure()
            }
        }
    }
}


extension InspectorViewController: InspectorTabViewDelegate {
    
    func tabView(_ tabView: NSTabView, selectedImageForItem tabViewItem: NSTabViewItem) -> NSImage? {
        
        let index = tabView.indexOfTabViewItem(tabViewItem)
        
        return InspectorPane(rawValue: index)?.image(selected: true)
    }
}


private extension InspectorPane {
    
    var name: String {
        
        switch self {
            case .document:
                String(localized: "InspectorPane.document.label",
                       defaultValue: "Document Inspector", table: "Document")
            case .outline:
                String(localized: "InspectorPane.outline.label",
                       defaultValue: "Outline", table: "Document")
            case .warnings:
                String(localized: "InspectorPane.warnings.label",
                       defaultValue: "Warnings", table: "Document")
        }
    }
    
    
    @MainActor func viewController(document: DataDocument?) -> sending NSViewController {
        
        switch self {
            case .document:
                DocumentInspectorViewController(document: document)
            case .outline:
                OutlineInspectorViewController(document: document as? Document)
            case .warnings:
                WarningInspectorViewController(document: document as? Document)
        }
    }
    
    
    /// The image for tab view label.
    ///
    /// - Parameter selected: The selection state of the pane.
    /// - Returns: An image.
    func image(selected: Bool = false) -> sending NSImage? {
        
        NSImage(systemSymbolName: selected ? self.selectedImageName : self.imageName, accessibilityDescription: self.name)?
            .withSymbolConfiguration(.init(pointSize: 0, weight: selected ? .semibold : .regular))
    }
    
    
    private var imageName: String {
        
        switch self {
            case .document: "document"
            case .outline: "list.bullet.indent"
            case .warnings: "exclamationmark.triangle"
        }
    }
    
    
    private var selectedImageName: String {
        
        switch self {
            case .document: "document.fill"
            case .outline: "list.bullet.indent"
            case .warnings: "exclamationmark.triangle.fill"
        }
    }
}
