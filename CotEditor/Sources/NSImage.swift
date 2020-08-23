//
//  NSImage.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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
    
    /// Return the system symbol image object with backward compatibility for macOS 10.15.
    ///
    /// Just like the Interface Builder, use bundled recoure image with the same name for unsupported systems.
    ///
    /// - Parameters:
    ///   - name: The name of image both for SF Symbols and image resorce.
    ///   - accessibilityDescription: The accessibility description.
    @available(macOS, deprecated: 11)
    convenience init?(symbolNamed name: String, accessibilityDescription: String?) {
        
        if #available(macOS 11, *)  {
            self.init(systemSymbolName: name, accessibilityDescription: accessibilityDescription)
        } else {
            self.init(named: name)
        }
    }
    
    
    /// Return a copy of the image tinted with the color.
    ///
    /// - Parameter color: The color to tint the image.
    /// - Returns: A tinted image.
    func tinted(with color: NSColor) -> Self {
        
        assert(self.isTemplate, "An image to tint should be a template image.")
        
        return Self(size: self.size, flipped: false) { [image = self.copy() as! Self] (dstRect) -> Bool in
            
            image.draw(in: dstRect)
            
            color.setFill()
            dstRect.fill(using: .sourceIn)
            
            return true
        }
    }
    
}
