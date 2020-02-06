//
//  Typesetter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-12-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2020 1024jp
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

final class Typesetter: NSATSTypesetter {
    
    // MARK: ATS Typesetter Methods
    
    /// adjust vertical position to keep line height always even
    override func willSetLineFragmentRect(_ lineRect: UnsafeMutablePointer<NSRect>, forGlyphRange glyphRange: NSRange, usedRect: UnsafeMutablePointer<NSRect>, baselineOffset: UnsafeMutablePointer<CGFloat>) {
        
        guard let manager = self.layoutManager as? LayoutManager else { return assertionFailure() }
        
        // avoid inconsistent line height by a composite font
        // -> The line height by normal input keeps consistant when overriding the related methods in NSLayoutManager.
        //    but then, the drawing won't be update properly when the font or line hight is changed.
        // -> NSParagraphStyle's `.lineheightMultiple` can also control the line height,
        //    but it causes an issue when the first character of the string uses a fallback font.
        lineRect.pointee.size.height = manager.lineHeight
        usedRect.pointee.size.height = manager.lineHeight
        
        // avoid baseline shifting when the glyph height is higher than the fixed line height, such as 𓆏.
        baselineOffset.pointee = manager.defaultBaselineOffset
    }
    
    
    /// customize behavior by control glyph
    override func actionForControlCharacter(at charIndex: Int) -> NSTypesetterControlCharacterAction {
        
        let action = super.actionForControlCharacter(at: charIndex)
        
        if action.contains(.zeroAdvancementAction),
            let manager = self.layoutManager as? LayoutManager,
            manager.showsOtherInvisibles,
            manager.showsInvisibles,
            let character = (self.attributedString?.string as NSString?)?.character(at: charIndex),
            let unicode = Unicode.Scalar(character),
            unicode.properties.generalCategory == .control || unicode == .zeroWidthSpace
        {
            return .whitespaceAction  // -> Then, the glyph width can be modified on `boundingBox(forControlGlyphAt:...)`.
        }
        
        return action
    }
    
    
    /// return bounding box for control glyph
    override func boundingBox(forControlGlyphAt glyphIndex: Int, for textContainer: NSTextContainer, proposedLineFragment proposedRect: NSRect, glyphPosition: NSPoint, characterIndex charIndex: Int) -> NSRect {
        
        guard let manager = self.layoutManager as? LayoutManager else { return .zero }
        
        // make blank space to draw a replacement character in LayoutManager later.
        var rect = proposedRect
        rect.size.width = manager.replacementGlyphWidth
        
        return rect
    }
    
    
    /// avoid soft wrapping just after an indent
    override func shouldBreakLine(byWordBeforeCharacterAt charIndex: Int) -> Bool {
        
        guard
            charIndex > 0,
            let string = self.attributedString?.string as NSString?
            else { return true }
        
        // check if the character is the first non-whitespace character after indent
        for index in stride(from: charIndex, through: 0, by: -1) {
            let character = string.character(at: index)
            
            switch character {
            case 0x0020, 0x0009:  // SPACE, HORIONTAL TAB
                continue
            case 0x000A:  // LINE FEED
                return false  // the line ended before hitting to any indent characters
            default:
                return true  // hit to non-indent character
            }
        }
        
        return false  // didn't hit any line-break (= first line)
    }
    
}
