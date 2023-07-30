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

enum InspectorPane: Int, CaseIterable {
    
    case document
    case outline
    case warnings
}


final class InspectorViewController: NSTabViewController {
    
    // MARK: Public Properties
    
    var selectedPane: InspectorPane { InspectorPane(rawValue: self.selectedTabViewItemIndex) ?? .document }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tabViewItems = InspectorPane.allCases.map { pane in
            let item = NSTabViewItem(viewController: pane.viewController())
            item.image = pane.image()
            item.label = pane.name
            item.viewController?.representedObject = self.representedObject
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
        self.view.setAccessibilityLabel(String(localized: "Inspector"))
    }
    
    
    // MARK: Tab View Controller Methods
    
    /// deliver passed-in document instance to child view controllers
    override var representedObject: Any? {
        
        didSet {
            for item in self.tabViewItems {
                item.viewController?.representedObject = representedObject
            }
        }
    }
    
    
    override var selectedTabViewItemIndex: Int {
        
        didSet {
            guard selectedTabViewItemIndex != oldValue else { return }
            
            UserDefaults.standard[.selectedInspectorPaneIndex] = selectedTabViewItemIndex
            self.invalidateRestorableState()
        }
    }
    
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        coder.encode(self.selectedTabViewItemIndex, forKey: #keyPath(selectedTabViewItemIndex))
    }
    
    
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if coder.containsValue(forKey: #keyPath(selectedTabViewItemIndex)) {
            self.selectedTabViewItemIndex = coder.decodeInteger(forKey: #keyPath(selectedTabViewItemIndex))
        }
    }
    
    
    override func viewDidLayout() {
        
        super.viewDidLayout()
        
        if !self.view.inLiveResize {
            UserDefaults.standard[.sidebarWidth] = self.view.frame.width
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
                String(localized: "Document Inspector")
            case .outline:
                String(localized: "Outline")
            case .warnings:
                String(localized: "Warnings")
        }
    }
    
    
    func viewController() -> NSViewController {
        
        switch self {
            case .document:
                NSStoryboard(name: "DocumentInspectorView").instantiateInitialController()!
            case .outline:
                NSStoryboard(name: "OutlineView").instantiateInitialController()!
            case .warnings:
                NSStoryboard(name: "WarningsView").instantiateInitialController()!
        }
    }
    
    
    func image(selected: Bool = false) -> NSImage? {
        
        NSImage(systemSymbolName: selected ? self.selectedImageName : self.imageName,
                accessibilityDescription: self.name)?
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
