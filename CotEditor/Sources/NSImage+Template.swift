//
//  NSImage+Template.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-11-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2018 1024jp
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

extension NSImage {
    
    /// Return a copy of the image tinted with the color.
    ///
    /// - Parameter color: The color to tint the image.
    /// - Returns: A tinted image.
    func tinted(color: NSColor) -> NSImage {
        
        assert(self.isTemplate, "A image to tint should be a template image.")
        
        return NSImage(size: self.size, flipped: false, drawingHandler: { [weak self] dstRect -> Bool in
            guard let self = self else { return false }
            
            self.draw(in: dstRect)
            
            color.setFill()
            dstRect.fill(using: .sourceIn)
            
            return true
        })
    }
    
}



extension NSColor {
    
    /// Provide a color similar (as possible) to one used for template images in highlighted buttons
    /// by taking window state into consideration.
    ///
    /// - Parameter view: The view the returned color will be drawn to.
    /// - Returns: A color for highlight.
    static func accentColor(for view: NSView) -> NSColor {
        
        assert(view.window?.colorSpace != nil)
        
        let controlTintColor = self.init(for: .blueControlTint)
        
        guard
            let window = view.window,
            let color = controlTintColor.usingColorSpace(window.colorSpace ?? .deviceRGB)
            else { return controlTintColor }
        
        return window.isKeyWindow
            ? NSColor(deviceHue: color.hueComponent, saturation: 1, brightness: 1, alpha: 1)
            : color
    }
    
}
