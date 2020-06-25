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
//  © 2018-2020 1024jp
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
    
    weak var openPanel: NSOpenPanel?  // keep open panel for hidden file visivility toggle
    
    
    // MARK: Private Properties
    
    @IBOutlet private weak var encodingMenu: NSPopUpButton?
    
    @objc private dynamic var _selectedEncoding: UInt = 0
    
    
    
    // MARK: -
    // MARK: ViewController Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.buildEncodingPopupButton()
    }
    
    
    
    // MARK: Public Methods
    
    /// encoding selected by user
    var selectedEncoding: String.Encoding {
        
        get { String.Encoding(rawValue: self._selectedEncoding) }
        set { self._selectedEncoding = newValue.rawValue }
    }
    
    
    
    // MARK: Action Messages
    
    /// toggle visivility of hidden files
    @IBAction func toggleShowsHidenFiles(_ sender: NSButton) {
        
        guard let openPanel = self.openPanel else { return assertionFailure() }
        
        let showsHiddenFiles = (sender.integerValue == 1)
        
        openPanel.showsHiddenFiles = showsHiddenFiles
        openPanel.treatsFilePackagesAsDirectories = showsHiddenFiles
    }
    
    
    
    // MARK: Private Methods
    
    /// update encoding menu
    func buildEncodingPopupButton() {
        
        let menu = self.encodingMenu!.menu!
        
        menu.removeAllItems()
        
        let autoDetectItem = NSMenuItem(title: "Automatic".localized, action: nil, keyEquivalent: "")
        autoDetectItem.tag = Int(String.Encoding.autoDetection.rawValue)
        menu.addItem(autoDetectItem)
        menu.addItem(.separator())
        menu.items += EncodingManager.shared.createEncodingMenuItems()
        
        self.selectedEncoding = .autoDetection
    }
    
}
