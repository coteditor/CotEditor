/*
 
 NSImage+Template.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-11-16.
 
 ------------------------------------------------------------------------------
 
 © 2016-2018 1024jp
 
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

extension NSImage {
    
     /// Return a copy of the image tinted based on controlTint type.
     ///
     /// - parameter controlTint: The tint type to tint the image.
     ///
     /// - returns: A tinted image.
    func tinted(for controlTint: NSControlTint = .defaultControlTint, isKey: Bool) -> NSImage {
        
        let tintColor = isKey ? NSColor(for: .blueControlTint).highlighted : NSColor(for: .blueControlTint)
        
        return self.tinted(color: tintColor)
    }
    
    
    /// Return a copy of the image tinted with the color.
    ///
    ///  - parameter color: The color to tint the image.
    ///
    ///  - returns: A tinted image.
    func tinted(color: NSColor) -> NSImage {
        
        assert(self.isTemplate, "A image to tint should be a template image.")
        
        return NSImage(size: self.size, flipped: false, drawingHandler: { [weak self] dstRect -> Bool in
            guard let strongSelf = self else { return false }
            
            strongSelf.draw(in: dstRect)
            
            color.setFill()
            dstRect.fill(using: .sourceIn)
            
            return true
        })
    }
    
}



private extension NSColor {
    
    var highlighted: NSColor {
        
        return NSColor(deviceHue: self.usingColorSpace(.deviceRGB)!.hueComponent,
                       saturation: 0.91, brightness: 0.96, alpha: 1.0)
    }
    
}
