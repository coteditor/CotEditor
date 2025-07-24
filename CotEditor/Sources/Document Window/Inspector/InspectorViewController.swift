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
    var selectedPane: InspectorPane  { InspectorPane(rawValue: self.selectedTabViewItemIndex) ?? .document }
    
    
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
            item.image = NSImage(systemSymbolName: pane.systemImage, accessibilityDescription: pane.label)
            item.label = pane.label
            return item
        }
        
        // select last used pane
        self.selectedTabViewItemIndex = UserDefaults.standard[.selectedInspectorPaneIndex]
        
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
    
    
    // MARK: Private Methods
    
    /// Updates the document in children.
    private func updateDocument() {
        
        for item in self.tabViewItems {
            switch item.viewController {
                case let viewController as InspectorPaneHostingController<DocumentInspectorView>:
                    viewController.rootView.document = self.document
                case let viewController as InspectorPaneHostingController<OutlineInspectorView>:
                    viewController.rootView.document = self.document
                case let viewController as InspectorPaneHostingController<WarningInspectorView>:
                    viewController.rootView.document = self.document
                default:
                    preconditionFailure()
            }
        }
    }
}


private extension InspectorPane {
    
    var label: String {
        
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
    
    
    var systemImage: String {
        
        switch self {
            case .document: "document"
            case .outline: "list.bullet.indent"
            case .warnings: "exclamationmark.triangle"
        }
    }
    
    
    @MainActor func viewController(document: DataDocument?) -> sending NSViewController {
        
        switch self {
            case .document:
                InspectorPaneHostingController(rootView: DocumentInspectorView(document: document))
            case .outline:
                InspectorPaneHostingController(rootView: OutlineInspectorView(document: document))
            case .warnings:
                InspectorPaneHostingController(rootView: WarningInspectorView(document: document))
        }
    }
}


@available(macOS, deprecated: 26)
extension InspectorViewController: InspectorTabViewDelegate {
    
    func tabView(_ tabView: NSTabView, selectedImageForItem tabViewItem: NSTabViewItem) -> NSImage? {
        
        let index = tabView.indexOfTabViewItem(tabViewItem)
        
        guard let pane = InspectorPane(rawValue: index) else { return nil }
        
        return NSImage(systemSymbolName: pane.selectedImageName, accessibilityDescription: pane.label)?
            .withSymbolConfiguration(.init(pointSize: 0, weight: .semibold))
    }
}


@available(macOS, deprecated: 26)
private extension InspectorPane {
    
    var selectedImageName: String {
        
        switch self {
            case .document: "document.fill"
            case .outline: "list.bullet.indent"
            case .warnings: "exclamationmark.triangle.fill"
        }
    }
}
