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

protocol InvisibleDrawing: NSLayoutManager {
    
    var textFont: NSFont { get }
    var showsInvisibles: Bool { get }
    var showsControls: Bool { get set }
    var replacementGlyphWidth: CGFloat { get }
    var invisiblesDefaultsObservers: [UserDefaultsObservation] { get set }
}



extension InvisibleDrawing {
    
    /// Draw invisible characters in the given context.
    ///
    /// - Parameters:
    ///   - glyphsToShow: The range of glyphs that are drawn.
    ///   - origin: The position of the text container in the coordinate system of the currently focused view.
    ///   - baselineOffset: The baseline offset to draw glyphs.
    ///   - color: The color of invisibles.
    ///   - shows: The setting which invisible types should be drawn.
    func drawInvisibles(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint, baselineOffset: CGFloat, color: NSColor, shows: [Invisible: Bool]) {
        
        assert(self.showsInvisibles)
        
        guard
            let textContainer = self.textContainer(forGlyphAt: glyphsToShow.lowerBound, effectiveRange: nil)
            else { return assertionFailure() }
        
        let string = self.attributedString().string as NSString
        let isRTL = textContainer.textView?.baseWritingDirection == .rightToLeft
        let glyphHeight = self.textFont.capHeight
        let lineWidth = self.textFont.pointSize * (1 + self.textFont.weight.rawValue) / 12
        let baselineOffset = (textContainer.layoutOrientation == .vertical)
            ? baselineOffset - (self.textFont.ascender - self.textFont.capHeight) / 2  // adjust to center symbols
            : baselineOffset
        var pathCache: [Invisible: CGPath] = [:]
        
        // locate invisibles glyph by glyph
        let symbolPaths = CGMutablePath()
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        for charIndex in characterRange.lowerBound..<characterRange.upperBound {
            let codeUnit = string.character(at: charIndex)
            
            guard
                let invisible = Invisible(codeUnit: codeUnit),
                shows[invisible] == true
                else { continue }
            
            let glyphIndex = self.glyphIndexForCharacter(at: charIndex)
            
            let location: CGPoint
            let path: CGPath
            if let cache = pathCache[invisible] {
                let lineOrigin = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true).origin
                let glyphLocation = self.location(forGlyphAt: glyphIndex)
                location = lineOrigin.offsetBy(dx: glyphLocation.x)
                path = cache
            } else {
                let glyphWidth: CGFloat
                switch invisible {
                    case .newLine:
                        // -> `boundingRect(forGlyphRange:in)` cannot calculate the location of the new line at the end.
                        let lineOrigin = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true).origin
                        let glyphLocation = self.location(forGlyphAt: glyphIndex)
                        location = lineOrigin.offsetBy(dx: glyphLocation.x)
                        glyphWidth = 0
                    default:
                        let boundingRect = self.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)
                        location = boundingRect.origin
                        glyphWidth = boundingRect.width
                }
                
                path = invisible.path(in: CGSize(width: glyphWidth, height: glyphHeight), isRTL: isRTL)
                if invisible != .tab {
                    pathCache[invisible] = path
                }
            }
            
            let symbolLocation = location.offset(by: origin).offsetBy(dy: baselineOffset - glyphHeight)
            
            symbolPaths.addPath(path, transform: .init(translationX: symbolLocation.x, y: symbolLocation.y))
        }
        
        guard !symbolPaths.isEmpty else { return }
        guard let context = NSGraphicsContext.current?.cgContext else { return assertionFailure() }
        
        // draw invisible symbols
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.addPath(symbolPaths)
        context.strokePath()
    }
    
    
    /// Invalidate invisible character drawing.
    ///
    /// - Precondition:
    ///   - The visivility of whole invisible characters is set by the implementer through `showsInvisibles` property.
    ///   - The visivility of each invisible type is obtained directly from UserDefaults settings.
    func invalidateInvisibleDisplay() {
        
        // invalidate normal invisible characters visivilisty
        let wholeRange = self.attributedString().range
        self.invalidateDisplay(forCharacterRange: wholeRange)
        
        // invalidate control characters visivilisty if needed
        let showsControls = self.showsInvisibles && UserDefaults.standard[.showInvisibleControl]
        if showsControls != self.showsControls {
            self.showsControls = showsControls
            self.invalidateLayout(forCharacterRange: wholeRange, actualCharacterRange: nil)
        }
        
        // update UserDefaults observation if needed
        if self.showsInvisibles, self.invisiblesDefaultsObservers.isEmpty {
            let visibilityKeys = Invisible.allCases.map(\.visibilityDefaultKey).unique
            self.invisiblesDefaultsObservers.forEach { $0.invalidate() }
            self.invisiblesDefaultsObservers = UserDefaults.standard.observe(keys: visibilityKeys) { [weak self] (_, _) in
                self?.invalidateInvisibleDisplay()
            }
        } else if !self.showsInvisibles, !self.invisiblesDefaultsObservers.isEmpty {
            self.invisiblesDefaultsObservers.forEach { $0.invalidate() }
            self.invisiblesDefaultsObservers = []
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
            action.contains(.zeroAdvancement),
            let unicode = Unicode.Scalar((self.attributedString().string as NSString).character(at: charIndex)),
            unicode.properties.generalCategory == .control || unicode == .zeroWidthSpace
            else { return false }
        
        return true
    }
    
}



