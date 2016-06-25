/*
 
 BackgroundView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-01-09.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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

@IBDesignable class BackgroundView: NSView {
    
    // MARK: Public Properties
    
    @IBInspectable var fillColor: NSColor = .windowBackgroundColor()
    
    
    
    // MARK:
    // MARK: View Methods
    
    /// draw inside
    override func draw(_ dirtyRect: NSRect) {
        
        NSGraphicsContext.saveGraphicsState()
        
        self.fillColor.setFill()
        NSBezierPath.fill(dirtyRect)
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    /// whether it's an opaque view
    override var isOpaque: Bool {
        
        return true
    }
    
}
