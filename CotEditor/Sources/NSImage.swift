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
//  © 2020-2022 1024jp
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
    
    /// Return a copy of the image tinted with the color.
    ///
    /// - Parameter color: The color to tint the image.
    /// - Returns: A tinted image.
    func tinted(with color: NSColor) -> Self {
        
        assert(self.isTemplate, "An image to tint should be a template image.")
        
        let image = Self(size: self.size, flipped: false) { [image = self.copy() as! Self] (dstRect) -> Bool in
            
            image.draw(in: dstRect)
            
            color.setFill()
            dstRect.fill(using: .sourceIn)
            
            return true
        }
        
        image.capInsets = self.capInsets
        image.alignmentRect = self.alignmentRect
        
        return image
    }
    
}



extension NSAttributedString {
    
    convenience init(systemSymbolName: String, configuration: NSImage.SymbolConfiguration? = nil, accessibilityDescription: String? = nil) {
        
        let attachment = NSTextAttachment()
        attachment.image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: accessibilityDescription)?
            .withSymbolConfiguration(configuration ?? .init())
        
        self.init(attachment: attachment)
    }
    
}
