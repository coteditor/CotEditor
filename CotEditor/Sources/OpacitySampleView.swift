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
//  © 2018-2020 1024jp
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
    
    
    // MARK: Private Properties
    
    private let cornerRadius: CGFloat = 4
    private let padding: CGFloat = 3
    
    
    
    // MARK: -
    // MARK: View Methods
    
    override func draw(_ dirtyRect: NSRect) {
        
        NSGraphicsContext.saveGraphicsState()
        
        // draw bezel
        let baseFrame = self.bounds.insetBy(dx: NSBezierPath.defaultLineWidth / 2,
                                            dy: NSBezierPath.defaultLineWidth / 2)
        let basePath = NSBezierPath(roundedRect: baseFrame,
                                    xRadius: self.cornerRadius,
                                    yRadius: self.cornerRadius)
        
        NSColor.controlBackgroundColor.setFill()
        basePath.fill()
        NSColor.gridColor.setStroke()
        basePath.stroke()
        
        // draw triangle
        let innerFrame = self.bounds.insetBy(dx: self.padding, dy: self.padding)
        let path = NSBezierPath()
        path.move(to: innerFrame.origin)
        path.line(to: NSPoint(x: innerFrame.minX, y: innerFrame.maxY))
        path.line(to: NSPoint(x: innerFrame.maxX, y: innerFrame.maxY))
        path.close()
        
        let innerRadius = max(self.cornerRadius - self.padding, 0)
        let clip = NSBezierPath(roundedRect: innerFrame, xRadius: innerRadius, yRadius: innerRadius)
        path.append(clip)
        path.setClip()
        
        NSColor.labelColor.withAlphaComponent(1 - self.opacity).setFill()
        path.fill()
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
}
