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
//  © 2016-2018 1024jp
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

import Cocoa

protocol TabViewControllerDelegate: AnyObject {
    
    func tabViewController(_ viewController: NSTabViewController, didSelect tabViewIndex: Int)
}


final class SidebarViewController: NSTabViewController {
    
    enum TabIndex: Int {
        
        case documentInspector
        case outline
        case incompatibleCharacters
    }
    
    
    // MARK: Public Properties
    
    weak var delegate: TabViewControllerDelegate?
    var selectedTabIndex: TabIndex { return TabIndex(rawValue: self.selectedTabViewItemIndex) ?? .documentInspector }
    
    
    // MARK: Private Properties
    
    @IBOutlet private weak var documentInspectorTabViewItem: NSTabViewItem?
    @IBOutlet private weak var outlineTabViewItem: NSTabViewItem?
    @IBOutlet private weak var incompatibleCharactersTabViewItem: NSTabViewItem?
    
    
    
    // MARK: -
    // MARK: Tab View Controller Methods
    
    /// prepare tabs
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // bind segmentedControl manually  (2016-09 on macOS 10.12)
        if let segmentedControl = (self.tabView as? InspectorTabView)?.segmentedControl {
            segmentedControl.bind(.selectedIndex, to: self, withKeyPath: #keyPath(selectedTabViewItemIndex))
        }
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("inspector".localized)
    }
    
    
    /// restore last state
    override class var restorableStateKeyPaths: [String] {
        
        return super.restorableStateKeyPaths + [#keyPath(selectedTabViewItemIndex)]
    }
    
    
    /// deliver passed-in document instance to child view controllers
    override var representedObject: Any? {
        
        didSet {
            guard let document = representedObject as? Document else { return }
            
            self.documentInspectorTabViewItem?.viewController?.representedObject = document.analyzer
            self.outlineTabViewItem?.viewController?.representedObject = document
            self.incompatibleCharactersTabViewItem?.viewController?.representedObject = document.incompatibleCharacterScanner
        }
    }
    
    
    override var selectedTabViewItemIndex: Int {
        
        didSet {
            guard selectedTabViewItemIndex != oldValue else { return }
            
            self.delegate?.tabViewController(self, didSelect: self.selectedTabViewItemIndex)
        }
    }
    
}
