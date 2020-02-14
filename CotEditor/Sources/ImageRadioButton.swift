//
//  ImageRadioButton.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-11-11.
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

@IBDesignable
final class ImageRadioButton: NSButton {
    
    // MARK: Inspectable Properties
    
    @IBInspectable private var leadingImage: NSImage?
    
    
    
    // MARK: -
    // MARK: Button Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // prepend image to the label
        let attachment = NSTextAttachment(image: self.leadingImage!)
        
        self.attributedTitle = NSAttributedString(attachment: attachment)
            + NSAttributedString(string: " ")
            + self.attributedTitle
    }
    
}



// MARK: -

private extension NSTextAttachment {
    
    /// create text attachment by considering whether image should be drawn as a template image
    convenience init(image: NSImage) {
        
        self.init()
        
        if image.isTemplate {
            self.image = NSImage(size: image.size, flipped: false) { (dstRect) -> Bool in
                
                image.draw(in: dstRect)
                
                NSColor.labelColor.setFill()
                dstRect.fill(using: .sourceIn)
                
                return true
            }
            
        } else {
            self.image = image
        }
    }
    
}
