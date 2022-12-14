//
//  NSLayoutManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2022 1024jp
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

extension NSLayoutManager {
    
    /// Calculate visual (wrapped) line range.
    ///
    /// - Parameter charIndex: The index of the character for which to return the line fragment range.
    /// - Returns: The range of characters that locate in the same line fragment of the given character.
    func lineFragmentRange(at charIndex: Int) -> NSRange {
        
        let glyphIndex = self.glyphIndexForCharacter(at: charIndex)
        var lineGlyphRange: NSRange = .notFound
        
        self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineGlyphRange, withoutAdditionalLayout: true)
        
        var range = self.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
        
        // strip the last line ending character
        let lineEndingRange = (self.attributedString().string as NSString).range(of: "\\R", options: [.regularExpression, .backwards], range: range)
        range.length -= lineEndingRange.length
        
        return range
    }
    
    
    /// The enclosing rectangle of a glyph at the given index.
    ///
    /// - Parameters:
    ///   - glyphIndex: The glyph index for which to return enclosing rectangle.
    ///   - forSelection: Whether obtaining rect in the quality for selection range drawing.
    ///   - textContainer: The text container in which the glyph is laid out.
    /// - Returns: The enclosing rectangle.
    func enclosingRectForGlyph(at glyphIndex: Int, forSelection: Bool = false, in textContainer: NSTextContainer) -> NSRect {
        
        assert(self.isValidGlyphIndex(glyphIndex))
        
        let glyphRange = NSRange(location: glyphIndex, length: 1)
        let selectedGlyphRange = forSelection ? glyphRange : .notFound
        var enclosingRect: NSRect = .zero
        self.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: selectedGlyphRange, in: textContainer) { (rect, _) in
            enclosingRect = rect
        }
        
        return enclosingRect
    }
}



// MARK: - Temporary Atttributes

extension NSLayoutManager {
    
    /// Return range of given attribute if the location is in it, otherwise nil.
    ///
    /// - Parameters:
    ///   - attrName: The name of a temporary attribute.
    ///   - location: The index for which to check attributes. This value must not exceed the bounds of the receiver.
    ///   - range: The range over which to search for continuous presence of attrName. This value must not exceed the bounds of the receiver.
    /// - Returns: A range contains the maximum range over which the named attribute’s value applies, clipped to rangeLimit. Or `nil` if no attribute value exists.
    func effectiveRange(of attrName: NSAttributedString.Key, at location: Int, in range: NSRange? = nil) -> NSRange? {
        
        let range = range ?? self.attributedString().range
        var effectiveRange = NSRange.notFound
        
        guard self.temporaryAttribute(attrName, atCharacterIndex: location, longestEffectiveRange: &effectiveRange, in: range) != nil else { return nil }
        
        return effectiveRange
    }
    
    
    /// Enumerate range and value of given temporary attribute.
    ///
    /// - Parameters:
    ///   - attrName: The name of the temporary attribute to enumerate.
    ///   - enumerationRange: The range over which the attribute values are enumerated.
    ///   - block: A closure to apply to ranges of the specified attribute in the receiver.
    ///   - value: The value for the specified attribute.
    ///   - range: The range of the attribute value in the receiver.
    ///   - stop: A reference to a Boolean value, which you can set to true within the closure to stop further processing of the attribute enumeration.
    func enumerateTemporaryAttribute(_ attrName: NSAttributedString.Key, in enumerationRange: NSRange, using block: (_ value: Any, _ range: NSRange, _ stop: inout Bool) -> Void) {
        
        var characterIndex = enumerationRange.location
        while characterIndex < enumerationRange.upperBound {
            var effectiveRange: NSRange = .notFound
            let value = self.temporaryAttribute(attrName, atCharacterIndex: characterIndex, longestEffectiveRange: &effectiveRange, in: enumerationRange)
            
            if let value = value {
                var stop = false
                block(value, effectiveRange, &stop)
                
                guard !stop else { return }
            }
            
            characterIndex = effectiveRange.upperBound
        }
    }
    
    
    /// Check if at least one temporary attribute for given attribute key exists.
    ///
    /// - Parameters:
    ///   - attrName: The name of temporary attribute key to check.
    ///   - range: The range where to check. When `nil`, search the entire range.
    /// - Returns: Whether the given attribute key exists.
    func hasTemporaryAttribute(_ attrName: NSAttributedString.Key, in range: NSRange? = nil) -> Bool {
        
        guard self.attributedString().length > 0 else { return false }
        
        let range = range ?? self.attributedString().range
        
        assert(range.upperBound <= self.attributedString().length)
        
        var effectiveRange: NSRange = .notFound
        let value = self.temporaryAttribute(attrName, atCharacterIndex: range.location, longestEffectiveRange: &effectiveRange, in: range)
        
        return value != nil || effectiveRange.upperBound < range.upperBound
    }
}



