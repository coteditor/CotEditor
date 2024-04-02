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

enum InspectorPane: Int, CaseIterable {
    
    case document
    case outline
    case warnings
}


protocol DocumentOwner: NSViewController {
    
    var document: Document { get set }
}


final class InspectorViewController: NSTabViewController {
    
    // MARK: Public Properties
    
    var document: Document  { didSet { self.updateDocument() } }
    var selectedPane: InspectorPane { InspectorPane(rawValue: self.selectedTabViewItemIndex) ?? .document }
    
    
    
    // MARK: Lifecycle
    
    init(document: Document) {
        
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        
        let tabView = InspectorTabView()
        tabView.wantsLayer = true
        
        // set identifier for pane restoration
        tabView.identifier = NSUserInterfaceItemIdentifier("InspectorTabView")
        
        // cover the entire area with an NSVisualEffectView
        let view = NSVisualEffectView()
        view.material = .windowBackground
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
            (item.viewController as? any DocumentOwner)?.document = self.document
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
            case .document: String(localized: "Document Inspector", table: "Document", comment: "inspector pane title")
            case .outline: String(localized: "Outline", table: "Document", comment: "inspector pane title")
            case .warnings: String(localized: "Warnings", table: "Document", comment: "inspector pane title")
        }
    }
    
    
    @MainActor func viewController(document: Document) -> NSViewController {
        
        switch self {
            case .document:
                DocumentInspectorViewController(document: document)
            case .outline:
                OutlineInspectorViewController(document: document)
            case .warnings:
                WarningInspectorViewController(document: document)
        }
    }
    
    
    func image(selected: Bool = false) -> NSImage? {
        
        NSImage(systemSymbolName: selected ? self.selectedImageName : self.imageName, accessibilityDescription: self.name)?
            .withSymbolConfiguration(.init(pointSize: 0, weight: selected ? .semibold : .regular))
    }
    
    
    private var imageName: String {
        
        switch self {
            case .document: "doc"
            case .outline: "list.bullet.indent"
            case .warnings: "exclamationmark.triangle"
        }
    }
    
    
    private var selectedImageName: String {
        
        switch self {
            case .document: "doc.fill"
            case .outline: "list.bullet.indent"
            case .warnings: "exclamationmark.triangle.fill"
        }
    }
}
