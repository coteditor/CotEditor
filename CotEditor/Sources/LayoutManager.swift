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

final class LayoutManager: NSLayoutManager, ValidationIgnorable {
    
    // MARK: Public Properties
    
    var ignoresDisplayValidation = false
    
    var showsInvisibles = false {
        
        didSet {
            guard let textStorage = self.textStorage else { return assertionFailure() }
            guard showsInvisibles != oldValue else { return }
            
            let wholeRange = textStorage.range
            
            if self.showsOtherInvisibles {
                // -> force recaluculate layout in order to make spaces for control characters drawing
                self.invalidateGlyphs(forCharacterRange: wholeRange, changeInLength: 0, actualCharacterRange: nil)
                self.invalidateLayout(forCharacterRange: wholeRange, actualCharacterRange: nil)
            } else {
                self.invalidateDisplay(forCharacterRange: wholeRange)
            }
        }
    }
    
    var usesAntialias = true
    
    var textFont: NSFont? {
        
        // store text font to avoid the issue where the line height can be different by composite font
        // -> DO NOT use `self.firstTextView?.font`, because when the specified font doesn't suuport
        //    the first character of the text view content, it returns a fallback font for the first one.
        didSet {
            guard let textFont = self.textFont else { return }
            
            // cache metric values to fix line height
            self.defaultLineHeight = self.defaultLineHeight(for: textFont)
            self.defaultBaselineOffset = self.defaultBaselineOffset(for: textFont)
            
            // cache width of space char for hanging indent width calculation
            self.spaceWidth = textFont.spaceWidth
            
            self.invisibleLines = self.generateInvisibleLines()
            self.replacementGlyphWidth = self.invisibleLines.replacement.bounds().width
        }
    }
    
    var invisiblesColor = NSColor.disabledControlTextColor {
        
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
        
        let space: CTLine
        let tab: CTLine
        let newLine: CTLine
        let fullwidthSpace: CTLine
        let replacement: CTLine
    }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.applyDefaultInvisiblesSetting()
        
        // Since NSLayoutManager's showsControlCharacters flag is totally buggy (at least on El Capitan),
        // we stopped using it since CotEditor 2.3.3 released in 2016-01.
        // Previously, CotEditor used this flag for "Other Invisible Characters."
        // However, as CotEditor draws such control-glyph-alternative-characters by itself in `drawGlyphs(forGlyphRange:at:)`,
        // this flag is actually not so necessary as I thougth. Thus, treat carefully this.
        self.showsControlCharacters = false
        
        self.typesetter = ATSTypesetter()
        
        // observe change in defaults
        let defaultKeys: [DefaultKeys] = [
            .invisibleSpace,
            .invisibleTab,
            .invisibleNewLine,
            .invisibleFullwidthSpace,
            
            .showInvisibleSpace,
            .showInvisibleTab,
            .showInvisibleNewLine,
            .showInvisibleFullwidthSpace,
            
            .showOtherInvisibleChars,
            ]
        self.defaultsObservers = UserDefaults.standard.observe(keys: defaultKeys) { [weak self] (key, _) in
            guard let self = self else { return assertionFailure() }
            
            self.applyDefaultInvisiblesSetting()
            self.invisibleLines = self.generateInvisibleLines()
            
            guard let textView = self.firstTextView else { return }
            
            if key == .showOtherInvisibleChars {
                self.invalidateLayout(forCharacterRange: self.attributedString().range, actualCharacterRange: nil)
            }
            textView.setNeedsDisplay(textView.visibleRect, avoidAdditionalLayout: (key != .showOtherInvisibleChars))
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
        
        // -> height of the extra line fragment should be the same as normal other fragments that are likewise customized in ATSTypesetter
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
            let context = NSGraphicsContext.current?.cgContext,
            let string = self.textStorage?.string as NSString?
        {
            let isVertical = (self.firstTextView?.layoutOrientation == .vertical)
            let isRTL = (self.firstTextView?.baseWritingDirection == .rightToLeft)
            let isOpaque = self.firstTextView?.isOpaque ?? true
            
            if !isOpaque {
                context.setShouldSmoothFonts(false)
            }
            
            // flip coordinate if needed
            if NSGraphicsContext.current?.isFlipped == true {
                context.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)
            }
            
            // draw invisibles glyph by glyph
            for glyphIndex in glyphsToShow.location..<glyphsToShow.upperBound {
                let charIndex = self.characterIndexForGlyph(at: glyphIndex)
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
                    
                default:
                    guard self.showsOtherInvisibles else { continue }
                    guard self.propertyForGlyph(at: glyphIndex) == .controlCharacter else { continue }
                    line = self.invisibleLines.replacement
                }
                
                // calculate position to draw glyph
                let lineOrigin = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true).origin
                let glyphLocation = self.location(forGlyphAt: glyphIndex)
                var point = lineOrigin.offset(by: origin).offsetBy(dx: glyphLocation.x,
                                                                   dy: self.defaultBaselineOffset)
                if isVertical {
                    // [note] Probably not a good solution but better than doing nothing (2016-05-25).
                    point.y += line.bounds(options: .useGlyphPathBounds).height / 2
                }
                if isRTL, invisible == .newLine {
                    point.x -= line.bounds().width
                }
                
