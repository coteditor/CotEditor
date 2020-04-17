//
//  LayoutManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-01-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2020 1024jp
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

final class LayoutManager: NSLayoutManager, ValidationIgnorable, LineRangeCacheable {
    
    // MARK: Protocol Properties
    
    var ignoresDisplayValidation = false
    
    var string: NSString  { self.attributedString().string as NSString }
    var lineRangeCache = LineRangeCache()
    
    
    // MARK: Public Properties
    
    var usesAntialias = true
    
    var textFont: NSFont = .systemFont(ofSize: 0) {
        
        // store text font to avoid the issue where the line height can be inconsistent by using a fallback font
        // -> DO NOT use `self.firstTextView?.font`, because when the specified font doesn't support
        //    the first character of the text view content, it returns a fallback font for the first one.
        didSet {
            // cache metric values to fix line height
            self.defaultLineHeight = self.defaultLineHeight(for: textFont)
            self.defaultBaselineOffset = self.defaultBaselineOffset(for: textFont)
            
            // cache widths of special glyphs
            self.spaceWidth = textFont.width(of: " ")
            self.replacementGlyphWidth = textFont.width(of: Invisible.otherControl.symbol)
        }
    }
    
    var showsInvisibles = false {
        
        didSet {
            guard showsInvisibles != oldValue else { return }
            
            self.invalidateInvisibleDisplay()
        }
    }
    
    var invisiblesColor: NSColor = .disabledControlTextColor
    
    private(set) var spaceWidth: CGFloat = 0
    
    
    // MARK: Private Properties
    
    private var defaultLineHeight: CGFloat = 1.0
    private var defaultBaselineOffset: CGFloat = 0
    
    private var showsControls = false
    private var replacementGlyphWidth: CGFloat = 0
    
