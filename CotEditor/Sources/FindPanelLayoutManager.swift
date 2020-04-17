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
    
    private let textFont: NSFont = .systemFont(ofSize: 0)
    private var lineHeight: CGFloat = 0
    private var baselineOffset: CGFloat = 0
    
    private var showsControls: Bool  { UserDefaults.standard[.showInvisibles] && UserDefaults.standard[.showInvisibleControl] }
    private lazy var replacementGlyphWidth = self.textFont.width(of: Invisible.otherControl.symbol)
    
    private var invisiblesDefaultsObservers: [UserDefaultsObservation] = []
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.lineHeight = self.defaultLineHeight(for: self.textFont)
        self.baselineOffset = self.defaultBaselineOffset(for: self.textFont)
        
        self.delegate = self
        
        let visibilityKeys: [DefaultKeys] = [
            .showInvisibles,
            .showInvisibleNewLine,
            .showInvisibleTab,
            .showInvisibleSpace,
            .showInvisibleFullwidthSpace,
            .showInvisibleControl,
        ]
        self.invisiblesDefaultsObservers = UserDefaults.standard.observe(keys: visibilityKeys) { [unowned self] (_, _) in
            let wholeRange = self.attributedString().range
            self.invalidateDisplay(forCharacterRange: wholeRange)
            self.invalidateLayout(forCharacterRange: wholeRange, actualCharacterRange: nil)
        }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        self.invisiblesDefaultsObservers.forEach { $0.invalidate() }
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
                
                // use cache or create if not in yet
                let glyphString = lineCache[invisible]
                    ?? NSAttributedString(string: String(invisible.symbol),
                                          attributes: [.font: self.textFont,
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
    
}



extension FindPanelLayoutManager: NSLayoutManagerDelegate {
    
    /// adjust line height to be all the same
    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>, lineFragmentUsedRect: UnsafeMutablePointer<NSRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
        
        lineFragmentRect.pointee.size.height = self.lineHeight
        lineFragmentUsedRect.pointee.size.height = self.lineHeight
        baselineOffset.pointee = self.baselineOffset
        
        return true
    }
    
    
    /// treat control characers as whitespace to draw replacement glyphs
    func layoutManager(_ layoutManager: NSLayoutManager, shouldUse action: NSLayoutManager.ControlCharacterAction, forControlCharacterAt charIndex: Int) -> NSLayoutManager.ControlCharacterAction {
        
        if self.showsControls,
            action.contains(.zeroAdvancement),
            let unicode = Unicode.Scalar((layoutManager.attributedString().string as NSString).character(at: charIndex)),
            unicode.properties.generalCategory == .control || unicode == .zeroWidthSpace
        {
            return .whitespace  // -> Then, the glyph width can be modified in `layoutManager(_:boundingBoxForControlGlyphAt:...)`.
        }
        
        return action
    }
    
    
    /// make a blank space to draw the replacement glyph in `drawGlyphs(forGlyphRange:at:)` later
    func layoutManager(_ layoutManager: NSLayoutManager, boundingBoxForControlGlyphAt glyphIndex: Int, for textContainer: NSTextContainer, proposedLineFragment proposedRect: NSRect, glyphPosition: NSPoint, characterIndex charIndex: Int) -> NSRect {
        
        var rect = proposedRect
        rect.size.width = self.replacementGlyphWidth
        
        return rect
    }
    
}
