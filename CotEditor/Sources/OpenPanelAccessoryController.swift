//
//  OpenPanelAccessoryController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

final class OpenPanelAccessoryController: NSViewController {
    
    @objc dynamic var showsHiddenFiles = false  // binding
    
    
    // MARK: Private Properties
    
    private weak var openPanel: NSOpenPanel?
    
    @IBOutlet private weak var encodingMenu: NSPopUpButton?
    
    @objc private dynamic var _selectedEncoding: UInt = 0
    
    
    
    
    // MARK: -
    // MARK: Public Methods
    
    /// String.Encoding accessor for encoding user selected in open panel
    var selectedEncoding: String.Encoding {
        
        get {
            return String.Encoding(rawValue: self._selectedEncoding)
        }
        set {
            self._selectedEncoding = newValue.rawValue
        }
    }
    
    
    func prepare(openPanel: NSOpenPanel) {
        
        self.buildEncodingPopupButton()
        
        openPanel.accessoryView = self.view
        self.openPanel = openPanel
        
        // set visibility of hidden files in the panel
        openPanel.showsHiddenFiles = self.showsHiddenFiles
        openPanel.treatsFilePackagesAsDirectories = self.showsHiddenFiles
        
        // -> bind showsHiddenFiles flag with openPanel
        openPanel.bind(NSBindingName(#keyPath(NSOpenPanel.showsHiddenFiles)), to: self, withKeyPath: #keyPath(showsHiddenFiles))
        openPanel.bind(NSBindingName(#keyPath(NSOpenPanel.treatsFilePackagesAsDirectories)), to: self, withKeyPath: #keyPath(showsHiddenFiles))
    }
    
    
    func tearDown() {
        
        self.showsHiddenFiles = false  // reset flag
        
        self.openPanel?.unbind(NSBindingName(#keyPath(NSOpenPanel.showsHiddenFiles)))
        self.openPanel?.unbind(NSBindingName(#keyPath(NSOpenPanel.treatsFilePackagesAsDirectories)))
    }
    
    
    
    // MARK: Private Methods
    
    
    /// update encoding menu in the open panel
    func buildEncodingPopupButton() {
        
        let menu = self.encodingMenu!.menu!
        
        menu.removeAllItems()
        
        let autoDetectItem = NSMenuItem(title: NSLocalizedString("Auto-Detect", comment: ""), action: nil, keyEquivalent: "")
        autoDetectItem.tag = Int(String.Encoding.autoDetection.rawValue)
        menu.addItem(autoDetectItem)
        menu.addItem(.separator())
        
        let items = EncodingManager.shared.createEncodingMenuItems()
        for item in items {
            menu.addItem(item)
        }
        
        self.selectedEncoding = .autoDetection
    }
    
}
