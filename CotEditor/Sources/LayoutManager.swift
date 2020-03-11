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
    
    var textFont: NSFont? {
        
        // store text font to avoid the issue where the line height can be different by composite font
        // -> DO NOT use `self.firstTextView?.font`, because when the specified font doesn't support
        //    the first character of the text view content, it returns a fallback font for the first one.
        didSet {
            guard let textFont = textFont else { return }
            
            // cache metric values to fix line height
            self.defaultLineHeight = self.defaultLineHeight(for: textFont)
            self.defaultBaselineOffset = self.defaultBaselineOffset(for: textFont)
            
            // cache width of space char for hanging indent width calculation
            self.spaceWidth = textFont.spaceWidth
            
            self.invisibleLines = self.generateInvisibleLines()
            self.replacementGlyphWidth = self.invisibleLines.otherControl.bounds().width
        }
    }
    
    var showsInvisibles = false {
        
        didSet {
            guard showsInvisibles != oldValue else { return }
            
            self.invalidateInvisibleDisplay(includingControls: self.showsOtherInvisibles)
        }
    }
    
    var invisiblesColor: NSColor = .disabledControlTextColor {
        
        didSet {
            self.invisibleLines = self.generateInvisibleLines()
        }
    }
    
    private(set) var spaceWidth: CGFloat = 0
    private(set) var replacementGlyphWidth: CGFloat = 0
    private(set) var defaultBaselineOffset: CGFloat = 0  // defaultBaselineOffset for textFont
    private(set) var showsOtherInvisibles = false
    
    
    // MARK: Private Properties
    
    private var defaultsObservers: [UserDefaultsObservation] = []
    
    private var defaultLineHeight: CGFloat = 1.0
    
    private var showsSpace = false
    private var showsTab = false
    private var showsNewLine = false
    private var showsFullwidthSpace = false
    
    private lazy var invisibleLines: InvisibleLines = self.generateInvisibleLines()
    
    
    private struct InvisibleLines {
        
        var space: CTLine
        var tab: CTLine
        var newLine: CTLine
        var fullwidthSpace: CTLine
        var otherControl: CTLine
    }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.applyInvisibleVisibilitySetting()
        
        // -> This `.showsControlCharacters` flag was used for "Other Invisible Characters" in previous CotEditor.
        //    However, since NSLayoutManager's .showsControlCharacters flag is totally buggy (at least on El Capitan),
        //    we turned it off since CotEditor 2.3.3, which was released in 2016-01.
        //    CotEditor now draws such control-alternative characters by itself in `drawGlyphs(forGlyphRange:at:)`.
        //    Thus, this flag is actually no more necessary. Treat carefully if you wanna use it in the future.
        self.showsControlCharacters = false
        
        self.typesetter = Typesetter()
        
        let visibilityKeys: [DefaultKeys] = [
            .showInvisibleSpace,
            .showInvisibleTab,
            .showInvisibleNewLine,
            .showInvisibleFullwidthSpace,
            .showOtherInvisibleChars,
        ]
        self.defaultsObservers += UserDefaults.standard.observe(keys: visibilityKeys) { [unowned self] (key, _) in
            self.applyInvisibleVisibilitySetting()
            self.invalidateInvisibleDisplay(includingControls: key == .showOtherInvisibleChars)
        }
        
        let invisibleSymbolKeys: [DefaultKeys] = [
            .invisibleSpace,
            .invisibleTab,
            .invisibleNewLine,
            .invisibleFullwidthSpace,
        ]
        self.defaultsObservers += UserDefaults.standard.observe(keys: invisibleSymbolKeys) { [unowned self] (_, _) in
            self.invisibleLines = self.generateInvisibleLines()
            self.invalidateInvisibleDisplay(includingControls: false)
        }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        self.defaultsObservers.forEach { $0.invalidate() }
    }
    
    
    
    // MARK: Layout Manager Methods
    
    /// adjust rect of last empty line
    override func setExtraLineFragmentRect(_ fragmentRect: NSRect, usedRect: NSRect, textContainer container: NSTextContainer) {
        
        // -> height of the extra line fragment should be the same as normal other fragments that are likewise customized in Typesetter
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
            let layoutOrientation = self.firstTextView?.layoutOrientation
            let writingDirection = self.firstTextView?.baseWritingDirection
            let disableSmoothFonts = (NSAppKitVersion.current <= .number10_14) || !(self.firstTextView?.isOpaque ?? true)
            
            if disableSmoothFonts {
                context.setShouldSmoothFonts(false)
            }
            
            // flip coordinate if needed
            if NSGraphicsContext.current?.isFlipped == true {
                context.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)
            }
            
            // draw invisibles glyph by glyph
            let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
            for charIndex in characterRange.lowerBound..<characterRange.upperBound {
                let codeUnit = string.character(at: charIndex)
                let invisible = Invisible(codeUnit: codeUnit)
                
                let line: CTLine
                switch invisible {
                    case .space:
                        guard self.showsSpace else { continue }
                        line = self.invisibleLines.space
                    
                    case .tab:
                        guard self.showsTab else { continue }
                        line = self.invisibleLines.tab
                    
                    case .newLine:
                        guard self.showsNewLine else { continue }
                        line = self.invisibleLines.newLine
                    
                    case .fullwidthSpace:
                        guard self.showsFullwidthSpace else { continue }
                        line = self.invisibleLines.fullwidthSpace
                    
                    case .otherControl:
                        guard self.showsOtherInvisibles else { continue }
                        line = self.invisibleLines.otherControl
                    
                    case .none:
                        continue
                }
                
                // calculate position to draw glyph
                let glyphIndex = self.glyphIndexForCharacter(at: charIndex)
                let lineOrigin = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true).origin
                let glyphLocation = self.location(forGlyphAt: glyphIndex)
                var point = lineOrigin.offset(by: origin).offsetBy(dx: glyphLocation.x,
                                                                   dy: self.defaultBaselineOffset)
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
            
            if disableSmoothFonts {
                context.setShouldSmoothFonts(true)
            }
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    /// fill background rectangles with a color
    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<NSRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: NSColor) {
        
        // modify selected highlight color when the window is inactive
        // -> Otherwise, `.secondarySelectedControlColor` will be used forcely and text becomes unreadable
        //    when the window appearance and theme is inconsistent.
        if color == .secondarySelectedControlColor,  // check if inactive
            let theme = (self.textViewForBeginningOfSelection as? Themable)?.theme,
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
    
    
    
    // MARK: Private Methods
    
    /// Invalidate invisible character drawing.
    ///
    /// - Parameter includingControls: Whether invalidate layout also so that control characters can fit.
    private func invalidateInvisibleDisplay(includingControls: Bool) {
        
        let wholeRange = self.attributedString().range
        
        self.invalidateDisplay(forCharacterRange: wholeRange)
        if includingControls {
            self.invalidateLayout(forCharacterRange: wholeRange, actualCharacterRange: nil)
        }
    }
    
    
    /// Apply invisible visibility setting.
    private func applyInvisibleVisibilitySetting() {
        
        let defaults = UserDefaults.standard
        
        // `showsInvisibles` will be set from EditorTextView or PrintTextView
        self.showsSpace = defaults[.showInvisibleSpace]
        self.showsTab = defaults[.showInvisibleTab]
        self.showsNewLine = defaults[.showInvisibleNewLine]
        self.showsFullwidthSpace = defaults[.showInvisibleFullwidthSpace]
        self.showsOtherInvisibles = defaults[.showOtherInvisibleChars]
    }
    
    
    /// Create CTLines to cache for invisible characters drawing.
    ///
    /// - Returns: An InvisibleLines struct.
    private func generateInvisibleLines() -> InvisibleLines {
        
        let fontSize = self.textFont?.pointSize ?? 0
        let font = NSFont.systemFont(ofSize: fontSize)
        let textFont = self.textFont ?? font
        let fullWidthFont = NSFont(named: .hiraginoSans, size: fontSize) ?? font
        
        return InvisibleLines(space: self.invisibleLine(.space, font: textFont),
                              tab: self.invisibleLine(.tab, font: font),
                              newLine: self.invisibleLine(.newLine, font: font),
                              fullwidthSpace: self.invisibleLine(.fullwidthSpace, font: fullWidthFont),
                              otherControl: self.invisibleLine(.otherControl, font: textFont))
    }
    
    
    /// Create a CTLine for given invisible type.
    ///
    /// - Parameters:
    ///   - invisible: The type of invisible character.
    ///   - font: The font for the alternative character.
    /// - Returns: A CTLine of the alternative glyph for the given invisible type.
    private func invisibleLine(_ invisible: Invisible, font: NSFont) -> CTLine {
        
        let attrString = NSAttributedString(string: UserDefaults.standard.invisibleSymbol(for: invisible),
                                            attributes: [.foregroundColor: self.invisiblesColor,
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
