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
    
    private var controlVisibilityObserver: UserDefaultsObservation?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.lineHeight = self.defaultLineHeight(for: self.font)
        self.baselineOffset = self.defaultBaselineOffset(for: self.font)
        
        self.delegate = self
        
        self.controlVisibilityObserver = UserDefaults.standard.observe(key: .showInvisibleControl) { [unowned self] (_) in
            let wholeRange = self.attributedString().range
            self.invalidateGlyphs(forCharacterRange: wholeRange, changeInLength: 0, actualCharacterRange: nil)
            self.invalidateLayout(forCharacterRange: wholeRange, actualCharacterRange: nil)
        }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        self.controlVisibilityObserver?.invalidate()
    }
    
    
    
    // MARK: Layout Manager Methods
    
    /// draw invisible characters
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        if UserDefaults.standard[.showInvisibles] {
            let string = self.attributedString().string as NSString
            
            // gather visibility settings
            let defaults = UserDefaults.standard
            let shows: [Invisible: Bool] = [
                .newLine: defaults[.showInvisibleNewLine],
                .tab: defaults[.showInvisibleTab],
                .space: defaults[.showInvisibleSpace],
                .fullwidthSpace: defaults[.showInvisibleFullwidthSpace],
                .otherControl: defaults[.showInvisibleControl],
            ]
            var lineCache: [Invisible: NSAttributedString] = [:]
            
            // draw invisibles glyph by glyph
            let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
            for charIndex in characterRange.lowerBound..<characterRange.upperBound {
                let codeUnit = string.character(at: charIndex)
                
                guard
                    let invisible = Invisible(codeUnit: codeUnit),
                    shows[invisible] == true
                    else { continue }
                
                if invisible == .otherControl {
                    self.addTemporaryAttribute(.foregroundColor, value: NSColor.clear, forCharacterRange: NSRange(location: charIndex, length: 1))
                }
                
                // use chache or create if not yet
                let glyphString = lineCache[invisible]
                    ?? NSAttributedString(string: String(invisible.symbol),
                                          attributes: [.font: self.font,
                                                       .foregroundColor: NSColor.tertiaryLabelColor])
                lineCache[invisible] = glyphString
                
                // calculate position to draw glyph
                let glyphIndex = self.glyphIndexForCharacter(at: charIndex)
                let lineOrigin = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true).origin
                let glyphLocation = self.location(forGlyphAt: glyphIndex)
                let point = lineOrigin.offset(by: origin).offsetBy(dx: glyphLocation.x)
                
                // draw character
                glyphString.draw(at: point)
            }
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
    
    
    /// replace control glyph
    override func setGlyphs(_ glyphs: UnsafePointer<CGGlyph>, properties props: UnsafePointer<NSLayoutManager.GlyphProperty>, characterIndexes charIndexes: UnsafePointer<Int>, font aFont: NSFont, forGlyphRange glyphRange: NSRange) {
        
        guard UserDefaults.standard[.showInvisibleControl] else {
            return super.setGlyphs(glyphs, properties: props, characterIndexes: charIndexes, font: aFont, forGlyphRange: glyphRange)
        }
        
        let newGlyphs = UnsafeMutablePointer(mutating: glyphs)
        let newProps = UnsafeMutablePointer(mutating: props)
        for index in 0..<glyphRange.length where props[index] == .controlCharacter {
            newGlyphs[index] = (aFont as CTFont).glyph(for: Invisible.otherControl.symbol)
            newProps[index] = []
        }
        
        super.setGlyphs(newGlyphs, properties: newProps, characterIndexes: charIndexes, font: aFont, forGlyphRange: glyphRange)
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
