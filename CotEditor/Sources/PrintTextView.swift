//
//  PrintTextView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-10-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2024 1024jp
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

final class PrintTextView: NSTextView, Themable {
    
    struct DocumentInfo {
        
        var name: String
        var fileURL: URL?
        var lastModifiedDate: Date?
        var syntaxName: String
    }
    
    
    // MARK: Constants
    
    static let margin = NSEdgeInsets(top: 56, left: 24, bottom: 56, right: 24)
    
    private let lineFragmentPadding: Double = 18
    private let lineNumberPadding: Double = 10
    private let headerFooterFontSize: Double = 9
    
    
    // MARK: Public Properties
    
    private(set) var theme: Theme?
    
    
    // MARK: Private Properties
    
    private let documentInfo: DocumentInfo
    private let tabWidth: Int
    private let lineHeight: CGFloat
    private var printsLineNumber = false
    private var xOffset: CGFloat = 0
    private var lastPaperContentSize: NSSize = .zero
    
    
    
    // MARK: Lifecycle
    
    init(info: DocumentInfo) {
        
        self.documentInfo = info
        self.tabWidth = UserDefaults.standard[.tabWidth]
        self.lineHeight = UserDefaults.standard[.lineHeight]
        
        // setup textContainer
        let textContainer = TextContainer()
        textContainer.widthTracksTextView = true
        textContainer.isHangingIndentEnabled = UserDefaults.standard[.enablesHangingIndent]
        textContainer.hangingIndentWidth = UserDefaults.standard[.hangingIndentWidth]
        textContainer.lineFragmentPadding = self.lineFragmentPadding
        // -> If padding is changed while printing, the print area can be cropped due to text wrapping.
        
        // setup textView components
        let textStorage = NSTextStorage()
        let layoutManager = PrintLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        super.init(frame: .zero, textContainer: textContainer)
        
        self.maxSize = .infinite
        self.isHorizontallyResizable = false
        self.isVerticallyResizable = true
        
        self.linkTextAttributes = UserDefaults.standard[.autoLinkDetection]
            ? [.underlineStyle: NSUnderlineStyle.single.rawValue]
            : [:]
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Text View Methods
    
    override var textContainerOrigin: NSPoint {
        
        NSPoint(x: self.xOffset, y: 0)
    }
    
    
    override var isOpaque: Bool {
        
        true
    }
    
    
    override var printJobTitle: String {
        
        self.documentInfo.name
    }
    
    
    override var pageHeader: NSAttributedString {
        
        self.headerFooter(for: .header)
    }
    
    
    override var pageFooter: NSAttributedString {
        
        self.headerFooter(for: .footer)
    }
    
    
    override var font: NSFont? {
        
        didSet {
            guard let font else { return }
            
            // setup paragraph style
            let paragraphStyle = (self.defaultParagraphStyle ?? .default).mutable
            paragraphStyle.tabStops = []
            paragraphStyle.defaultTabInterval = CGFloat(self.tabWidth) * font.width(of: " ")
            paragraphStyle.lineHeightMultiple = self.lineHeight
            self.defaultParagraphStyle = paragraphStyle
            self.typingAttributes[.paragraphStyle] = paragraphStyle
            self.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: self.string.nsRange)
            
            // set font also to layout manager
            (self.layoutManager as? LayoutManager)?.textFont = font
        }
    }
    
    
    /// Returns the number of pages available for printing.
    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        
        if let printInfo = NSPrintOperation.current?.printInfo {
            // set scope to print
            (self.layoutManager as? PrintLayoutManager)?.visibleRange = printInfo.isSelectionOnly ? self.selectedRange : nil
            
            // adjust content size based on print setting
            let paperContentSize = printInfo.paperContentSize
            if self.lastPaperContentSize != paperContentSize {
                self.lastPaperContentSize = paperContentSize
                self.frame.size = paperContentSize
                self.layoutManager?.doForegroundLayout()
            }
        }
        