                // draw character
                context.textPosition = point
                CTLineDraw(line, context)
            }
            
            if !isOpaque {
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
    
    
    
    // MARK: Public Methods
    
    /// return fixed line height to avoid having different line height by composite font
    var lineHeight: CGFloat {
        
        let multiple = self.firstTextView?.defaultParagraphStyle?.lineHeightMultiple ?? 1.0
        
        return multiple * self.defaultLineHeight
    }
    
    
    
    // MARK: Private Methods
    
    /// apply invisible settings
    private func applyDefaultInvisiblesSetting() {
        
        let defaults = UserDefaults.standard
        // `showsInvisibles` will be set from EditorTextView or PrintTextView
        self.showsSpace = defaults[.showInvisibleSpace]
        self.showsTab = defaults[.showInvisibleTab]
        self.showsNewLine = defaults[.showInvisibleNewLine]
        self.showsFullwidthSpace = defaults[.showInvisibleFullwidthSpace]
        self.showsOtherInvisibles = defaults[.showOtherInvisibleChars]
    }
    
    
    /// cache CTLines for invisible characters drawing
    private func generateInvisibleLines() -> InvisibleLines {
        
        let fontSize = self.textFont?.pointSize ?? 0
        let font = NSFont.systemFont(ofSize: fontSize)
        let textFont = self.textFont ?? font
        let fullWidthFont = NSFont(named: .hiraginoSans, size: fontSize) ?? font
        
        return InvisibleLines(space: self.invisibleLine(.space, font: textFont),
                              tab: self.invisibleLine(.tab, font: font),
                              newLine: self.invisibleLine(.newLine, font: font),
                              fullwidthSpace: self.invisibleLine(.fullwidthSpace, font: fullWidthFont),
                              replacement: self.invisibleLine(.replacement, font: textFont))
    }
    
    
    /// create CTLine for given invisible type
    private func invisibleLine(_ invisible: Invisible, font: NSFont) -> CTLine {
        
        return CTLine.create(string: invisible.usedSymbol, color: self.invisiblesColor, font: font)
    }
    
}



// MARK: -

private extension CTLine {
    
    /// convenient initializer for CTLine
    class func create(string: String, color: NSColor, font: NSFont) -> CTLine {
        
        let attrString = NSAttributedString(string: string, attributes: [.foregroundColor: color,
                                                                         .font: font])
        
        return CTLineCreateWithAttributedString(attrString)
    }
    
    
    /// get bounds in a objective way.
    func bounds(options: CTLineBoundsOptions = []) -> CGRect {
        
        return CTLineGetBoundsWithOptions(self, options)
    }
    
}