// MARK: - Bidi-Text

extension NSLayoutManager {
    
    /// Check the writing direction of the character.
    ///
    /// - Parameter index: The character index to check.
    /// - Returns: `true` when is right-to-left, otherwise `false`.
    func isRTL(at index: Int) -> Bool {
        
        let glyphIndex = self.glyphIndexForCharacter(at: index)
        
        guard self.isValidGlyphIndex(glyphIndex) else { return false }
        
        var bidiLevels: [UInt8] = [0]
        self.getGlyphs(in: NSRange(location: glyphIndex, length: 1), glyphs: nil, properties: nil, characterIndexes: nil, bidiLevels: &bidiLevels)
        
        return !bidiLevels[0].isMultiple(of: 2)
    }
    
    
    /// Return the character index of the left side of the given character index in display order.
    ///
    /// - Parameters:
    ///   - characterIndex: The character index of the origin character.
    ///   - baseWritingDirection: The base writing direction of the entire string to move index among lines.
    /// - Returns: Left character index.
    func leftCharacterIndex(of characterIndex: Int, baseWritingDirection: NSWritingDirection) -> Int {
        
        let characterIndexes = self.lineFragmentInsertionPointIndexes(forCharacterAt: characterIndex)
        
        guard let index = characterIndexes.firstIndex(of: characterIndex)
                ?? characterIndexes.lastIndex(where: { $0 < characterIndex })
        else { assertionFailure(); return characterIndex }
        
        // -> The target is in the same fragment.
        if index > 0 { return characterIndexes[index - 1] }
        
        let string = self.attributedString().string as NSString
        
        switch baseWritingDirection {
            case .rightToLeft:
                return string.index(after: characterIndexes.max() ?? 0)
            default:
                return string.index(before: characterIndexes.min() ?? 0)
        }
    }
    
    
    /// Return the character index of the right side of the given character index in display order.
    ///
    /// - Parameters:
    ///   - characterIndex: The character index of the origin character.
    ///   - baseWritingDirection: The base writing direction of the entire string to move index among lines.
    /// - Returns: Right character index.
    func rightCharacterIndex(of characterIndex: Int, baseWritingDirection: NSWritingDirection) -> Int {
        
        let characterIndexes = self.lineFragmentInsertionPointIndexes(forCharacterAt: characterIndex)
        
        guard let index = characterIndexes.firstIndex(of: characterIndex)
                ?? characterIndexes.lastIndex(where: { $0 < characterIndex })
        else { assertionFailure(); return characterIndex }
        
        // -> The target is in the same fragment.
        if index < characterIndexes.count - 1 { return characterIndexes[index + 1] }
        
        let string = self.attributedString().string as NSString
        
        switch baseWritingDirection {
            case .rightToLeft:
                return string.index(before: characterIndexes.min() ?? 0)
            default:
                return string.index(after: characterIndexes.max() ?? 0)
        }
    }
    
    
    /// Rects to draw insertion point for the given character index.
    ///
    /// - Note: The rects can be either in one or two when the cursor split at the boundary of the writing direction.
    ///
    /// - Parameter characterIndex: The character index.
    /// - Returns: One-pixel-width rects to draw insertion point in the layout manager coordinate.
    func insertionPointRects(at characterIndex: Int) -> [NSRect] {
        
        guard
            let primaryRect = self.insertionPointRect(at: characterIndex, alternate: false)
        else { assertionFailure(); return [] }
        
        guard
            UserDefaults.standard.useSplitCursor,
            let alternateRect = self.insertionPointRect(at: characterIndex, alternate: true)
        else { return [primaryRect] }
        
        return [NSRect(x: primaryRect.minX, y: primaryRect.minY,
                       width: primaryRect.width, height: primaryRect.height / 2),
                NSRect(x: alternateRect.minX, y: alternateRect.minY + alternateRect.height / 2,
                       width: alternateRect.width, height: alternateRect.height / 2)]
    }
    
    
    /// Return the character indexes for the insertion points in the same line fragment of the given character index in display order.
    ///
    /// - Parameter characterIndex: The character index of one character within the line fragment.
    /// - Returns: An array contains character indexes in display order.
    private func lineFragmentInsertionPointIndexes(forCharacterAt characterIndex: Int) -> [Int] {
        
        let count = self.getLineFragmentInsertionPoints(forCharacterAt: characterIndex, alternatePositions: false, inDisplayOrder: true, positions: nil, characterIndexes: nil)
        var characterIndexes = [Int](repeating: 0, count: count)
        self.getLineFragmentInsertionPoints(forCharacterAt: characterIndex, alternatePositions: false, inDisplayOrder: true, positions: nil, characterIndexes: &characterIndexes)
        
        return characterIndexes
    }
    
    
    /// Rect to draw insertion point for the given character index.
    ///
    /// - Parameters:
    ///   - characterIndex: The character index.
    ///   - alternate: If `true`, the secondary insertion point rect for split cursor will be returned.
    /// - Returns: An one-pixel-width rect to draw the insertion point in the layout manager coordinate, or `nil` if no alternate insertion point is provided.
    private func insertionPointRect(at characterIndex: Int, alternate: Bool) -> NSRect? {
        
        assert(characterIndex > 0)
        
        let count = self.getLineFragmentInsertionPoints(forCharacterAt: characterIndex, alternatePositions: alternate, inDisplayOrder: true, positions: nil, characterIndexes: nil)
        
        var positions = [CGFloat](repeating: 0, count: count)
        var characterIndexes = [Int](repeating: 0, count: count)
        self.getLineFragmentInsertionPoints(forCharacterAt: characterIndex, alternatePositions: alternate, inDisplayOrder: true, positions: &positions, characterIndexes: &characterIndexes)
        
        guard let index = characterIndexes.firstIndex(of: characterIndex) else { return nil }
        
        let position = positions[index]
        let glyphIndex = self.glyphIndexForCharacter(at: characterIndex)
        let lastGlyphIndex = self.isValidGlyphIndex(glyphIndex) ? glyphIndex : glyphIndex - 1
        let lineFragment = self.lineFragmentRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil, withoutAdditionalLayout: true)
        
