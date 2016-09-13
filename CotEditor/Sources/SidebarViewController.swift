/*
 
 SidebarViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-05.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class SidebarViewController: NSTabViewController {
    
    enum TabIndex: Int {
        
        case documentInspector
        case incompatibleCharacters
    }
    
    // MARK: Private Properties
    
    private weak var documentInspectorTabViewItem: NSTabViewItem?
    private weak var incompatibleCharactersTabViewItem: NSTabViewItem?
    
    
    
    // MARK:
    // MARK: Tab View Controller Methods
    
    /// prepare tabs
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let documentInspectorTabViewItem = NSTabViewItem(viewController: DocumentInspectorViewController())
        let incompatibleCharactersTabViewItem = NSTabViewItem(viewController: IncompatibleCharactersViewController())
        
        documentInspectorTabViewItem.image = #imageLiteral(resourceName: "DocumentTemplate")
        incompatibleCharactersTabViewItem.image = #imageLiteral(resourceName: "ConflictsTemplate")
        documentInspectorTabViewItem.toolTip = NSLocalizedString("Document Inspector", comment: "")
        incompatibleCharactersTabViewItem.toolTip = NSLocalizedString("Incompatible Characters", comment: "")
        
        self.addTabViewItem(documentInspectorTabViewItem)
        self.addTabViewItem(incompatibleCharactersTabViewItem)
        
        self.documentInspectorTabViewItem = documentInspectorTabViewItem
        self.incompatibleCharactersTabViewItem = incompatibleCharactersTabViewItem
    }
    
    
    /// deliver passed-in document instance to child view controllers
    override var representedObject: Any? {
        
        didSet {
            guard let document = representedObject as? Document else { return }
            
            self.documentInspectorTabViewItem?.viewController?.representedObject = document.analyzer
            self.incompatibleCharactersTabViewItem?.viewController?.representedObject = document.incompatibleCharacterScanner
        }
    }
    
}
