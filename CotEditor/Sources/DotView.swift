//
//  DotView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2022 1024jp
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

@IBDesignable
final class DotView: NSView {
    
    // MARK: Inspectable Properties
    
    @IBInspectable @Invalidating(.display) var color: NSColor = .labelColor
    @IBInspectable @Invalidating(.display, .intrinsicContentSize) var dotLength: CGFloat = 4
    
    
    
    // MARK: -
    // MARK: View Methods
    
    override var intrinsicContentSize: NSSize {
        
        NSSize(width: self.dotLength * 4, height: self.dotLength * 4)
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        assert(self.dotLength <= self.bounds.width)
        assert(self.dotLength <= self.bounds.height)
        
        let rect = NSRect(x: (self.bounds.width - self.dotLength) / 2,
                          y: (self.bounds.height - self.dotLength) / 2,
                          width: self.dotLength,
                          height: self.dotLength)
        
        NSGraphicsContext.saveGraphicsState()
        
        self.color.setFill()
        NSBezierPath(ovalIn: rect).fill()
        
        NSGraphicsContext.restoreGraphicsState()
    }
}