    private var invisiblesDefaultsObservers: [UserDefaultsObservation] = []
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.delegate = self
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        self.invisiblesDefaultsObservers.forEach { $0.invalidate() }
    }
    
    
    
    // MARK: Layout Manager Methods
    
    /// adjust rect of last empty line
    override func setExtraLineFragmentRect(_ fragmentRect: NSRect, usedRect: NSRect, textContainer container: NSTextContainer) {
        
        // -> The height of the extra line fragment should be the same as other normal fragments that are likewise customized in the delegate.
        var fragmentRect = fragmentRect
        fragmentRect.size.height = self.lineHeight
        var usedRect = usedRect
        usedRect.size.height = self.lineHeight
        
        super.setExtraLineFragmentRect(fragmentRect, usedRect: usedRect, textContainer: container)
    }
    
    
    /// draw glyphs
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        NSGraphicsContext.saveGraphicsState()
        
        // set anti-alias state on screen drawing
        if NSGraphicsContext.currentContextDrawingToScreen() {
            NSGraphicsContext.current?.shouldAntialias = self.usesAntialias
        }
        
        // draw invisibles
        if self.showsInvisibles,
            let context = NSGraphicsContext.current?.cgContext
        {
            let string = self.attributedString().string as NSString
            let textView = self.textContainer(forGlyphAt: glyphsToShow.lowerBound, effectiveRange: nil)?.textView
            let layoutOrientation = textView?.layoutOrientation
            let writingDirection = textView?.baseWritingDirection
            let baselineOffset = self.baselineOffset(for: layoutOrientation ?? .horizontal)
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
                let line = lineCache[invisible] ?? self.invisibleLine(for: invisible)
                lineCache[invisible] = line
                
                // calculate position to draw glyph
                let glyphIndex = self.glyphIndexForCharacter(at: charIndex)
                let lineOrigin = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true).origin
                let glyphLocation = self.location(forGlyphAt: glyphIndex)
                var point = lineOrigin.offset(by: origin).offsetBy(dx: glyphLocation.x, dy: baselineOffset)
                if layoutOrientation == .vertical {
                    let bounds = line.bounds()
                    point.y += bounds.minY + bounds.height / 2
                }
                if writingDirection == .rightToLeft, invisible == .newLine {
                    point.x -= line.bounds().width
                }
                
                // draw character
                context.textPosition = point
                CTLineDraw(line, context)
            }
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    /// fill background rectangles with a color
    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<NSRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: NSColor) {
        
        // modify selected highlight color when the window is inactive
        // -> Otherwise, `.secondarySelectedControlColor` will be used forcibly and text becomes unreadable
        //    when the window appearance and theme are inconsistent.
        if color == .secondarySelectedControlColor,  // check if inactive
            let textContainer = self.textContainer(forGlyphAt: self.glyphIndexForCharacter(at: charRange.location),
                                                   effectiveRange: nil, withoutAdditionalLayout: true),
            let theme = (textContainer.textView as? Themable)?.theme,
            let secondarySelectionColor = theme.secondarySelectionColor
        {
            secondarySelectionColor.setFill()
        }
        
        super.fillBackgroundRectArray(rectArray, count: rectCount, forCharacterRange: charRange, color: color)
    }
    
    
    /// invalidate display for the given character range
    override func invalidateDisplay(forCharacterRange charRange: NSRange) {
        
        // ignore display validation during applying temporary attributes continuously
        // -> See `SyntaxParser.apply(highlights:range:)` for the usage of this option. (2018-12)
        if self.ignoresDisplayValidation { return }
        
        super.invalidateDisplay(forCharacterRange: charRange)
    }
    
    
    override func processEditing(for textStorage: NSTextStorage, edited editMask: NSTextStorageEditActions, range newCharRange: NSRange, changeInLength delta: Int, invalidatedRange invalidatedCharRange: NSRange) {
        
        if editMask.contains(.editedCharacters) {
            self.invalidateLineRanges(in: newCharRange, changeInLength: delta)
        }
        
        super.processEditing(for: textStorage, edited: editMask, range: newCharRange, changeInLength: delta, invalidatedRange: invalidatedCharRange)
    }
    
    
    
    // MARK: Public Methods
    
    /// Fixed line height to avoid having different line height by composite font.
    var lineHeight: CGFloat {
        
        let multiple = self.firstTextView?.defaultParagraphStyle?.lineHeightMultiple ?? 1.0
        
        return multiple * self.defaultLineHeight
    }
    
    
    /// Fixed baseline offset to place glyphs vertically in the middle of a line.
    ///
    /// - Parameter layoutOrientation: The text layout orientation.
    /// - Returns: The baseline offset.
    func baselineOffset(for layoutOrientation: TextLayoutOrientation) -> CGFloat {
        
        switch layoutOrientation {
            case .vertical:
                return self.lineHeight / 2
            default:
                return (self.lineHeight + self.defaultBaselineOffset) / 2
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Invalidate invisible character drawing.
    ///
    /// - Precondition:
    ///   - The visivility of whole invisible characters is set by the implementer through `showsInvisibles` property.
    ///   - The visivility of each invisible type is obtained directly from UserDefaults settings.
    private func invalidateInvisibleDisplay() {
        
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
            let visibilityKeys: [DefaultKeys] = [
                .showInvisibleNewLine,
                .showInvisibleTab,
                .showInvisibleSpace,
                .showInvisibleFullwidthSpace,
                .showInvisibleControl,
            ]
            self.invisiblesDefaultsObservers.forEach { $0.invalidate() }
            self.invisiblesDefaultsObservers = UserDefaults.standard.observe(keys: visibilityKeys) { [weak self] (_, _) in
                self?.invalidateInvisibleDisplay()
            }
        } else if !self.showsInvisibles, !self.invisiblesDefaultsObservers.isEmpty {
            self.invisiblesDefaultsObservers.forEach { $0.invalidate() }
            self.invisiblesDefaultsObservers = []
        }
    }
    
    
    /// Create a CTLine for given invisible type.
    ///
    /// - Parameters:
    ///   - invisible: The type of invisible character.
    /// - Returns: A CTLine of the alternative glyph for the given invisible type.
    private func invisibleLine(for invisible: Invisible) -> CTLine {
        
        let font: NSFont
        switch invisible {
            case .newLine, .tab, .fullwidthSpace:
                font = .systemFont(ofSize: self.textFont.pointSize)
            case .space, .otherControl:
                font = self.textFont
        }
        let attrString = NSAttributedString(string: String(invisible.symbol),
                                            attributes: [.foregroundColor: self.invisiblesColor,
                                                         .font: font])
        
        return CTLineCreateWithAttributedString(attrString)
    }
    
}



extension LayoutManager: NSLayoutManagerDelegate {
    
    /// adjust line height to be all the same
    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>, lineFragmentUsedRect: UnsafeMutablePointer<NSRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
        
        // avoid inconsistent line height by a composite font
        // -> The line height by normal input keeps consistant when overriding the related methods in NSLayoutManager.
        //    but then, the drawing won't be update properly when the font or line hight is changed.
        // -> NSParagraphStyle's `.lineheightMultiple` can also control the line height,
        //    but it causes an issue when the first character of the string uses a fallback font.
        lineFragmentRect.pointee.size.height = self.lineHeight
        lineFragmentUsedRect.pointee.size.height = self.lineHeight
        
        // vertically center the glyphs in the line fragment
        baselineOffset.pointee = self.baselineOffset(for: textContainer.layoutOrientation)
        
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
    
    
    /// avoid soft wrapping just after indent
    func layoutManager(_ layoutManager: NSLayoutManager, shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool {
        
        // avoid creating CharacterSet every time
        struct NonIndent { static let characterSet = CharacterSet(charactersIn: " \t").inverted }
        
        // check if the character is the first non-whitespace character after indent
        let string = self.string
        let lineStartIndex = self.lineStartIndex(at: charIndex)
        let range = NSRange(location: lineStartIndex, length: charIndex - lineStartIndex)
        
        return string.rangeOfCharacter(from: NonIndent.characterSet, range: range) != .notFound
    }
    
    
    /// apply sytax highlighing on printing also
    func layoutManager(_ layoutManager: NSLayoutManager, shouldUseTemporaryAttributes attrs: [NSAttributedString.Key: Any] = [:], forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: NSRangePointer?) -> [NSAttributedString.Key: Any]? {
        
        return attrs
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
