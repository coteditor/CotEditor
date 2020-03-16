//
//  MonosizeToolbar.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-09-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

final class MonosizeToolbar: NSToolbar {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var window: NSWindow?
    
    
    
    // MARK: Toolbar Methods
    
    override var sizeMode: NSToolbar.SizeMode {
        
        get {
            return .regular
        }
        
        set {
            _ = newValue
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
        if
            let contextMenu = self.window?.contentView?.superview?.menu,
            let menuItem = contextMenu.items.first(where: { $0.action?.string == "toggleUsingSmallToolbarIcons:" })
        {
            contextMenu.removeItem(menuItem)
        }
    }
    
    
    /// display toolbar customization sheet
    @IBAction override func runCustomizationPalette(_ sender: Any?) {
        
        super.runCustomizationPalette(sender)
        
        // fallback for removing "Use small size" button in `window(:willPositionSheet:using)`
        if let sheet = self.window?.attachedSheet {
            sheet.contentView?.removeSmallSizeButton()
        }
    }
    
}



extension DocumentWindowController {
    
    /// remove "Use small size" button before showing the customization sheet
    func window(_ window: NSWindow, willPositionSheet sheet: NSWindow, using rect: NSRect) -> NSRect {
        
        if sheet.className == "NSToolbarConfigPanel" {
            sheet.contentView?.removeSmallSizeButton()
        }
        
        return rect
    }
    
}



private extension NSView {
    
    /// remove "Use small size" button in the toolbar customization sheet
    func removeSmallSizeButton() {
        
        let toggleButton: NSButton? = self.descendants.lazy
            .compactMap { $0 as? NSButton }
            .first { $0.action?.string == "toggleUsingSmallToolbarIcons:" }
        
        toggleButton?.isHidden = true
        self.needsDisplay = true
    }
    
    
    /// find all subviews recursively
    private var descendants: [NSView] {
        
        return self.subviews + self.subviews.flatMap(\.descendants)
    }
    
}



private extension Selector {
    
    var string: String {
        
        return NSStringFromSelector(self)
    }
    
}
