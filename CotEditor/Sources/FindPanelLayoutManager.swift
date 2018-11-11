//
//  FindPanelLayoutManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-03-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2018 1024jp
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
    
    
    /// draw invisible characters
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        if UserDefaults.standard[.showInvisibles] {
            let string = self.textStorage?.string ?? ""
            
            let color = NSColor.tertiaryLabelColor
            
            let font = self.font
            let fullWidthFont = NSFont(named: .hiraginoSans, size: font.pointSize) ?? font
            
            let attributes: [NSAttributedString.Key: Any] = [.font: font,
                                                            .foregroundColor: color]
            let fullwidthAttributes: [NSAttributedString.Key: Any] = [.font: fullWidthFont,
                                                                     .foregroundColor: color]
            
            let defaults = UserDefaults.standard
            let showsSpace = defaults[.showInvisibleSpace]
            let showsTab = defaults[.showInvisibleTab]
            let showsNewLine = defaults[.showInvisibleNewLine]
            let showsFullwidthSpace = defaults[.showInvisibleFullwidthSpace]
            let showsOtherInvisibles = defaults[.showOtherInvisibleChars]
            
            let space = NSAttributedString(string: Invisible.space.usedSymbol, attributes: attributes)
            let tab = NSAttributedString(string: Invisible.tab.usedSymbol, attributes: attributes)
            let newLine = NSAttributedString(string: Invisible.newLine.usedSymbol, attributes: attributes)
            let fullwidthSpace = NSAttributedString(string: Invisible.fullwidthSpace.usedSymbol, attributes: fullwidthAttributes)
            
            // draw invisibles glyph by glyph
            for glyphIndex in glyphsToShow.location..<glyphsToShow.upperBound {
                let charIndex = self.characterIndexForGlyph(at: glyphIndex)
                let utf16Index = String.UTF16Index(encodedOffset: charIndex)
                let codeUnit = string.utf16[utf16Index]
                let invisible = Invisible(codeUnit: codeUnit)
                
                let glyphString: NSAttributedString
                switch invisible {
                case .space?:
                    guard showsSpace else { continue }
                    glyphString = space
                    
                case .tab?:
                    guard showsTab else { continue }
                    glyphString = tab
                    
                case .newLine?:
                    guard showsNewLine else { continue }
                    glyphString = newLine
                    
                case .fullwidthSpace?:
                    guard showsFullwidthSpace else { continue }
                    glyphString = fullwidthSpace
                    
                default:
                    guard showsOtherInvisibles else { continue }
                    guard
                        self.propertyForGlyph(at: glyphIndex) == .controlCharacter,
                        self.textStorage?.attribute(.glyphInfo, at: charIndex, effectiveRange: nil) == nil
                        else { continue }
                    
                    let replaceFont = NSFont(named: .lucidaGrande, size: font.pointSize) ?? NSFont.systemFont(ofSize: font.pointSize)
                    let charRange = self.characterRange(forGlyphRange: NSRange(location: glyphIndex, length: 1), actualGlyphRange: nil)
                    let baseString = (string as NSString).substring(with: charRange)
                    
                    guard let glyphInfo = NSGlyphInfo(glyphName: "replacement", for: replaceFont, baseString: baseString) else { continue }
                    
                    // !!!: The following line can cause crash by binary document.
                    //      It's actually dangerous and to be detoured to modify textStorage while drawing.
                    //      (2015-09 by 1024jp)
                    self.textStorage?.addAttributes([.glyphInfo: glyphInfo,
                                                     .font: replaceFont,
                                                     .foregroundColor: color], range: charRange)
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
