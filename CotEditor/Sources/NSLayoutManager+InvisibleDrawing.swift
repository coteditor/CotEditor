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
//  © 2020 1024jp
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
import CoreText

protocol InvisibleDrawing: NSLayoutManager {
    
    var textFont: NSFont { get }
}



extension InvisibleDrawing {
    
    /// Draw invisible characters in the given context.
    ///
    /// - Parameters:
    ///   - glyphsToShow: The range of glyphs that are drawn.
    ///   - origin: The position of the text container in the coordinate system of the currently focused view.
    ///   - baselineOffset: The baseline offset to draw glyphs.
    ///   - color: The color of invisibles.
    func drawInvisibles(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint, baselineOffset: CGFloat, color: NSColor) {
        
        guard let context = NSGraphicsContext.current?.cgContext else { return assertionFailure() }
        
        let string = self.attributedString().string as NSString
        let textView = self.textContainer(forGlyphAt: glyphsToShow.lowerBound, effectiveRange: nil)?.textView
        let writingDirection = textView?.baseWritingDirection
        var lineCache: [Invisible: CTLine] = [:]
        
        // gather visibility settings
        let defaults = UserDefaults.standard
        let shows: [Invisible: Bool] = [
            .newLine: defaults[.showInvisibleNewLine],
            .tab: defaults[.showInvisibleTab],
            .space: defaults[.showInvisibleSpace],
            .fullwidthSpace: defaults[.showInvisibleFullwidthSpace],
            .otherControl: defaults[.showInvisibleControl],
        ]
        
        // flip coordinate if needed
        if NSGraphicsContext.current?.isFlipped == true {
            context.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)
        }
        
        // draw invisibles glyph by glyph
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        for charIndex in characterRange.lowerBound..<characterRange.upperBound {
            let codeUnit = string.character(at: charIndex)
            
            guard
                let invisible = Invisible(codeUnit: codeUnit),
                shows[invisible] == true
                else { continue }
            
            // use cached line or create if not yet
            let line = lineCache[invisible] ?? self.invisibleLine(for: invisible, color: color)
            lineCache[invisible] = line
            
            // calculate position to draw glyph
            let glyphIndex = self.glyphIndexForCharacter(at: charIndex)
            let lineOrigin = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true).origin
            let glyphLocation = self.location(forGlyphAt: glyphIndex)
            var point = lineOrigin.offset(by: origin).offsetBy(dx: glyphLocation.x, dy: baselineOffset)
            if writingDirection == .rightToLeft, invisible == .newLine {
                point.x -= line.bounds().width
            }
            
            // draw character
            context.textPosition = point
            CTLineDraw(line, context)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Create a CTLine for given invisible type.
    ///
    /// - Parameters:
    ///   - invisible: The type of invisible character.
    ///   - color: The color of invisible character.
    /// - Returns: A CTLine of the alternative glyph for the given invisible type.
    private func invisibleLine(for invisible: Invisible, color: NSColor) -> CTLine {
        
        let font: NSFont
        switch invisible {
            case .newLine, .tab, .fullwidthSpace:
                font = .systemFont(ofSize: self.textFont.pointSize)
            case .space, .otherControl:
                font = self.textFont
        }
        let attrString = NSAttributedString(string: String(invisible.symbol),
                                            attributes: [.foregroundColor: color,
                                                         .font: font])
        
        return CTLineCreateWithAttributedString(attrString)
    }
    
}



// MARK: -

private extension CTLine {
    
    /// Get receiver's bounds in the object-oriented way.
    ///
    /// - Parameter options: Desired options or 0 if none.
    /// - Returns: The bouns of the receiver.
    func bounds(options: CTLineBoundsOptions = []) -> CGRect {
        
        return CTLineGetBoundsWithOptions(self, options)
    }
    
}
