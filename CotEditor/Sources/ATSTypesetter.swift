//
//  ATSTypesetter.swift
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

final class ATSTypesetter: NSATSTypesetter {
    
    // MARK: ATS Typesetter Methods
    
    /// adjust vertical position to keep line height even with composed font
    override func willSetLineFragmentRect(_ lineRect: UnsafeMutablePointer<NSRect>, forGlyphRange glyphRange: NSRange, usedRect: UnsafeMutablePointer<NSRect>, baselineOffset: UnsafeMutablePointer<CGFloat>) {
        
        // avoid being line height inconsistent by a composite font
        //   -> LayoutManager の関連メソッドをオーバーライドしてあれば、このメソッドをオーバーライドしなくても
        //      通常の入力では行間が一定になるが、フォントや行間を変更したときに適正に描画されない。
        //   -> EditorTextView で、NSParagraphStyle の lineHeightMultiple を設定しても行間は制御できるが、
        //      「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        //      挿入すると行間がズレる」問題が生じる。
        //   -> `baselineOffset` also shifts when a character height is higher than the fixed line height,
        //      such as 𓆏.
        
        guard let manager = self.layoutManager as? LayoutManager else { return assertionFailure() }
        
        lineRect.pointee.size.height = manager.lineHeight
        usedRect.pointee.size.height = manager.lineHeight
        baselineOffset.pointee = manager.defaultBaselineOffset
    }
    
    
    /// customize behavior by control glyph
    override func actionForControlCharacter(at charIndex: Int) -> NSTypesetterControlCharacterAction {
        
        let action = super.actionForControlCharacter(at: charIndex)
        
        if action.contains(.zeroAdvancementAction),
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
        
        guard
            let manager = self.layoutManager as? LayoutManager,
            manager.showsOtherInvisibles,
            manager.showsInvisibles
            else { return .zero }
        
        // make blank space to draw a replacement character in LayoutManager later.
        var rect = proposedRect
        rect.size.width = manager.replacementGlyphWidth
        
        return rect
    }
    
    
    /// avoid soft warpping just after an indent
    override func shouldBreakLine(byWordBeforeCharacterAt charIndex: Int) -> Bool {
        
        // -> Getting index fails when the code point is a part of surrogate pair.
        guard
            charIndex > 0,
            let string = self.attributedString?.string
            else { return true }
        
        let index = String.Index(utf16Offset: charIndex, in: string)
        
        // check if the character is the first non-whitespace character after indent
        for character in string[workaround: string.startIndex..<index].reversed() {
            switch character {
            case " ", "\t":
                continue
            case "\n":  // the line ended before hitting to any indent characters
                return false
            default:  // hit to non-indent character
                return true
            }
        }
        
        return false  // didn't hit any line-break (= first line)
    }
    
}
