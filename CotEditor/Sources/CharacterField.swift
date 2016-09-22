/*
 
 CharacterField.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-11-21.
 
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

final class CharacterField: NSTextField {
    
    // MARK: Text Field Methods
    
    /// determine size
    override var intrinsicContentSize: NSSize {
        
        var size = super.intrinsicContentSize
        let textBounds = self.attributedStringValue.bounds.integral
        
        if let font = self.font {
            size.width = max(font.pointSize, size.width)
        }
        size.height = max(size.height, textBounds.height) + 1
        
        return size
    }
    
}



final class CharacterFieldCell: NSTextFieldCell {
    
    /// rect of content text
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        
        var titleRect = super.titleRect(forBounds: rect)
        let textBounds = self.attributedStringValue.bounds.integral
        
        titleRect.origin.y = -textBounds.minY
        titleRect.size.height = max(textBounds.height, titleRect.height)
        
        return titleRect
    }
    
    
    /// draw inside of field
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        self.attributedStringValue.draw(in: self.titleRect(forBounds: cellFrame))
    }
    
}



private extension NSAttributedString {
    
    var bounds: NSRect {
        
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage(attributedString: self)
        let textContainer = NSTextContainer(containerSize: .infinite)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
    
}
