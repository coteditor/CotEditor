/*
 
 ATSTypesetter.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-12-08.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

final class ATSTypesetter: NSATSTypesetter {
    
    // MARK: ATS Typesetter Methods
    
    /// adjust vertical position to keep line height even with composed font
    override func willSetLineFragmentRect(_ lineRect: UnsafeMutablePointer<NSRect>, forGlyphRange glyphRange: NSRange, usedRect: UnsafeMutablePointer<NSRect>, baselineOffset: UnsafeMutablePointer<CGFloat>) {
        
        // avoid being line height different by composite font
        //   -> LayoutManager の関連メソッドをオーバーライドしてあれば、このメソッドをオーバーライドしなくても
        //      通常の入力では行間が一定になるが、フォントや行間を変更したときに適正に描画されない。
        //   -> EditorTextView で、NSParagraphStyle の lineHeightMultiple を設定しても行間は制御できるが、
        //      「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        //      挿入すると行間がズレる」問題が生じる。
        
        guard let manager = self.layoutManager as? LayoutManager else { return }
        
        lineRect.pointee.size.height = manager.lineHeight
        usedRect.pointee.size.height = manager.lineHeight
        baselineOffset.pointee = manager.defaultBaselineOffset
    }
    
    
    /// customize behavior by control glyph
    override func actionForControlCharacter(at charIndex: Int) -> NSTypesetterControlCharacterAction {
        
        let result = super.actionForControlCharacter(at: charIndex)
        
        if result.contains(.zeroAdvancementAction) && charIndex > 0 {
            guard let string = self.attributedString?.string as NSString? else { return result }
            
            let isLowSurrogate = CFStringIsSurrogateLowCharacter(string.character(at: charIndex)) && CFStringIsSurrogateHighCharacter(string.character(at: charIndex - 1))
            if !isLowSurrogate {
                return .whitespaceAction  // -> Then, the glyph width can be modified on `boundingBoxForControlGlyphAtIndex:...`.
            }
        }
        
        return result
    }
    
    
    /// return bounding box for control glyph
    override func boundingBox(forControlGlyphAt glyphIndex: Int, for textContainer: NSTextContainer, proposedLineFragment proposedRect: NSRect, glyphPosition: NSPoint, characterIndex charIndex: Int) -> NSRect {
        
        guard let manager = self.layoutManager as? LayoutManager, manager.showsOtherInvisibles && manager.showsInvisibles else {
            // DON'T invoke super method here. If invoked, it can not continue drawing remaining lines any more on Mountain Lion (and possible other versions except El Capitan).
            // Just passing zero rect is enough if you don't need to draw it.
            return NSRect.zero
        }
        
        // make blank space to draw a replacement character in LayoutManager later.
        guard let textFont = manager.textFont else { return NSRect.zero }
        let invisibleFont = NSFont(name: "Lucida Grande", size: textFont.pointSize) ?? textFont  // use current text font for fallback
        let replacementGlyph = invisibleFont.glyph(withName: "replacement")  // U+FFFD
        let replacementGlyphBounding = invisibleFont.boundingRect(forGlyph: replacementGlyph)
        
        var rect = proposedRect
        rect.size.width = replacementGlyphBounding.width
        
        return rect
    }
    
    
    /// avoid soft warpping just after an indent
    override func shouldBreakLine(byWordBeforeCharacterAt charIndex: Int) -> Bool {
        
        if charIndex == 0 { return true }
        
        // check if the character is the first non-whitespace character after indent
        guard let string = self.attributedString?.string else { return true }
        
        let index = string.utf16.startIndex.advanced(by: charIndex).samePosition(in: string)!
        
        for character in string.substring(to: index).characters.reversed() {
            if character == "\n" { return false }  // the line ended before hitting to any indent characters
            if character != " " && character != "\t" { return true }  // hit to non-indent character
        }
        
        return false  // didn't hit to line-break (= first line)
    }
    
}
