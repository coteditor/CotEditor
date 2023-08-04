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
import Combine

enum InspectorPane: Int {
    
    case document
    case outline
    case warnings
}


final class InspectorViewController: NSTabViewController {
    
    // MARK: Public Properties
    
    var selectedPane: InspectorPane { InspectorPane(rawValue: self.selectedTabViewItemIndex) ?? .document }
    
    
    // MARK: Private Properties
    
    private var frameObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // select last used pane
        self.selectedTabViewItemIndex = UserDefaults.standard[.selectedInspectorPaneIndex]
        
        // restore thickness first when the view is loaded
        let width = UserDefaults.standard[.sidebarWidth]
        if width > 0 {
            self.view.frame.size.width = width
        }
        self.frameObserver = self.view.publisher(for: \.frame)
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
            .map(\.size.width)
            .removeDuplicates()
            .sink { UserDefaults.standard[.sidebarWidth] = $0 }
        
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
            
            if self.isViewLoaded {  // avoid storing initial state (set in the storyboard)
                UserDefaults.standard[.selectedInspectorPaneIndex] = selectedTabViewItemIndex
                self.invalidateRestorableState()
            }
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
}



extension InspectorViewController: InspectorTabViewDelegate {
    
    func tabView(_ tabView: NSTabView, selectedImageForItem tabViewItem: NSTabViewItem) -> NSImage? {
        
        let index = tabView.indexOfTabViewItem(tabViewItem)
        
        switch InspectorPane(rawValue: index) {
            case .document:
                return NSImage(systemSymbolName: "doc.fill", accessibilityDescription: nil)?
                    .withSymbolConfiguration(.init(pointSize: 0, weight: .semibold))
                
            case .outline:
                return tabViewItem.image?.withSymbolConfiguration(.init(pointSize: 0, weight: .bold))
                
            case .warnings:
                return NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
                    .withSymbolConfiguration(.init(pointSize: 0, weight: .semibold))
                
            case nil:
                preconditionFailure()
        }
    }
}
