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
//  © 2018-2022 1024jp
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
    
    // MARK: Public Properties
    
    weak var openPanel: NSOpenPanel?  // keep open panel for hidden file visivility toggle
    
    
    // MARK: Private Properties
    
    @IBOutlet private weak var encodingMenu: NSPopUpButton?
    
    @objc private dynamic var _selectedEncoding: UInt = 0
    
    
    
    // MARK: -
    // MARK: ViewController Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // build encoding menu
        let menu = self.encodingMenu!.menu!
        let autoDetectItem = NSMenuItem(title: "Automatic".localized, action: nil, keyEquivalent: "")
        menu.items = [autoDetectItem, .separator()] + EncodingManager.shared.createEncodingMenuItems()
        
        self.selectedEncoding = nil
    }
    
    
    
    // MARK: Public Methods
    
    /// encoding selected by user
    private(set) var selectedEncoding: String.Encoding? {
        
        get { self._selectedEncoding > 0 ? String.Encoding(rawValue: self._selectedEncoding) : nil }
        set { self._selectedEncoding = newValue?.rawValue ?? 0 }  // 0 for automatic
    }
    
    
    
    // MARK: Action Messages
    
    /// toggle visivility of hidden files
    @IBAction func toggleShowsHiddenFiles(_ sender: NSButton) {
        
        guard let openPanel = self.openPanel else { return assertionFailure() }
        
        let showsHiddenFiles = (sender.integerValue == 1)
        
        openPanel.showsHiddenFiles = showsHiddenFiles
        openPanel.treatsFilePackagesAsDirectories = showsHiddenFiles
        
        openPanel.validateVisibleColumns()
    }
    
}
