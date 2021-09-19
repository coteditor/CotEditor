//
//  SidebarViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2021 1024jp
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

import Combine
import Cocoa

final class SidebarViewController: NSTabViewController {
    
    enum TabIndex: Int {
        
        case documentInspector
        case outline
        case incompatibleCharacters
    }
    
    
    // MARK: Public Properties
    
    var selectedTabIndex: TabIndex { TabIndex(rawValue: self.selectedTabViewItemIndex) ?? .documentInspector }
    
    
    // MARK: Private Properties
    
    private var frameObserver: AnyCancellable?
    
    @IBOutlet private weak var documentInspectorTabViewItem: NSTabViewItem?
    @IBOutlet private weak var outlineTabViewItem: NSTabViewItem?
    @IBOutlet private weak var incompatibleCharactersTabViewItem: NSTabViewItem?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// prepare tabs
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // select last used pane
        self.selectedTabViewItemIndex = UserDefaults.standard[.selectedInspectorPaneIndex]
        
        // bind segmentedControl manually  (2016-09 on macOS 10.12)
        (self.tabView as! InspectorTabView).segmentedControl.bind(.selectedIndex, to: self, withKeyPath: #keyPath(selectedTabViewItemIndex))
        
        // restore thickness first when the view is loaded
        let sidebarWidth = UserDefaults.standard[.sidebarWidth]
        if sidebarWidth > 0 {
            self.view.frame.size.width = sidebarWidth
            // apply also to .tabView that is the only child of .view
            self.view.layoutSubtreeIfNeeded()
        }
        self.frameObserver = self.view.publisher(for: \.frame)
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .map(\.size.width)
            .removeDuplicates()
            .sink { UserDefaults.standard[.sidebarWidth] = $0 }
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("inspector".localized)
    }
    
    
    
    // MARK: Tab View Controller Methods
    
    /// keys to be restored from the last session
    override class var restorableStateKeyPaths: [String] {
        
        return super.restorableStateKeyPaths + [
            #keyPath(selectedTabViewItemIndex),
        ]
    }
    
    
    /// deliver passed-in document instance to child view controllers
    override var representedObject: Any? {
        
        didSet {
            for item in self.tabViewItems {
                item.viewController?.representedObject = representedObject as? Document
            }
        }
    }
    
    
    override var selectedTabViewItemIndex: Int {
        
        didSet {
            guard selectedTabViewItemIndex != oldValue else { return }
            
            if self.isViewLoaded {  // avoid storing initial state (set in the storyboard)
                UserDefaults.standard[.selectedInspectorPaneIndex] = selectedTabViewItemIndex
            }
        }
    }
    
}



extension SidebarViewController: InspectorTabViewDelegate {
    
    func tabView(_ tabView: NSTabView, selectedImageForItem tabViewItem: NSTabViewItem) -> NSImage? {
        
        switch tabViewItem {
            case self.documentInspectorTabViewItem:
                return NSImage(systemSymbolName: "doc.fill", accessibilityDescription: nil)?
                    .withSymbolConfiguration(.init(pointSize: 0, weight: .semibold))
                
            case self.outlineTabViewItem:
                return nil  // -> bold version
                
            case self.incompatibleCharactersTabViewItem:
                return NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)?
                    .withSymbolConfiguration(.init(pointSize: 0, weight: .semibold))
                
            default:
                preconditionFailure()
        }
    }
    
}
