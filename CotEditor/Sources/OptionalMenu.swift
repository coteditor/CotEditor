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
//  © 2022-2023 1024jp
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

/// Menu dynamically shows optional menu items by pressing the Option key.
///
/// Optional items should have an empty key equivalent and the Option key only modifier key.
final class OptionalMenu: NSMenu, NSMenuDelegate {
    
    // MARK: Private Properties
    
    private var trackingTimer: Timer?
    private var isShowingOptionalItems = false
    
    
    // MARK: Lifecycle
    
    required init(coder: NSCoder) {
        
        super.init(coder: coder)
        
        self.delegate = self
    }
    
    
    // MARK: Menu Delegate Methods
    
    func menuWillOpen(_ menu: NSMenu) {
        
        self.update()  // UI validation is performed here
        self.validateKeyEvent(force: true)
        
        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(validateKeyEvent), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .eventTracking)
        self.trackingTimer = timer
    }
    
    
    func menuDidClose(_ menu: NSMenu) {
        
        self.trackingTimer?.invalidate()
        self.updateOptionalItems(shows: false)
    }
    
    
    // MARK: Private Functions
    
    /// Check the state of the modifier key press and update the item visibility.
    ///
    /// - Parameter force: Whether forcing to update the item visibility.
    @objc private func validateKeyEvent(force: Bool = false) {
        
        let shows = NSEvent.modifierFlags.contains(.option)
        
        guard force || shows != self.isShowingOptionalItems else { return }
        
        self.updateOptionalItems(shows: shows)
    }
    
    
    /// Update the visibility of optional items.
    ///
    /// - Parameter shows: `true` to show optional items.
    private func updateOptionalItems(shows: Bool) {
        
        for item in self.items {
            guard
                item.isEnabled,
                item.keyEquivalentModifierMask == .option,
                item.keyEquivalent.isEmpty
            else { continue }
            
            item.isHidden = (item.state == .off) && !shows
        }
        
        self.isShowingOptionalItems = shows
    }
}
