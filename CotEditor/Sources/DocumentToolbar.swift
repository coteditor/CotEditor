/*
 
 DocumentToolbar.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-09-03.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

class DocumentToolbar: NSToolbar {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var window: NSWindow?
    
    
    
    // MARK: Toolbar Methods
    
    override var sizeMode: NSToolbarSizeMode {
        
        get {
            return .regular
        }
        set { /* ignore */ }
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
            let contextMenu = superview.menu ?? superview.subviews.last?.menu  // second one is for OS X 10.10 Mavericks
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
    override func runCustomizationPalette(_ sender: Any?) {
        
        super.runCustomizationPalette(sender)
        
        guard
            let window = self.window,
            let sheet = window.attachedSheet,
            let views = sheet.contentView?.subviews else { return }
        
        let toggleButton: NSButton? = views.lazy
            .flatMap { $0 as? NSButton }
            .filter { (button: NSButton) -> Bool in
                guard
                    let buttonTypeValue = button.cell?.value(forKey: "buttonType") as? UInt,
                    let buttonType = NSButtonType(rawValue: buttonTypeValue)
                    else { return false }
                
                return buttonType == .switch
            }
            .first
        
        toggleButton?.isHidden = true
        sheet.contentView?.needsDisplay = true
    }
    
}
