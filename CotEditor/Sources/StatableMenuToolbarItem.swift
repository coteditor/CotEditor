//
//  StatableMenuToolbarItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-06-18.
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

import AppKit

final class StatableMenuToolbarItem: NSMenuToolbarItem, StatableItem, Validatable {
    
    // MARK: Public Properties
    
    var state: NSControl.StateValue = .on  { didSet { self.invalidateImage() } }
    var stateImages: [NSControl.StateValue: NSImage] = [:]  { didSet { self.invalidateImage() } }
    
    
    
    // MARK: -
    // MARK: Toolbar Item Methods
    
    override var image: NSImage? {
        
        get { super.image }
        @available(*, unavailable, message: "Set images through 'stateImages' instead.") set {  }
    }
    
    
    override func validate() {
        
        self.isEnabled = self.validate()
    }
    
    
    
    // MARK: Private Methods
    
    private func invalidateImage() {
        
        assert(self.state != .mixed)
        
        super.image = self.stateImages[self.state]
    }
    
}
