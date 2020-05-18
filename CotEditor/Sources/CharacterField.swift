//
//  CharacterField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2020 1024jp
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
import CoreText

final class CharacterField: NSTextField {
    
    // MARK: Text Field Methods
    
    /// required size
    override var intrinsicContentSize: NSSize {
        
        return self.attributedStringValue.pathBounds.integral.size
    }
    
}



final class CharacterFieldCell: NSTextFieldCell {
    
    // MARK: Text Field Cell Methods
    
    /// draw inside of field with CoreText
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        guard let context = NSGraphicsContext.current?.cgContext else { return assertionFailure() }
        
        NSGraphicsContext.saveGraphicsState()
        
        let line = CTLineCreateWithAttributedString(self.attributedStringValue as CFAttributedString)
        let pathBounds = self.attributedStringValue.pathBounds.integral
        
        // avoid flipping drawing when popover detached
        if controlView.isFlipped {
            context.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)
        }
        context.textPosition = CGPoint(x: (cellFrame.width - pathBounds.width) / 2 - pathBounds.minX,
                                       y: (cellFrame.height - pathBounds.height) / 2 + pathBounds.maxY)
        
        CTLineDraw(line, context)
        
        #if DEBUG
        NSColor.tertiaryLabelColor.set()
        cellFrame.frame(withWidth: 0.5)
        NSRect(x: (cellFrame.width - pathBounds.width) / 2,
               y: (cellFrame.height - pathBounds.height) / 2,
               width: pathBounds.width,
               height: pathBounds.height).frame()
        #endif
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
}



private extension NSAttributedString {
    
    var pathBounds: NSRect {
        
        let line = CTLineCreateWithAttributedString(self as CFAttributedString)
        
        return CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds, .excludeTypographicLeading, .excludeTypographicShifts])
    }
    
}