        return super.knowsPageRange(range)
    }
    
    
    override func viewWillDraw() {
        
        super.viewWillDraw()
        
        // apply print settings
        self.applyPrintSettings()
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        // store graphics state to keep line number area drawable
        // -> Otherwise, line numbers can be cropped. (2016-03 by 1024jp)
        NSGraphicsContext.saveGraphicsState()
        
        super.draw(dirtyRect)
        
        NSGraphicsContext.restoreGraphicsState()
        
        // draw line numbers if needed
        if self.printsLineNumber {
            guard
                let layoutManager = self.layoutManager as? PrintLayoutManager,
                let textContainer = self.textContainer
            else { return assertionFailure() }
            
            // determine range to draw numbers
            guard
                let dirtyRange = self.range(for: dirtyRect, withoutAdditionalLayout: true),
                let range = if let visibleRange = layoutManager.visibleRange {
                    dirtyRange.intersection(visibleRange)
                } else {
                    dirtyRange
                } else { return }
            
            // prepare text attributes for line numbers
            let numberFontSize = (0.9 * (self.font?.pointSize ?? 12)).rounded()
            let numberFont = NSFont.lineNumberFont(ofSize: numberFontSize)
            let attrs: [NSAttributedString.Key: Any] = [.font: numberFont,
                                                        .foregroundColor: self.textColor ?? .textColor]
            
            // calculate character width using `8` as the representative character
            let numberSize = NSAttributedString(string: "8", attributes: attrs).size()
            
            // adjust values for line number drawing
            let horizontalOrigin = self.baseWritingDirection != .rightToLeft
                ? self.textContainerOrigin.x + textContainer.lineFragmentPadding - self.lineNumberPadding
                : self.textContainerOrigin.x + textContainer.size.width
            let baselineOffset = layoutManager.baselineOffset(for: self.layoutOrientation)
            let numberAscender = numberFont.ascender
            
            // vertical text
            let isVerticalText = self.layoutOrientation == .vertical
            if isVerticalText {
                // rotate axis
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current?.cgContext.rotate(by: -.pi / 2)
            }
            
            self.enumerateLineFragments(in: range, options: .bySkippingExtraLine) { (lineRect, lineNumber, _) in
                // draw number only every 5 times
                let numberString = (!isVerticalText || lineNumber == 1 || lineNumber.isMultiple(of: 5)) ? String(lineNumber) :  "·"
                
                // adjust position to draw
                let width = CGFloat(numberString.count) * numberSize.width
                let point = isVerticalText
                    ? NSPoint(x: -lineRect.midY - width / 2,
                              y: horizontalOrigin - numberSize.height)
                    : NSPoint(x: horizontalOrigin - width,  // - width to align to right
                              y: lineRect.minY + baselineOffset - numberAscender)
                
                // draw number
                NSAttributedString(string: numberString, attributes: attrs).draw(at: point)
            }
            
            if isVerticalText {
                NSGraphicsContext.restoreGraphicsState()
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Parses the current print settings in printInfo.
    private func applyPrintSettings() {
        
        guard
            let layoutManager = self.layoutManager as? LayoutManager,
            let printInfo = NSPrintOperation.current?.printInfo
        else { return assertionFailure() }
        
        // set font size
        if let fontSize: CGFloat = printInfo[.fontSize], self.font?.pointSize != fontSize {
            self.font = self.font?.withSize(fontSize)
        }
        
        // set line numbers
        self.printsLineNumber = printInfo[.printsLineNumbers] ?? false
        // adjust paddings considering the line numbers
        let printsAtLeft = (self.printsLineNumber && self.baseWritingDirection != .rightToLeft)
        self.xOffset = printsAtLeft ? self.lineFragmentPadding : 0
        self.textContainerInset.width = printsAtLeft ? self.lineFragmentPadding : 0
        
        // set invisibles
        layoutManager.showsInvisibles = printInfo[.printsInvisibles] ?? false
        
        // set whether draws background
        self.drawsBackground = printInfo[.printsBackground] ?? true
        
        // create theme
        let themeName = printInfo[.theme] ?? ThemeName.blackAndWhite
        let theme = ThemeManager.shared.setting(name: themeName)  // nil for Black and White
        
        guard self.theme?.name != theme?.name else { return }
        
        // set theme
        self.theme = theme
        self.backgroundColor = theme?.background.color ?? .textBackgroundColor  // expensive task
        self.textColor = theme?.text.color ?? .textColor
        layoutManager.invisiblesColor = theme?.invisibles.color ?? .disabledControlTextColor
        
        if let theme {
            layoutManager.invalidateHighlight(theme: theme)
        } else {
            layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: self.string.range)
        }
    }
    
    
    /// Returns the attributed string for header/footer.
    ///
    /// - Parameter type: Whether the string is for header or footer.
    /// - Returns: The attributed string for header/footer.
    private func headerFooter(for location: HeaderFooterLocation) -> NSAttributedString {
        
        guard let printInfo = NSPrintOperation.current?.printInfo else { return NSAttributedString() }
        
        let keys = location.keys
        let primaryInfoType = PrintInfoType(printInfo[keys.primaryContent])
        let primaryAlignment = AlignmentType(printInfo[keys.primaryAlignment]).textAlignment
        let secondaryInfoType = PrintInfoType(printInfo[keys.secondaryContent])
        let secondaryAlignment = AlignmentType(printInfo[keys.secondaryAlignment]).textAlignment
        
        let primaryString = self.printInfoString(type: primaryInfoType)
        let secondaryString = self.printInfoString(type: secondaryInfoType)
        
        return switch (primaryString, secondaryString) {
            // case: empty
            case (.none, .none):
                NSAttributedString()
            
            // case: single content
            case let (.some(string), .none):
                NSAttributedString(string: string, attributes: self.headerFooterAttributes(for: primaryAlignment))
            case let (.none, .some(string)):
                NSAttributedString(string: string, attributes: self.headerFooterAttributes(for: secondaryAlignment))
                
            case let (.some(primaryString), .some(secondaryString)):
                switch (primaryAlignment, secondaryAlignment) {
                    // case: double-sided
                    case (.left, .right):
                        NSAttributedString(string: primaryString + "\t" + secondaryString, attributes: self.headerFooterAttributes(for: .left))
                    case (.right, .left):
                        NSAttributedString(string: secondaryString + "\t" + primaryString, attributes: self.headerFooterAttributes(for: .left))
                        
                    // case: two lines
                    default:
                        [NSAttributedString(string: primaryString, attributes: self.headerFooterAttributes(for: primaryAlignment)),
                         NSAttributedString(string: secondaryString, attributes: self.headerFooterAttributes(for: secondaryAlignment))]
                            .joined(separator: "\n")
                }
        }
    }
    
    
    /// Returns the attributes for header/footer string.
    ///
    /// - Parameter alignment: The text alignment.
    /// - Returns: The attributes for NSAttributedString.
    private func headerFooterAttributes(for alignment: NSTextAlignment) -> [NSAttributedString.Key: Any] {
        
        let font = NSFont.userFont(ofSize: self.headerFooterFontSize)
        
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        paragraphStyle.alignment = alignment
        
        // tab stop for double-sided alignment (imitation of super.pageHeader)
        if let printInfo = NSPrintOperation.current?.printInfo {
            let xMax = printInfo.paperSize.width - printInfo.topMargin / 2
            paragraphStyle.tabStops = [NSTextTab(type: .rightTabStopType, location: xMax)]
        }
        
        return [.font: font,
                .paragraphStyle: paragraphStyle]
            .compactMapValues { $0 }
    }
    
    
    /// Returns the string for header/footer.
    ///
    /// - Parameter type: Whether the string is for header or footer.
    /// - Returns: The string for given info type.
    private func printInfoString(type: PrintInfoType) -> String? {
        
        switch type {
            case .documentName:
                self.documentInfo.name
            case .syntaxName:
                self.documentInfo.syntaxName
            case .filePath:
                self.documentInfo.fileURL?.pathAbbreviatingWithTilde ?? self.documentInfo.name
            case .printDate:
                String(localized: "Printed on \(.now, format: .dateTime)", comment: "print header/footer (%@ is date)")
            case .lastModifiedDate:
                self.documentInfo.lastModifiedDate
                    .flatMap { String(localized: "Last modified on \($0, format: .dateTime)", comment: "print header/footer (%@ is date)") }
                    ?? "–"
            case .pageNumber:
                NSPrintOperation.current.flatMap { String($0.currentPage) }
            case .none:
                nil
        }
    }
}



private extension NSLayoutManager {
    
    /// This method causes the text to be laid out in the foreground.
    ///
    /// - Note: This method is based on `textEditDoForegroundLayoutToCharacterIndex:` in Apple's TextView.app source code.
    func doForegroundLayout() {
        
        guard self.numberOfGlyphs > 0 else { return }
        
        // cause layout by asking a question which has to determine where the glyph is
        self.textContainer(forGlyphAt: self.numberOfGlyphs - 1, effectiveRange: nil)
    }
}



// MARK: -

private final class PrintLayoutManager: LayoutManager {
    
    var visibleRange: NSRange? {
        
        didSet {
            guard visibleRange != oldValue else { return }
            
            let range = self.attributedString().range
            self.invalidateGlyphs(forCharacterRange: range, changeInLength: 0, actualCharacterRange: nil)
            self.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)  // important for vertical orientation
            self.ensureGlyphs(forCharacterRange: range)
            self.ensureLayout(forCharacterRange: range)
        }
    }
    
    
    func layoutManager(_ layoutManager: NSLayoutManager, shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>, properties: UnsafePointer<NSLayoutManager.GlyphProperty>, characterIndexes: UnsafePointer<Int>, font: NSFont, forGlyphRange glyphRange: NSRange) -> Int {
        
        // hide unselected glyphs if set so
        guard
            let visibleRange = self.visibleRange,
            self.attributedString().length != visibleRange.length
        else { return 0 }  // return 0 for the default processing
        
        let glyphIndexesToHide = (0..<glyphRange.length).filter { !visibleRange.contains(characterIndexes[$0]) }
        
        guard !glyphIndexesToHide.isEmpty else { return 0 }
        
        let newProperties = UnsafeMutablePointer(mutating: properties)
        for index in glyphIndexesToHide {
            newProperties[index].insert(.null)
        }
        
        layoutManager.setGlyphs(glyphs, properties: newProperties, characterIndexes: characterIndexes, font: font, forGlyphRange: glyphRange)
        
        return glyphRange.length
    }
    
    
    override func layoutManager(_ layoutManager: NSLayoutManager, shouldUse action: NSLayoutManager.ControlCharacterAction, forControlCharacterAt charIndex: Int) -> NSLayoutManager.ControlCharacterAction {
        
        // zero width for folded characters
        if self.visibleRange?.contains(charIndex) == false {
            return .zeroAdvancement
        }
        
        return super.layoutManager(layoutManager, shouldUse: action, forControlCharacterAt: charIndex)
    }
}



// MARK: -

private enum HeaderFooterLocation {
    
    case header
    case footer
    
    
    struct Keys {
        
        var primaryContent: NSPrintInfo.AttributeKey
        var primaryAlignment: NSPrintInfo.AttributeKey
        var secondaryContent: NSPrintInfo.AttributeKey
        var secondaryAlignment: NSPrintInfo.AttributeKey
    }
    
    
    var keys: Keys {
        
        switch self {
            case .header:
                Keys(primaryContent: .primaryHeaderContent,
                     primaryAlignment: .primaryHeaderAlignment,
                     secondaryContent: .secondaryHeaderContent,
                     secondaryAlignment: .secondaryHeaderAlignment)
                
            case .footer:
                Keys(primaryContent: .primaryFooterContent,
                     primaryAlignment: .primaryFooterAlignment,
                     secondaryContent: .secondaryFooterContent,
                     secondaryAlignment: .secondaryFooterAlignment)
        }
    }
}



private extension AlignmentType {
    
    var textAlignment: NSTextAlignment {
        
        switch self {
            case .left: .left
            case .center: .center
            case .right: .right
        }
    }
}
