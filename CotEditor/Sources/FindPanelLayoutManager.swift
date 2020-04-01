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

final class FindPanelLayoutManager: NSLayoutManager {
    
    // MARK: Private Properties
    
    private let font: NSFont = .systemFont(ofSize: 0)
    private var lineHeight: CGFloat = 0
    private var baselineOffset: CGFloat = 0
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.lineHeight = self.defaultLineHeight(for: self.font)
        self.baselineOffset = self.defaultBaselineOffset(for: self.font)
        
        self.delegate = self
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Layout Manager Methods
    
    /// draw invisible characters
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        if UserDefaults.standard[.showInvisibles] {
            let string = self.attributedString().string as NSString
            let color = NSColor.tertiaryLabelColor
            
            let defaults = UserDefaults.standard
            let showsNewLine = defaults[.showInvisibleNewLine]
            let showsTab = defaults[.showInvisibleTab]
            let showsSpace = defaults[.showInvisibleSpace]
            let showsFullwidthSpace = defaults[.showInvisibleFullwidthSpace]
            let showsOtherInvisibles = defaults[.showOtherInvisibleChars]
            
            // draw invisibles glyph by glyph
            let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
            for charIndex in characterRange.lowerBound..<characterRange.upperBound {
                let codeUnit = string.character(at: charIndex)
                
                guard let invisible = Invisible(codeUnit: codeUnit) else { continue }
                
                switch invisible {
                    case .newLine:
                        guard showsNewLine else { continue }
                    
                    case .tab:
                        guard showsTab else { continue }
                    
                    case .space:
                        guard showsSpace else { continue }
                    
                    case .fullwidthSpace:
                        guard showsFullwidthSpace else { continue }
                    
                    case .otherControl:
                        guard showsOtherInvisibles else { continue }
                        guard self.textStorage?.attribute(.glyphInfo, at: charIndex, effectiveRange: nil) == nil else { continue }
                        
                        let glyph = (self.font as CTFont).glyph(for: invisible.symbol)
                        let controlRange = NSRange(location: charIndex, length: 1)
                        let baseString = string.substring(with: controlRange)
                        
                        guard let glyphInfo = NSGlyphInfo(cgGlyph: glyph, for: self.font, baseString: baseString) else { assertionFailure(); continue }
                        
                        // !!!: The following line can cause crash by binary document.
                        //      It's actually dangerous and to be detoured to modify textStorage while drawing.
                        //      (2015-09 by 1024jp)
                        self.textStorage?.addAttributes([.glyphInfo: glyphInfo,
                                                         .foregroundColor: color], range: controlRange)
                        continue
                }
                
                // calculate position to draw glyph
                let glyphIndex = self.glyphIndexForCharacter(at: charIndex)
                let lineOrigin = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true).origin
                let glyphLocation = self.location(forGlyphAt: glyphIndex)
                let point = lineOrigin.offset(by: origin).offsetBy(dx: glyphLocation.x)
                
                // draw character
                let glyphString = NSAttributedString(string: String(invisible.symbol),
                                                     attributes: [.font: self.font,
                                                                  .foregroundColor: color])
                glyphString.draw(at: point)
            }
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
    
}



extension FindPanelLayoutManager: NSLayoutManagerDelegate {
    
    /// adjust line height to be all the same
    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>, lineFragmentUsedRect: UnsafeMutablePointer<NSRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
        
        lineFragmentRect.pointee.size.height = self.lineHeight
        lineFragmentUsedRect.pointee.size.height = self.lineHeight
        baselineOffset.pointee = self.baselineOffset
        
        return true
    }
    
}
