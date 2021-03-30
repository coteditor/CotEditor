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
//  © 2014-2021 1024jp
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
import Cocoa

final class LayoutManager: NSLayoutManager, InvisibleDrawing, ValidationIgnorable, LineRangeCacheable {
    
    // MARK: Protocol Properties
    
    var showsControls = false
    var invisiblesDefaultsObserver: AnyCancellable?
    
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
            // cache metric values
            self.defaultLineHeight = self.defaultLineHeight(for: textFont)
            self.defaultBaselineOffset = self.defaultBaselineOffset(for: textFont)
            self.boundingBoxForControlGlyph = self.boundingBoxForControlGlyph(for: textFont)
            self.spaceWidth = textFont.width(of: " ")
        }
    }
    
    var showsInvisibles = false {
        
        didSet {
            guard showsInvisibles != oldValue else { return }
            
            self.invalidateInvisibleDisplay()
        }
    }
    
    var invisiblesColor: NSColor = .disabledControlTextColor
    
    var showsIndentGuides = false
    var tabWidth = 0
    
    private(set) var spaceWidth: CGFloat = 0
    
    
    // MARK: Private Properties
    
    private var defaultLineHeight: CGFloat = 1.0
    private var defaultBaselineOffset: CGFloat = 0
    private var boundingBoxForControlGlyph: NSRect = .zero
    
    private var indentGuideObserver: AnyCancellable?
    
    private static let unemphasizedSelectedContentBackgroundColor: NSColor = (ProcessInfo().operatingSystemVersion.majorVersion < 11)
        ? .secondarySelectedControlColor
        : .unemphasizedSelectedContentBackgroundColor
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.indentGuideObserver = UserDefaults.standard.publisher(for: .showIndentGuides)
            .sink { [weak self] _ in
                guard let self = self, self.showsInvisibles else { return }
                self.invalidateDisplay(forCharacterRange: self.attributedString().range)
            }
        
        self.delegate = self
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
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
        
        if NSGraphicsContext.currentContextDrawingToScreen() {
            NSGraphicsContext.current?.shouldAntialias = self.usesAntialias
        }
        
        if self.showsIndentGuides {
            self.drawIndentGuides(forGlyphRange: glyphsToShow, at: origin, color: self.invisiblesColor, tabWidth: self.tabWidth)
        }
        
        if self.showsInvisibles {
            self.drawInvisibles(forGlyphRange: glyphsToShow, at: origin, baselineOffset: self.baselineOffset(for: .horizontal), color: self.invisiblesColor, types: UserDefaults.standard.showsInvisible)
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    /// fill background rectangles with a color
    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<NSRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: NSColor) {
        
        // modify selected highlight color when the window is inactive
        // -> Otherwise, `.unemphasizedSelectedContentBackgroundColor` will be used forcibly and text becomes unreadable
        //    when the window appearance and theme are inconsistent.
        if color == Self.unemphasizedSelectedContentBackgroundColor,  // check if inactive
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
    
    
    override func setGlyphs(_ glyphs: UnsafePointer<CGGlyph>, properties props: UnsafePointer<NSLayoutManager.GlyphProperty>, characterIndexes charIndexes: UnsafePointer<Int>, font aFont: NSFont, forGlyphRange glyphRange: NSRange) {
        
        // fix the width of whitespaces when the base font is fixed pitch.
        let newProps = UnsafeMutablePointer(mutating: props)
        if self.textFont.isFixedPitch {
            for index in 0..<glyphRange.length {
                newProps[index].subtract(.elastic)
            }
        }
        
        super.setGlyphs(glyphs, properties: newProps, characterIndexes: charIndexes, font: aFont, forGlyphRange: glyphRange)
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
                // remove the space above to make glyphs visually center
                let diff = self.textFont.ascender - self.textFont.capHeight
                return (self.lineHeight + self.defaultBaselineOffset - diff) / 2
        }
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
        
        // -> Then, the glyph width can be modified in `layoutManager(_:boundingBoxForControlGlyphAt:...)`.
        return self.showsControlCharacter(at: charIndex, proposedAction: action) ? .whitespace : action
    }
    
    
    /// make a blank space to draw the replacement glyph in `drawGlyphs(forGlyphRange:at:)` later
    func layoutManager(_ layoutManager: NSLayoutManager, boundingBoxForControlGlyphAt glyphIndex: Int, for textContainer: NSTextContainer, proposedLineFragment proposedRect: NSRect, glyphPosition: NSPoint, characterIndex charIndex: Int) -> NSRect {
        
        return self.boundingBoxForControlGlyph
    }
    
    
    /// avoid soft wrapping just after indent
    func layoutManager(_ layoutManager: NSLayoutManager, shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool {
        
        // avoid creating CharacterSet every time
        struct NonIndent { static let characterSet = CharacterSet(charactersIn: " \t").inverted }
        
        // check if the character is the first non-whitespace character after indent
        let lineStartIndex = self.lineStartIndex(at: charIndex)
        let range = NSRange(location: lineStartIndex, length: charIndex - lineStartIndex)
        
        guard !range.isEmpty else { return true }
        
        return self.string.rangeOfCharacter(from: NonIndent.characterSet, range: range) != .notFound
    }
    
    
    /// apply sytax highlighing on printing also
    func layoutManager(_ layoutManager: NSLayoutManager, shouldUseTemporaryAttributes attrs: [NSAttributedString.Key: Any] = [:], forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: NSRangePointer?) -> [NSAttributedString.Key: Any]? {
        
        return attrs
    }
    
}



