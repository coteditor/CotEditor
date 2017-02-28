/*
 
 FindPanelLayoutManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-03-04.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class FindPanelLayoutManager: NSLayoutManager {
    
    // MARK: Private Properties

    private let font = NSFont.systemFont(ofSize: 0)
    
    
    
    // MARK: -
    // MARK: Layout Manager Methods
    
    /// fix line height for mixed font
    override func setLineFragmentRect(_ fragmentRect: NSRect, forGlyphRange glyphRange: NSRange, usedRect: NSRect) {
        
        let lineHeight = self.defaultLineHeight(for: self.font)
        
        var fragmentRect = fragmentRect
        fragmentRect.size.height = lineHeight
        
        var usedRect = usedRect
        usedRect.size.height = lineHeight
        
        super.setLineFragmentRect(fragmentRect, forGlyphRange: glyphRange, usedRect: usedRect)
    }
    
    
    /// show invisible characters
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        if UserDefaults.standard[.showInvisibles] {
            let string = self.textStorage?.string ?? ""
            
            let color = NSColor.tertiaryLabelColor
            
            let font = self.font
            let fullWidthFont = NSFont(name: "HiraKakuProN-W3", size: font.pointSize) ?? font
            
            let attributes = [NSFontAttributeName: font,
                              NSForegroundColorAttributeName: color]
            let fullwidthAttributes = [NSFontAttributeName: fullWidthFont,
                              NSForegroundColorAttributeName: color]
            
            let defaults = UserDefaults.standard
            let showsSpace = defaults[.showInvisibleSpace]
            let showsTab = defaults[.showInvisibleTab]
            let showsNewLine = defaults[.showInvisibleNewLine]
            let showsFullWidthSpace = defaults[.showInvisibleFullwidthSpace]
            let showsOtherInvisibles = defaults[.showOtherInvisibleChars]
            
            let space = NSAttributedString(string: Invisible.userSpace, attributes: attributes)
            let tab = NSAttributedString(string: Invisible.userTab, attributes: attributes)
            let newLine = NSAttributedString(string: Invisible.userNewLine, attributes: attributes)
            let fullWidthSpace = NSAttributedString(string: Invisible.userFullWidthSpace, attributes: fullwidthAttributes)
            let verticalTab = NSAttributedString(string: Invisible.verticalTab, attributes: attributes)
            
            // draw invisibles glyph by glyph
            for glyphIndex in glyphsToShow.location..<glyphsToShow.max {
                let charIndex = self.characterIndexForGlyph(at: glyphIndex)
                
                let utfChar = string.utf16[String.UTF16Index(charIndex)]
                let character = String(utf16CodeUnits: [utfChar], count: 1)
                
                let glyphString: NSAttributedString
                switch character {
                case " ", "\u{A0}":
                    guard showsSpace else { continue }
                    glyphString = space
                    
                case "\t":
                    guard showsTab else { continue }
                    glyphString = tab
                    
                case "\n":
                    guard showsNewLine else { continue }
                    glyphString = newLine
                    
                case "\u{3000}":  // fullwidth-space (JP)
                    guard showsFullWidthSpace else { continue }
                    glyphString = fullWidthSpace
                    
                case "\u{b}":
                    guard showsOtherInvisibles else { continue }
                    glyphString = verticalTab
                    
                default:
                    guard self.showsInvisibleCharacters && self.glyph(at: glyphIndex, isValidIndex: nil) == NSGlyph(NSControlGlyph) else { continue }
                    
                    guard self.textStorage?.attribute(NSGlyphInfoAttributeName, at: charIndex, effectiveRange: nil) == nil else { continue }
                    
                    let replaceFont = NSFont(name: "Lucida Grande", size: font.pointSize) ?? NSFont.systemFont(ofSize: font.pointSize)
                    let charRange = self.characterRange(forGlyphRange: NSRange(location: glyphIndex, length: 1), actualGlyphRange: nil)
                    let baseString = (string as NSString).substring(with: charRange)
                    
                    guard let glyphInfo = NSGlyphInfo(glyphName: "replacement", for: replaceFont, baseString: baseString) else { continue }
                    
                    // !!!: The following line can cause crash by binary document.
                    //      It's actually dangerous and to be detoured to modify textStorage while drawing.
                    //      (2015-09 by 1024jp)
                    self.textStorage?.addAttributes([NSGlyphInfoAttributeName: glyphInfo,
                                                     NSFontAttributeName: replaceFont,
                                                     NSForegroundColorAttributeName: color], range: charRange)
                    continue
                }

                // calculate position to draw glyph
                let lineOrigin = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true).origin
                let glyphLocation = self.location(forGlyphAt: glyphIndex)
                let point = lineOrigin.offset(by: origin).offsetBy(dx: glyphLocation.x)
                
                // draw character
                glyphString.draw(at: point)
            }
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
    
}
