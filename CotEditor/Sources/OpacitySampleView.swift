//
//  OpacitySampleView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-06-07.
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

import Cocoa

@IBDesignable
final class OpacitySampleView: NSView {
    
    // MARK: Inspectable Properties
    
    @IBInspectable private var opacity: CGFloat = 0.5
    
    
    
    // MARK: -
    // MARK: View Methods
    
    override func draw(_ dirtyRect: NSRect) {
        
        NSGraphicsContext.saveGraphicsState()
        
        // draw bezel
        moof(self.bounds)
        let baseFrame = self.bounds.insetBy(dx: NSBezierPath.defaultLineWidth / 2,
                                            dy: NSBezierPath.defaultLineWidth / 2)
        let basePath = NSBezierPath(roundedRect: baseFrame, xRadius: 2, yRadius: 2)
        
        NSColor.controlBackgroundColor.setFill()
        basePath.fill()
        NSColor.controlShadowColor.setStroke()
        basePath.stroke()
        
        // draw rectangle
        let insideFrame = self.bounds.insetBy(dx: 2, dy: 2)
        let path = NSBezierPath()
        path.move(to: insideFrame.origin)
        path.line(to: NSPoint(x: insideFrame.minX, y: insideFrame.maxY))
        path.line(to: NSPoint(x: insideFrame.maxX, y: insideFrame.maxY))
        path.close()
        
        NSColor.labelColor.withAlphaComponent(1 - self.opacity).setFill()
        path.fill()
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
}