// MARK: Private Extension

private extension NSLayoutManager {
    
    /// Draw indent guides at every given indent width.
    ///
    /// - Parameters:
    ///   - glyphsToShow: The range of glyphs that are drawn.
    ///   - origin: The position of the text container in the coordinate system of the currently focused view.
    ///   - color: The color of guides.
    ///   - tabWidth: The number of spaces for an indent.
    func drawIndentGuides(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint, color: NSColor, tabWidth: Int) {
        
        guard tabWidth > 0 else { return assertionFailure() }
        
        // calculate characterRange to seek
        let string = self.attributedString().string as NSString
        let charactersToShow = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        let lineStartIndex = string.lineStartIndex(at: charactersToShow.location)
        let characterRange = NSRange(location: lineStartIndex, length: charactersToShow.upperBound - lineStartIndex)
        
        // find indent indexes
        var indentIndexes: [(lineRange: NSRange, indexes: [Int])] = []
        string.enumerateSubstrings(in: characterRange, options: [.byLines, .substringNotRequired]) { (_, range, _, _) in
            var indexes: [Int] = []
            var spaceCount = 0
            loop: for characterIndex in range.lowerBound..<range.upperBound {
                let isIndentLevel = spaceCount.isMultiple(of: tabWidth) && spaceCount > 0
                
                switch string.character(at: characterIndex) {
                    case 0x0020:  // space
                        spaceCount += 1
                    case 0x0009:  // tab
                        spaceCount += tabWidth - (spaceCount % tabWidth)
                    default:
                        break loop
                }
                
                if isIndentLevel {
                    indexes.append(characterIndex)
                }
            }
            
            guard !indexes.isEmpty else { return }
            
            indentIndexes.append((range, indexes))
        }
        
        guard !indentIndexes.isEmpty else { return }
        
        NSGraphicsContext.saveGraphicsState()
        
        color.set()
        let lineWidth: CGFloat = 0.5
        let scaleFactor = NSGraphicsContext.current?.cgContext.ctm.a ?? 1
        
        // draw guides logical line by logical line
        for (lineRange, indexes) in indentIndexes {
            // calculate vertical area to draw lines
            let glyphIndex = self.glyphIndexForCharacter(at: lineRange.location)
            var effectiveRange: NSRange = .notFound
            let lineFragment = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveRange)
            let guideLength: CGFloat = {
                guard !effectiveRange.contains(lineRange.upperBound - 1) else { return lineFragment.height }
                
                let lastGlyphIndex = self.glyphIndexForCharacter(at: lineRange.upperBound - 1)
                let lastLineFragment = self.lineFragmentRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)
                
                // check whether hanging indent is enabled
                guard lastLineFragment.minX != lineFragment.minX else { return lineFragment.height }
                
                return lastLineFragment.maxY - lineFragment.minY
            }()
            let guideSize = NSSize(width: lineWidth, height: guideLength)
            
            // draw lines
            for index in indexes {
                let glyphIndex = self.glyphIndexForCharacter(at: index)
                let glyphLocation = self.location(forGlyphAt: glyphIndex)
                let guideOrigin = lineFragment.origin.offset(by: origin).offsetBy(dx: glyphLocation.x).aligned(scale: scaleFactor)
                let guideRect = NSRect(origin: guideOrigin, size: guideSize)
                
                guideRect.fill()
            }
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
}


private extension CGPoint {
    
    /// Make the point pixel-perfect with the desired scale.
    ///
    /// - Parameter scale: The scale factor in which the receiver to be pixel-perfect.
    /// - Returns: An adjusted point.
    func aligned(scale: CGFloat = 1) -> Self {
        
        return Self(x: (self.x * scale).rounded() / scale,
                    y: (self.y * scale).rounded() / scale)
    }
    
}
