//
//  PopUpToolbarItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-11-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2018 1024jp
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

final class PopUpToolbarItem: NSToolbarItem {
    
    // MARK: Toolbar Item Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        let popUpButton = self.popUpButton!
        
        // setup popup menu for "Text Only" mode
        let item = NSMenuItem()
        item.submenu = popUpButton.menu
        item.title = self.label
        
        self.menuFormRepresentation = item
    }
    
    
    
    // MARK: Private Methods
    
    var popUpButton: NSPopUpButton? {
        
        return self.view as? NSPopUpButton
    }
    
}
