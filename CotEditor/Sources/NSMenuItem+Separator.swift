//
//  NSMenuItem+Separator.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

extension NSMenuItem {
    
    class func seriesableSeparator() -> NSMenuItem {
        
        let view = SeparatorMenuItemView(frame: NSRect(x: 0, y: 0, width: 0, height: 11))
        view.autoresizingMask = [.width]
        
        let item = NSMenuItem(title: .separator, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.view = view
        
        return item
    }
    
}



private final class SeparatorMenuItemView: NSView {
    
    override func viewWillDraw() {
        
        // avoid shrinking drawing area width when a modifier key is pressed,
        // and the titles of all other menu items in the same menu are shorter than the menu content width
        if let width = self.enclosingMenuItem?.menu?.size.width {
            self.frame.size.width = width
        }
        
        super.viewWillDraw()
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        NSGraphicsContext.saveGraphicsState()
        
        NSColor(calibratedWhite: 0, alpha: 0.1).setFill()
        NSBezierPath.fill(NSRect(x: dirtyRect.minX, y: floor(self.frame.midY) - 1, width: dirtyRect.width, height: 2))
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
}
