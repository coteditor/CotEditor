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

import AppKit

extension NSImage {
    
    /// Return rotated image by the specified degrees around the center.
    ///
    /// The `angle` must be a multiple of 90°; otherwise, parts of the rotated image may be drawn outside the image bounds.
    ///
    /// - Parameter angle: The rotation angle, measured in degrees.
    /// - Returns: A rotated image.
    func rotated(by angle: CGFloat) -> Self {
        
        let rotatedSize: NSSize
        switch angle.remainder(dividingBy: 180) {
            case 0:
                rotatedSize = self.size
            case -90, 90:
                rotatedSize = self.size.rotated
            default:
                assertionFailure("The angle is assumed to be a multiple of 90°.")
                rotatedSize = self.size
        }
        
        let image = Self(size: rotatedSize, flipped: false) { [unowned self] (dstRect) -> Bool in
            
            let transform = NSAffineTransform()
            transform.translateX(by: dstRect.width / 2, yBy: dstRect.height / 2)
            transform.rotate(byDegrees: angle)
            transform.translateX(by: -dstRect.width / 2, yBy: -dstRect.height / 2)
            transform.concat()
            
            self.draw(in: dstRect)
            
            return true
        }
        
        image.isTemplate = self.isTemplate
        
        return image
    }
    
    
    /// Return a copy of the image tinted with the color.
    ///
    /// - Parameter color: The color to tint the image.
    /// - Returns: A tinted image.
    func tinted(color: NSColor) -> Self {
        
        assert(self.isTemplate, "An image to tint should be a template image.")
        
        return Self(size: self.size, flipped: false) { [unowned self] (dstRect) -> Bool in
            
            self.draw(in: dstRect)
            
            color.setFill()
            dstRect.fill(using: .sourceIn)
            
            return true
        }
    }
    
}
