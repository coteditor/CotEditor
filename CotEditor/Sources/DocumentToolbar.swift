/*
 
 DocumentToolbar.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-09-03.
 
 ------------------------------------------------------------------------------
 
 © 2016-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class DocumentToolbar: NSToolbar, NSWindowDelegate {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var window: NSWindow?
    
    
    
    // MARK: Toolbar Methods
    
    override var sizeMode: NSToolbar.SizeMode {
        
        get {
            return .regular
        }
        set {
            super.sizeMode = .regular
        }
    }
    
    
    /// remove "Use Small Size" menu item in context menu
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // This is really dirty way but works.
        //   -> It actually doesn't matter if "Use Small Size" menu item cannot be removed.
        //      What really matter is crash, or any other unwanted side effects. So, be careful.
        // cf. https://forums.developer.apple.com/thread/21887
        
        guard
            let superview = self.window?.contentView?.superview,
            let contextMenu = superview.menu
            else { return }
        
        // find "Use Small Size" menu item
        guard let menuItem = contextMenu.items.first(where: {
            guard let action = $0.action else { return false }
            return NSStringFromSelector(action) == "toggleUsingSmallToolbarIcons:"
        }) else { return }
        
        // remove separator
        let index = contextMenu.index(of: menuItem)
        if contextMenu.item(at: index + 1) == NSMenuItem.separator() {
            contextMenu.removeItem(at: index + 1)
        }
        
        // remove item
        contextMenu.removeItem(menuItem)
    }
    
    
    /// display toolbar customization sheet
    @IBAction override func runCustomizationPalette(_ sender: Any?) {
        
        super.runCustomizationPalette(sender)
        
        // fallback for removing "Use small size" button in `window(:willPositionSheet:using)`
        if let sheet = self.window?.attachedSheet {
            self.removeSmallSizeButton(in: sheet)
        }
    }
    
    
    
    // MARK: Window Delegate
    
    /// remove "Use small size" button before showing the customization sheet
    func window(_ window: NSWindow, willPositionSheet sheet: NSWindow, using rect: NSRect) -> NSRect {
        
        if sheet.className == "NSToolbarConfigPanel" {
            self.removeSmallSizeButton(in: sheet)
        }
        
        return rect
    }
    
    
    
    // MARK: Private Methods
    
    /// remove "Use small size" button in the customization sheet
    private func removeSmallSizeButton(in sheet: NSWindow) {
        
        guard let views = sheet.contentView?.subviews else { return }
        
        // From macOS 10.13, the button is placed inside of a NSStackView
        let subviews = views.flatMap { $0.subviews }

        let toggleButton: NSButton? = (views + subviews).lazy
            .compactMap { $0 as? NSButton }
            .first { button in
                guard let action = button.action else { return false }
                
                return NSStringFromSelector(action) == "toggleUsingSmallToolbarIcons:"
            }
        
        toggleButton?.isHidden = true
        sheet.contentView?.needsDisplay = true
    }
    
}
