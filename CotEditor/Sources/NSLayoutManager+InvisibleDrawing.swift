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
//  © 2020-2022 1024jp
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

import Combine
import AppKit

protocol InvisibleDrawing: NSLayoutManager {
    
    var invisiblesColor: NSColor { get }
    var textFont: NSFont { get }
    var showsInvisibles: Bool { get }
    var showsControls: Bool { get set }
    var invisiblesDefaultsObserver: AnyCancellable? { get set }
    
    func isInvalidInvisible(_ invisible: Invisible, at characterIndex: Int) -> Bool
}



extension InvisibleDrawing {
    
    /// Draw invisible character symbols.
    ///
    /// - Parameters:
    ///   - glyphsToShow: The range of glyphs that are drawn.
    ///   - origin: The position of the text container in the coordinate system of the currently focused view.
    ///   - baselineOffset: The baseline offset to draw glyphs.
    ///   - types: The invisible types to draw.
    func drawInvisibles(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint, baselineOffset: CGFloat, types: Set<Invisible>) {
        
        guard
            self.showsInvisibles,
            !types.isEmpty
        else { return }
        
        guard
            let textContainer = self.textContainer(forGlyphAt: glyphsToShow.lowerBound, effectiveRange: nil)
        else { return assertionFailure() }
        
        let string = self.attributedString().string as NSString
        let isRTL = textContainer.textView?.baseWritingDirection == .rightToLeft
        // -> Some fonts, such as Raanana in the system, can return a negative value for `.capHeight` (macOS 12, 2022-06).
        let glyphHeight = (self.textFont.capHeight > 0) ? self.textFont.capHeight : self.textFont.ascender
        let lineWidth = self.textFont.pointSize * (1 + self.textFont.weight.rawValue) / 12
        let cacheableInvisibles: Set<Invisible> = [.newLine, .fullwidthSpace, .otherControl]
        var pathCache: [UTF16.CodeUnit: NSBezierPath] = [:]
        
        // setup drawing parameters
        NSGraphicsContext.saveGraphicsState()
        self.invisiblesColor.set()
        
        // draw invisibles glyph by glyph
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        var lastCodeUnit: unichar?
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
            
            let path: NSBezierPath
            if let cache = pathCache[codeUnit] {
                path = cache
            } else {
                let glyphWidth: CGFloat
                switch invisible {
                    case .newLine:
                        glyphWidth = 0
                    case .otherControl:
                        // for non-zeroAdvancement controls, such as VERTICAL TABULATION
                        glyphWidth = self.boundingBoxForControlGlyph(for: self.textFont).width
                    default:
                        // -> Avoid invoking `.enclosingRectForGlyph(at:in:)` as much as possible
                        //    that takes long time with long unwrapped lines.
                        glyphWidth = (lineFragmentRange.contains(glyphIndex + 1) && !isRTL)
                            ? self.location(forGlyphAt: glyphIndex + 1).x - glyphLocation.x
                            : self.enclosingRectForGlyph(at: glyphIndex, in: textContainer).width
                }
                
                let size = CGSize(width: glyphWidth, height: glyphHeight)
                let cgPath = invisible.path(in: size, lineWidth: lineWidth, isRTL: isRTL)
                path = NSBezierPath(path: cgPath)
                
                if cacheableInvisibles.contains(invisible) {
                    pathCache[codeUnit] = path
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
    
    
    /// Invalidate invisible character drawing.
    ///
    /// - Precondition:
    ///   - The visibility of whole invisible characters is set by the implementer through `showsInvisibles` property.
    ///   - The visibility of each invisible type is obtained directly from UserDefaults settings.
    func invalidateInvisibleDisplay() {
        
        // invalidate normal invisible characters visibility
        let wholeRange = self.attributedString().range
        self.invalidateDisplay(forCharacterRange: wholeRange)
        
        // invalidate control characters visibility if needed
        let showsControls = self.showsInvisibles && UserDefaults.standard[.showInvisibleControl]
        if showsControls != self.showsControls {
            self.showsControls = showsControls
            self.invalidateLayout(forCharacterRange: wholeRange, actualCharacterRange: nil)
        }
        
        // update UserDefaults observation if needed
        if self.showsInvisibles, self.invisiblesDefaultsObserver == nil {
            let publishers = Invisible.allCases.map(\.visibilityDefaultKey).unique
                .map { UserDefaults.standard.publisher(for: $0) }
            self.invisiblesDefaultsObserver = Publishers.MergeMany(publishers)
                .sink { [weak self] _ in self?.invalidateInvisibleDisplay() }
            
        } else if !self.showsInvisibles {
            self.invisiblesDefaultsObserver = nil
        }
    }
    
    
    /// Whether a control character replacement glyph for the control character will be drawn.
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
    
    
    /// Bounding box for the invisible control character symbol.
    func boundingBoxForControlGlyph(for font: NSFont) -> NSRect {
        
        // -> Use `0` to represent the standard glyph size of the font.
        let glyph = (font as CTFont).glyph(for: "0")
        let advancement = font.advancement(forCGGlyph: glyph)
        
        return NSRect(origin: .zero, size: advancement)
    }
}



// MARK: -

private extension Invisible {
    
    /// Return the path to draw as alternative symbol.
    ///
    /// - Parameters:
    ///   - size: The size of bounding box.
    ///   - lineWidth: The standard line width.
    ///   - isRTL: Whether the path will be used for right-to-left writing direction.
    /// - Returns: The path.
    func path(in size: CGSize, lineWidth: CGFloat, isRTL: Bool = false) -> CGPath {
        
        switch self {
            case .newLine:
                // -> Do not use `size.width` as new line glyphs actually have no area.
                let y = 0.5 * size.height
                let radius = 0.25 * size.height
                let transform = isRTL ? CGAffineTransform(scaleX: -1, y: 1) : .identity
                let path = CGMutablePath()
                // arrow body
                path.addArc(center: CGPoint(x: 0.9 * size.height, y: y),
                            radius: radius, startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
                path.addLine(to: CGPoint(x: 0.2 * size.height, y: y + radius))
                // arrow head
                path.addLines(between: [CGPoint(x: 0.5 * size.height, y: y + radius + 0.25 * size.height),
                                        CGPoint(x: 0.2 * size.height, y: y + radius),
                                        CGPoint(x: 0.5 * size.height, y: y + radius - 0.25 * size.height)])
                return path.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0, transform: transform)
            
            case .tab:
                // -> The width of tab is elastic and even can be (almost) zero.
                let arrow = CGSize(width: 0.3 * size.height, height: 0.25 * size.height)
                let margin = (0.7 * (size.width - arrow.width)).clamped(to: 0...(0.4 * size.height))
                let endPoint = CGPoint(x: size.width - margin, y: size.height / 2)
                let transform = isRTL ? CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -size.width, y: 0) : .identity
                let path = CGMutablePath()
                // arrow body
                path.addLines(between: [endPoint, endPoint.offsetBy(dx: -max(size.width - 2 * margin, arrow.width))])
                // arrow head
                path.addLines(between: [endPoint.offsetBy(dx: -arrow.width, dy: +arrow.height),
                                        endPoint,
                                        endPoint.offsetBy(dx: -arrow.width, dy: -arrow.height)])
                return path.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0, transform: transform)
            
            case .space:
                let radius = 0.15 * size.height + lineWidth
                let rect = CGRect(x: (size.width - radius) / 2, y: (size.height - radius) / 2, width: radius, height: radius)
                return CGPath(ellipseIn: rect, transform: nil)
            
            case .noBreakSpace:
                let hat = CGMutablePath()
                let hatCorner = CGPoint(x: 0.5 * size.width, y: 0.05 * size.height)
                hat.addLines(between: [hatCorner.offsetBy(dx: -0.15 * size.height, dy: 0.18 * size.height),
                                       hatCorner,
                                       hatCorner.offsetBy(dx: 0.15 * size.height, dy: 0.18 * size.height)])
                let path = CGMutablePath()
                path.addPath(hat.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0))
                path.addPath(Self.space.path(in: size, lineWidth: lineWidth))
                return path
            
            case .fullwidthSpace:
                let length = min(0.95 * size.width, size.height) - lineWidth
                let radius = 0.1 * length
                let rect = CGRect(x: (size.width - length) / 2, y: (size.height - length) / 2, width: length, height: length)
                return CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
                    .copy(strokingWithWidth: lineWidth, lineCap: .butt, lineJoin: .miter, miterLimit: 0)
            
            case .otherWhitespace:
                let path = CGMutablePath()
                path.addLines(between: [CGPoint(x: 0.2 * size.width, y: 0.3 * size.height),
                                        CGPoint(x: 0.8 * size.width, y: 0.3 * size.height)])
                path.addLines(between: [CGPoint(x: 0.2 * size.width, y: 0.8 * size.height),
                                        CGPoint(x: 0.8 * size.width, y: 0.8 * size.height)])
                return path.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .miter, miterLimit: 0)
            
            case .otherControl:
                let question = CGMutablePath()  // `?` mark in unit size
                question.move(to: CGPoint(x: 0, y: 0.25))
                question.addCurve(to: CGPoint(x: 0.5, y: 0), control1: CGPoint(x: 0, y: 0.12), control2: CGPoint(x: 0.22, y: 0))
                question.addCurve(to: CGPoint(x: 1.0, y: 0.25), control1: CGPoint(x: 0.78, y: 0), control2: CGPoint(x: 1.0, y: 0.12))
                question.addCurve(to: CGPoint(x: 0.7, y: 0.48), control1: CGPoint(x: 1.0, y: 0.32), control2: CGPoint(x: 0.92, y: 0.4))
                question.addCurve(to: CGPoint(x: 0.5, y: 0.75), control1: CGPoint(x: 0.48, y: 0.56), control2: CGPoint(x: 0.5, y: 0.72))
                question.move(to: CGPoint(x: 0.5, y: 0.99))
                question.addLine(to: CGPoint(x: 0.5, y: 1.0))
                let transform = CGAffineTransform(translationX: 0.25 * size.width, y: 0.12 * size.height)
                    .scaledBy(x: 0.5 * size.width, y: 0.76 * size.height)
                let scaledQuestion = question.copy(using: [transform])!
                    .copy(strokingWithWidth: 0.15 * size.width, lineCap: .round, lineJoin: .miter, miterLimit: 0)
                let path = CGMutablePath()
                path.addPath(scaledQuestion)
                path.addLines(between: [CGPoint(x: 0.5 * size.width, y: -0.15 * size.height),
                                        CGPoint(x: 0.9 * size.width, y: 0.15 * size.height),
                                        CGPoint(x: 0.9 * size.width, y: 0.85 * size.height),
                                        CGPoint(x: 0.5 * size.width, y: 1.15 * size.height),
                                        CGPoint(x: 0.1 * size.width, y: 0.85 * size.height),
                                        CGPoint(x: 0.1 * size.width, y: 0.15 * size.height)])
                path.closeSubpath()
                return path
        }
    }
}
