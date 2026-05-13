//
//  NSLayoutManager+InvisibleDrawing.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-04-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2026 1024jp
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

import AppKit
import Invisible
import StringUtils

protocol InvisibleDrawing: NSLayoutManager {
    
    var invisiblesColor: NSColor { get }
    var textFont: NSFont { get }
    
    var showsInvisibles: Bool { get }
    var showsControls: Bool { get set }
    var shownInvisibles: Set<Invisible> { get }
    
    func isInvalidInvisible(_ invisible: Invisible, at characterIndex: Int) -> Bool
}


private struct PathCacheKey: Hashable {
    
    let codeUnit: UTF16.CodeUnit
    let usesRTLPath: Bool
}


extension InvisibleDrawing {
    
    /// Draws invisible character symbols.
    ///
    /// - Parameters:
    ///   - glyphsToShow: The range of glyphs that are drawn.
    ///   - origin: The position of the text container in the coordinate system of the currently focused view.
    ///   - baselineOffset: The baseline offset to draw glyphs.
    func drawInvisibles(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint, baselineOffset: CGFloat) {
        
        let types = self.shownInvisibles
        
        guard
            self.showsInvisibles,
            !types.isEmpty
        else { return }
        
        guard
            let textContainer = self.textContainer(forGlyphAt: glyphsToShow.lowerBound, effectiveRange: nil)
        else { return assertionFailure() }
        
        let string = self.attributedString().string as NSString
        let textView = textContainer.textView
        let isRTL = MainActor.assumeIsolated { textView?.baseWritingDirection == .rightToLeft }
        // -> Some fonts, such as Raanana in the system, can return a negative value for `.capHeight` (2022-06, macOS 12).
        let glyphHeight = (self.textFont.capHeight > 0) ? self.textFont.capHeight : self.textFont.ascender
        let lineWidth = self.textFont.pointSize * (1 + self.textFont.weight.rawValue) / 12
        let cacheableInvisibles: Set<Invisible> = [.newLine, .fullwidthSpace, .otherControl]
        var pathCache: [PathCacheKey: NSBezierPath] = [:]
        
        // setup drawing parameters
        NSGraphicsContext.saveGraphicsState()
        self.invisiblesColor.set()
        
        // draw invisibles glyph by glyph
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        var lastCodeUnit: unichar? = (characterRange.lowerBound > 0)
            ? string.character(at: characterRange.lowerBound - 1)
            : nil
        for charIndex in characterRange.lowerBound..<characterRange.upperBound {
            let codeUnit = string.character(at: charIndex)
            defer { lastCodeUnit = codeUnit }
            
            guard
                let invisible = Invisible(codeUnit: codeUnit),
                types.contains(invisible),
                !(codeUnit == 0xA && lastCodeUnit == 0xD)  // skip LF for CRLF
            else { continue }
            
            let glyphIndex = self.glyphIndexForCharacter(at: charIndex)
            
            // skip folded text
            guard !self.propertyForGlyph(at: glyphIndex).contains(.null) else { continue }
            
            var lineFragmentRange: NSRange = .notFound
            let lineOrigin = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineFragmentRange, withoutAdditionalLayout: true).origin
            let glyphLocation = self.location(forGlyphAt: glyphIndex)
            let symbolOrigin = lineOrigin.offset(by: origin).offsetBy(dx: glyphLocation.x, dy: baselineOffset - glyphHeight)
            
            let glyphWidth: CGFloat
            let usesRTLPath: Bool
            switch invisible {
                case .newLine:
                    glyphWidth = 0
                    usesRTLPath = isRTL
                case .otherControl:
                    // for non-zeroAdvancement controls, such as VERTICAL TABULATION
                    glyphWidth = self.boundingBoxForControlGlyph(for: self.textFont).width
                    usesRTLPath = isRTL
                default:
                    // -> Avoid invoking `.enclosingRectForGlyph(at:in:)` as much as possible
                    //    that takes long time with long unwrapped lines.
                    if lineFragmentRange.contains(glyphIndex + 1) {
                        let nextGlyphLocation = self.location(forGlyphAt: glyphIndex + 1)
                        if nextGlyphLocation.x > glyphLocation.x {
                            glyphWidth = nextGlyphLocation.x - glyphLocation.x
                            usesRTLPath = false
                        } else {
                            glyphWidth = self.enclosingRectForGlyph(at: glyphIndex, in: textContainer).width
                            usesRTLPath = true
                        }
                    } else {
                        glyphWidth = self.enclosingRectForGlyph(at: glyphIndex, in: textContainer).width
                        usesRTLPath = isRTL
                    }
            }
            
            let cacheKey = PathCacheKey(codeUnit: codeUnit, usesRTLPath: usesRTLPath)
            let path: NSBezierPath
            if let cache = pathCache[cacheKey] {
                path = cache
            } else {
                let size = CGSize(width: glyphWidth, height: glyphHeight)
                let cgPath = invisible.path(in: size, lineWidth: lineWidth, isRTL: usesRTLPath)
                path = NSBezierPath(cgPath: cgPath)
                
                if cacheableInvisibles.contains(invisible) {
                    pathCache[cacheKey] = path
                }
            }
            let isInvalid = self.isInvalidInvisible(invisible, at: charIndex)
            
            if isInvalid {
                NSColor.systemRed.set()
            }
            
            path.transform(using: .init(translationByX: symbolOrigin.x, byY: symbolOrigin.y))
            path.fill()
            path.transform(using: .init(translationByX: -symbolOrigin.x, byY: -symbolOrigin.y))
            
            if isInvalid {
                self.invisiblesColor.set()
            }
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    /// Invalidates invisible character drawing for when a user setting was changed.
    ///
    /// - Precondition: The user settings are set by the implementer through `showsInvisibles` and `shownInvisibles` properties.
    func invalidateInvisibleDisplay() {
        
        // invalidate normal invisible characters visibility
        let wholeRange = self.attributedString().range
        self.invalidateDisplay(forCharacterRange: wholeRange)
        
        // invalidate control characters visibility if needed
        let showsControls = self.showsInvisibles && self.shownInvisibles.contains(.otherControl)
        if showsControls != self.showsControls {
            self.showsControls = showsControls
            self.invalidateLayout(forCharacterRange: wholeRange, actualCharacterRange: nil)
        }
    }
    
    
    /// Returns whether a control character replacement glyph for the control character will be drawn.
    ///
    /// - Parameters:
    ///   - charIndex: The character index.
    ///   - action: The proposed control character action.
    /// - Returns: A boolean value indicating whether an invisible glyph needs to be shown.
    func showsControlCharacter(at charIndex: Int, proposedAction action: NSLayoutManager.ControlCharacterAction) -> Bool {
        
        guard
            self.showsControls,
            action.contains(.zeroAdvancement)
        else { return false }
        
        let codeUnit = (self.attributedString().string as NSString).character(at: charIndex)
        
        return Invisible(codeUnit: codeUnit) == .otherControl
    }
    
    
    /// Returns the bounding box for the invisible control character symbol.
    ///
    /// - Parameter font: The font to use for sizing the symbol.
    /// - Returns: The bounding box for the symbol.
    func boundingBoxForControlGlyph(for font: NSFont) -> NSRect {
        
        // -> Use `0` to represent the standard glyph size of the font.
        let glyph = (font as CTFont).glyph(for: "0")
        let advancement = font.advancement(forCGGlyph: glyph)
        
        return NSRect(origin: .zero, size: advancement)
    }
}