// MARK: -

private extension Invisible {
    
    /// Return the path to draw as alternative symbol.
    ///
    /// - Parameters:
    ///   - size: The size of bounding box.
    ///   - isRTL: Whether the path will be used for right-to-left writing direction.
    /// - Returns: The path.
    func path(in size: CGSize, isRTL: Bool = false) -> CGPath {
        
        switch self {
            case .newLine:
                // -> Do not use `size.width` as it's basically the rest of the line fragment.
                let y = 0.4 * size.height
                let radius = 0.25 * size.height
                let path = CGMutablePath()
                // arrow body
                path.move(to: CGPoint(x: 0.9 * size.height, y: y - radius))
                path.addArc(center: CGPoint(x: 0.9 * size.height, y: y),
                            radius: radius, startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
                path.addLine(to: CGPoint(x: 0.2 * size.height, y: y + radius))
                // arrow head
                path.move(to: CGPoint(x: 0.5 * size.height, y: y + radius + 0.25 * size.height))
                path.addLine(to: CGPoint(x: 0.2 * size.height, y: y + radius))
                path.addLine(to: CGPoint(x: 0.5 * size.height, y: y + radius - 0.25 * size.height))
                if isRTL, let flippedPath = path.copy(using: [CGAffineTransform(scaleX: -1, y: 1)]) {
                    return flippedPath
                }
                return path
            
            case .tab:
                // -> The width of tab is elastic.
                let arrow = CGSize(width: 0.3 * size.height, height: 0.25 * size.height)
                let margin = (0.7 * (size.width - arrow.width)).clamped(to: 0...(0.4 * size.height))
                let endPoint = CGPoint(x: size.width - margin, y: size.height / 2)
                let transform = isRTL ? CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -size.width, y: 0) : .identity
                let path = CGMutablePath()
                // arrow body
                path.move(to: endPoint, transform: transform)
                path.addLine(to: endPoint.offsetBy(dx: -max(size.width - 2 * margin, arrow.width), dy: 0), transform: transform)
                // arrow head
                path.move(to: endPoint.offsetBy(dx: -arrow.width, dy: +arrow.height), transform: transform)
                path.addLine(to: endPoint, transform: transform)
                path.addLine(to: endPoint.offsetBy(dx: -arrow.width, dy: -arrow.height), transform: transform)
                return path
            
            case .space:
                let radius = size.height / 15
                let rect = CGRect(x: size.width / 2, y: size.height / 2, width: 0, height: 0)
                let path = CGMutablePath()
                path.addPath(CGPath(ellipseIn: rect.insetBy(dx: -radius, dy: -radius), transform: nil))
                // draw a zero size dot to fill in the center
                path.addPath(CGPath(ellipseIn: rect, transform: nil))
                return path
            
            case .fullwidthSpace:
                let length = min(size.width, size.height)
                let radius = 0.1 * size.width
                let rect = CGRect(x: (size.width - length) / 2, y: (size.height - length) / 2, width: length, height: length)
                    .insetBy(dx: 0.05 * length, dy: 0.05 * length)
                return CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
                
            case .otherControl:
                let question = CGMutablePath()  // `?` mark in unit size
                question.move(to: CGPoint(x: 0, y: 0.25))
                question.addCurve(to: CGPoint(x: 0.5, y: 0), control1: CGPoint(x: 0, y: 0.12), control2: CGPoint(x: 0.22, y: 0))
                question.addCurve(to: CGPoint(x: 1.0, y: 0.25), control1: CGPoint(x: 0.78, y: 0), control2: CGPoint(x: 1.0, y: 0.12))
                question.addCurve(to: CGPoint(x: 0.7, y: 0.48), control1: CGPoint(x: 1.0, y: 0.32), control2: CGPoint(x: 0.92, y: 0.4))
                question.addCurve(to: CGPoint(x: 0.5, y: 0.75), control1: CGPoint(x: 0.48, y: 0.56), control2: CGPoint(x: 0.5, y: 0.72))
                question.move(to: CGPoint(x: 0.5, y: 0.99))
                question.addLine(to: CGPoint(x: 0.5, y: 1.0))
                let path = CGMutablePath()
                let transform = CGAffineTransform(translationX: 0.3 * size.width, y: 0.2 * size.height)
                    .scaledBy(x: 0.4 * size.width, y: 0.6 * size.height)
                path.addPath(question, transform: transform)
                let rect = CGRect(origin: .zero, size: size).insetBy(dx: 0.1 * size.width, dy: 0)
                let radius = 0.1 * size.width
                path.addRoundedRect(in: rect, cornerWidth: radius, cornerHeight: radius)
                return path
        }
    }
    
}