        return NSRect(x: lineFragment.minX + position, y: lineFragment.minY, width: 1, height: lineFragment.height)
    }
}


private extension UserDefaults {
    
    /// Whether the user enables the system-wide "Use split cursor" option in System Settings > Keyboard > Input Source.
    var useSplitCursor: Bool  { self.bool(forKey: "NSUseSplitCursor") }
}



// MARK: - Debug

extension NSLayoutManager {
    
    private static let guidelineColor = NSColor(hue: 0.5, saturation: 0.75, brightness: 0.5, alpha: 1)
    
    
    /// Draw guidelines of line fragment and baseline for debugging.
    ///
    /// Invoke this method in `drawBackground(forGlyphRange:at:)` to check the text layout for debugging.
    ///
    /// - Parameters:
    ///   - glyphsToShow: The range of glyphs for which the line fragments are drawn.
    ///   - origin: The position of the text container in the coordinate system of the currently focused view.
    ///   - offsetsHandler: The block returning the vertical offsets in the line fragment coordinate to draw additional guidelines.
    ///   - textContainer: The text container in which the glyphs are laid out.
    ///   - glyphRange: The range of glyphs laid out in the current line fragment.
    func drawLineFragments(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint, offsetsHandler: @escaping (_ textContainer: NSTextContainer, _ glyphRange: NSRange) -> [CGFloat] = { (_, _) in [] }) {
        
        NSGraphicsContext.saveGraphicsState()
        
        Self.guidelineColor.setStroke()
        self.enumerateLineFragments(forGlyphRange: glyphsToShow) { (rect, _, textContainer, glyphRange, _) in
            let rect = rect.offset(by: origin)
            
            NSBezierPath.defaultLineWidth = 0.5
            NSBezierPath.stroke(rect)
            
            NSBezierPath.defaultLineWidth = 0.25
            for offset in offsetsHandler(textContainer, glyphRange) {
                NSBezierPath.strokeLine(from: NSPoint(x: rect.minX, y: rect.minY + offset),
                                        to: NSPoint(x: rect.maxX, y: rect.minY + offset))
            }
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
}
