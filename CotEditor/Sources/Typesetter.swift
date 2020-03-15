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
        
        // vertically center the glyphs in the line fragment
        baselineOffset.pointee = manager.baselineOffset(for: self.currentTextContainer?.layoutOrientation ?? .horizontal)
    }
    
    
    /// customize behavior by control glyph
    override func actionForControlCharacter(at charIndex: Int) -> NSTypesetterControlCharacterAction {
        
        let action = super.actionForControlCharacter(at: charIndex)
        
        if action.contains(.zeroAdvancementAction),
            let manager = self.layoutManager as? LayoutManager,
            manager.showsOtherInvisibles,
            manager.showsInvisibles,
            let unicode = Unicode.Scalar((manager.attributedString().string as NSString).character(at: charIndex)),
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
    
    
    /// avoid soft wrapping just after indent
    override func shouldBreakLine(byWordBeforeCharacterAt charIndex: Int) -> Bool {
        
        guard let layoutManager = self.layoutManager as? LineRangeCacheable else { return true }
        
        // avoid creating CharacterSet every time
        struct NonIndent { static let characterSet = CharacterSet(charactersIn: " \t").inverted }
        
        // check if the character is the first non-whitespace character after indent
        let string = layoutManager.string
        let lineStartIndex = layoutManager.lineStartIndex(at: charIndex)
        let range = NSRange(location: lineStartIndex, length: charIndex - lineStartIndex)
        
        return string.rangeOfCharacter(from: NonIndent.characterSet, range: range) != .notFound
    }
    
}
