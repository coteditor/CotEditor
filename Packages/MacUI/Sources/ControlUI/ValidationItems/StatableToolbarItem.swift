//
//  NSToolbarItem+Statable.swift
//  ControlUI
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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

public final class StatableToolbarItem: NSToolbarItem, StatableItem {
    
    // MARK: Public Properties
    
    public var state: NSControl.StateValue = .off  { didSet { self.invalidateImage() } }
    public var stateImages: [NSControl.StateValue: NSImage] = [:]  { didSet { self.invalidateImage() } }
    
    
    // MARK: Toolbar Item Methods
    
    public override var image: NSImage? {
        
        get { super.image }
        @available(*, unavailable, message: "Set images through 'stateImages' instead.") set { }
    }
    
    
    // MARK: Private Methods
    
    /// Invalidates `.image` according to the `.state`.
    private func invalidateImage() {
        
        assert(self.state != .mixed)
        
        super.image = self.stateImages[self.state]
    }
}
