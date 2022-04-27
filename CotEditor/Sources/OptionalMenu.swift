//
//  OptionalMenu.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-02-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

/// Menu dinamically shows optional menu items by pressing the Option key.
///
/// Optional items sould have an empty key equivalent and the Option key only modifier key.
final class OptionalMenu: NSMenu, NSMenuDelegate {
    
    // MARK: Private Properties
    
    private var trackingTimer: Timer?
    
    
    
    // MARK: Menu Methods
    
    required init(coder: NSCoder) {
        
        super.init(coder: coder)
        
        self.delegate = self
    }
    
    
    override func update() {
        
        super.update()  // validation performs here
        
        let isOptionPressed = NSEvent.modifierFlags.contains(.option)
        for item in self.items where item.isEnabled {
            let isOptional = item.keyEquivalentModifierMask == .option && item.keyEquivalent.isEmpty
            item.isHidden = isOptional && item.state == .off && !isOptionPressed
        }
    }
    
    
    // MARK: Menu Delegate Methods
    
    func menuWillOpen(_ menu: NSMenu) {
        
        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .eventTracking)
        self.trackingTimer = timer
    }
    
    
    func menuDidClose(_ menu: NSMenu) {
        
        self.trackingTimer?.invalidate()
    }
    
}
