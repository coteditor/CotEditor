//
//  NSFont+Size.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

import AppKit.NSFont
import CoreText

extension NSFont {
    
    /// Width of SPACE character.
    var spaceWidth: CGFloat {
        
        let glyph = (self as CTFont).glyph(for: " ")
        let advancement = self.advancement(forCGGlyph: glyph)
        
        return advancement.width
    }
    
}



extension CTFont {
    
    /// Create CGGlyph from a character.
    ///
    /// - Parameter character: The character to extract glyph.
    /// - Returns: A CGGlyph for passed-in character based on the receiver font.
    func glyph(for character: Character) -> CGGlyph {
        
        assert(character.utf16.count == 1)
        
        var glyph = CGGlyph()
        let uniChar: UniChar = character.utf16.first!
        CTFontGetGlyphsForCharacters(self, [uniChar], &glyph, 1)
        
        return glyph
    }
    
    
    /// Get advancement of a glyph.
    ///
    /// - Parameters:
    ///   - glyph: The glyph to calculate advancement.
    ///   - orientation: Drawing orientation.
    /// - Returns: Advancement of passed-in glyph.
    func advance(for glyph: CGGlyph, orientation: CTFontOrientation = .horizontal) -> CGSize {
        
        var advance: CGSize = .zero
        CTFontGetAdvancesForGlyphs(self, orientation, [glyph], &advance, 1)
        
        return advance
    }
    
}
