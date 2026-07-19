//
//  MenuButton.swift
//  MacUI
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-07-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

public import AppKit

/// A button that immediately shows its menu on mouse down like a pull-down button.
public final class MenuButton: NSButton {
    
    // MARK: Button Methods
    
    public override func mouseDown(with event: NSEvent) {
        
        guard self.isEnabled, self.menu != nil else { return super.mouseDown(with: event) }
        
        self.showMenu()
    }
    
    
    public override func performClick(_ sender: Any?) {
        
        guard self.menu != nil else { return super.performClick(sender) }
        
        self.showMenu()
    }
    
    
    public override func accessibilityRole() -> NSAccessibility.Role? {
        
        (self.menu != nil) ? .menuButton : super.accessibilityRole()
    }
    
    
    public override func accessibilityPerformPress() -> Bool {
        
        guard self.isEnabled, self.menu != nil else { return super.accessibilityPerformPress() }
        
        // show the menu asynchronously to return the response immediately
        // because the menu tracking blocks the main run loop
        DispatchQueue.main.async { [weak self] in
            self?.showMenu()
        }
        
        return true
    }
    
    
    public override func accessibilityPerformShowMenu() -> Bool {
        
        self.accessibilityPerformPress()
    }
    
    
    // MARK: Private Methods
    
    /// Shows the receiver's menu below the button.
    private func showMenu() {
        
        guard let menu = self.menu else { return }
        
        self.highlight(true)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: self.bounds.maxY + 4), in: self)
        self.highlight(false)
    }
}
