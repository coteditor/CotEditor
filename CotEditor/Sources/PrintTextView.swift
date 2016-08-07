/*
 
 PrintTextView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-10-01.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

let kVerticalPrintMargin: CGFloat = 56.0    // default 90.0
let kHorizontalPrintMargin: CGFloat = 24.0  // default 72.0

private let kLineFragmentPadding: CGFloat = 20.0
private let kLineNumberPadding: CGFloat = 10.0
private let kHeaderFooterFontSize: CGFloat = 9.0

private let kLineNumberFontName = "AvenirNextCondensed-Regular"



final class PrintTextView: NSTextView, NSLayoutManagerDelegate, Themable {

    // MARK: Public Properties
    
    var filePath: String?
    var documentName: String?
    var syntaxName: String?
    var theme: Theme?
    
    
    // settings on current window to be set by Document.
    // These values are used if set option is "Same as document's setting"
    var documentShowsLineNumber = false
    var documentShowsInvisibles = false
    
    
    // MARK: Private Properties
    
    private var lineHeight: CGFloat
    private var printsLineNumber = false
    private var xOffset: CGFloat = 0
    private var syntaxStyle: SyntaxStyle?
    private let dateFormatter: DateFormatter
    
    
    // MARK:
    // MARK: Lifecycle
    
    init() {
        
        // prepare date formatter
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = UserDefaults.standard.string(forKey: DefaultKey.headerFooterDateFormat)
        
        self.lineHeight = UserDefaults.standard.cgFloat(forKey: DefaultKey.lineHeight)
        
        // dirty workaround to obtain auto-generated textContainer (2016-07 on OS X 10.11)
        // cf. http://stackoverflow.com/questions/34616892/
        let dummyTextView = NSTextView()
        
        super.init(frame: dummyTextView.frame, textContainer: dummyTextView.textContainer)
        
        // fix text container padding
        // -> If padding is changed while printing, print area can be cropped due to text wrapping
        self.textContainer?.lineFragmentPadding = kLineFragmentPadding
        
        // mimic as if view is created with `init()` inizializer (2016-07 on OS X 10.11)
        self.maxSize = dummyTextView.maxSize
        self.isHorizontallyResizable = dummyTextView.isHorizontallyResizable
        self.isVerticallyResizable = dummyTextView.isVerticallyResizable
        
        // replace layoutManager
        let layoutManager = LayoutManager()
        layoutManager.delegate = self
        layoutManager.usesScreenFonts = false
        self.textContainer?.replaceLayoutManager(layoutManager)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Text View Methods
    
    /// job title
    override var printJobTitle: String {
        
        return self.documentName ?? super.printJobTitle
    }
    
    
    /// draw
    override func draw(_ dirtyRect: NSRect) {
        
        self.loadPrintSettings()
        
        // store graphics state to keep line number area drawable
        //   -> Otherwise, line numbers can be cropped. (2016-03 by 1024jp)
        NSGraphicsContext.saveGraphicsState()
        
        super.draw(dirtyRect)
        
        NSGraphicsContext.restoreGraphicsState()
        
        // draw line numbers if needed
        if self.printsLineNumber,
            let string = self.string,
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
        {
            // prepare text attributes for line numbers
            let fontSize = round(0.9 * (self.font?.pointSize ?? 12))
            let font = NSFont(name: kLineNumberFontName, size: fontSize) ?? NSFont.userFixedPitchFont(ofSize: fontSize)!
            let attrs = [NSFontAttributeName: font,
                         NSForegroundColorAttributeName: self.textColor ?? .textColor]
            
            // calculate character width by treating the font as a mono-space font
            let charSize = NSAttributedString(string: "8", attributes: attrs).size()
            
            // adjust values for line number drawing
            let horizontalOrigin = self.textContainerOrigin.x + kLineFragmentPadding - kLineNumberPadding
            
            // vertical text
            let isVerticalText = self.layoutOrientation == .vertical
            if isVerticalText {
                // rotate axis
                NSGraphicsContext.saveGraphicsState()
                let transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
                NSGraphicsContext.current()?.cgContext.concatenate(transform)
            }
            
            // get glyph range of which line number should be drawn
            let glyphRangeToDraw = layoutManager.glyphRange(forBoundingRectWithoutAdditionalLayout: dirtyRect, in: textContainer)
            
            // count up lines until visible
            let undisplayedRange = NSRange(location: 0, length: layoutManager.characterIndexForGlyph(at: glyphRangeToDraw.location))
            var lineNumber = max(string.numberOfLines(in: undisplayedRange, includingLastLineEnding: true), 1)  // start with 1
            
            // draw visible line numbers
            var glyphCount = glyphRangeToDraw.location
            var glyphIndex = glyphRangeToDraw.location
            var lastLineNumber = 0
            
            while glyphIndex < glyphRangeToDraw.max {  // count "real" lines
                defer {
                    lineNumber += 1
                }
                
                let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
                let lineRange = (string as NSString).lineRange(at: charIndex)  // get NSRange
                let lineCharacterRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
                glyphIndex = lineCharacterRange.max
                
                while glyphCount < glyphIndex {  // handle wrapped lines
                    var range = NSRange.notFound
                    let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphCount, effectiveRange: &range, withoutAdditionalLayout: true)
                    let isWrappedLine = (lastLineNumber == lineNumber)
                    lastLineNumber = lineNumber
                    glyphCount = range.max
                    
                    if isVerticalText && isWrappedLine { continue }
                    
                    var numberString = isWrappedLine ? "-" : String(lineNumber)
                    
                    // adjust position to draw
                    var point = NSPoint(x: horizontalOrigin, y: lineRect.maxY - charSize.height)
                    let digit = numberString.characters.count
                    if isVerticalText {
                        numberString = (lineNumber == 1 || lineNumber % 5 == 0) ? numberString : "·"  // draw real number only in every 5 times
                        
                        let width = (charSize.width * CGFloat(digit) + charSize.height)
                        point = NSPoint(x: -point.y - width / 2,
                                        y: point.x - charSize.height)
                    } else {
                        point.x -= CGFloat(digit) * charSize.width   // align right
                    }
                    
                    // draw number
                    NSAttributedString(string: numberString, attributes: attrs).draw(at: point)
                }
            }
            
            if isVerticalText {
                NSGraphicsContext.restoreGraphicsState()
            }
        }
    }
    
    
    /// return page header attributed string
    override var pageHeader: NSAttributedString {
        
        guard let settings = NSPrintOperation.current()?.printInfo.dictionary(),
            (settings[PrintSettingKey.printsHeader.rawValue] as? Bool) ?? false else { return NSAttributedString() }
        
        let primaryInfoType = PrintInfoType(rawValue: settings[PrintSettingKey.primaryHeaderContent.rawValue] as! Int)!
        let primaryAlignment = AlignmentType(rawValue: settings[PrintSettingKey.primaryHeaderAlignment.rawValue] as! Int)!
        let secondaryInfoType = PrintInfoType(rawValue: settings[PrintSettingKey.secondaryHeaderContent.rawValue] as! Int)!
        let secondaryAlignment = AlignmentType(rawValue: settings[PrintSettingKey.secondaryHeaderAlignment.rawValue] as! Int)!
        
        return self.headerFooter(primaryString: self.printInfoString(type: primaryInfoType),
                                 primaryAlignment: primaryAlignment,
                                 secondaryString: self.printInfoString(type: secondaryInfoType),
                                 secondaryAlignment: secondaryAlignment)
    }
    
    
    /// return page footer attributed string
    override var pageFooter: NSAttributedString {
        
        guard let settings = NSPrintOperation.current()?.printInfo.dictionary(),
            (settings[PrintSettingKey.printsFooter.rawValue] as? Bool) ?? false else { return NSAttributedString() }
        
        let primaryInfoType = PrintInfoType(rawValue: settings[PrintSettingKey.primaryFooterContent.rawValue] as! Int)!
        let primaryAlignment = AlignmentType(rawValue: settings[PrintSettingKey.primaryFooterAlignment.rawValue] as! Int)!
        let secondaryInfoType = PrintInfoType(rawValue: settings[PrintSettingKey.secondaryFooterContent.rawValue] as! Int)!
        let secondaryAlignment = AlignmentType(rawValue: settings[PrintSettingKey.secondaryFooterAlignment.rawValue] as! Int)!
        
        return self.headerFooter(primaryString: self.printInfoString(type: primaryInfoType),
                                 primaryAlignment: primaryAlignment,
                                 secondaryString: self.printInfoString(type: secondaryInfoType),
                                 secondaryAlignment: secondaryAlignment)
    }
    
    
    /// flip Y axis
    override var isFlipped: Bool {
        
        return true
    }
    
    
    /// view's opacity
    override var isOpaque: Bool {
        
        return true
    }
    
    
    /// the top/left point of text container
    override var textContainerOrigin: NSPoint {
        
        return NSPoint(x: self.xOffset, y: 0)
    }
    
    
    /// return whether do paganation by itself
    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        
        self.setupPrintSize()
        
        return super.knowsPageRange(range)  // = false
    }
    
    
    /// set printing font
    override var font: NSFont? {
        
        willSet (newFont) {
            // set tab width
            let paragraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
            let tabWidth = UserDefaults.standard.integer(forKey: DefaultKey.tabWidth)
            
            paragraphStyle.tabStops = []
            paragraphStyle.defaultTabInterval = CGFloat(tabWidth) * (newFont?.advancement(character: " ").width ?? 0)
            paragraphStyle.lineHeightMultiple = self.lineHeight
            self.defaultParagraphStyle = paragraphStyle
            
            // apply to current string
            if let textStorage = self.textStorage {
                textStorage.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: textStorage.string.nsRange)
            }
            
            // set font also to layout manager
            if let layoutManager = self.layoutManager as? LayoutManager {
                layoutManager.textFont = newFont
            }
        }
    }
    
    
    
    // MARK: Layout Manager Delegate
    
    func layoutManager(_ layoutManager: NSLayoutManager, shouldUseTemporaryAttributes attrs: [String : AnyObject] = [:], forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: NSRangePointer?) -> [String : AnyObject]? {
        
        if attrs[NSForegroundColorAttributeName] != nil {
            return attrs
        }
        
        return nil
    }
    
    
    
    // MARK: Private Methods
    
    /// parse current print settings in printInfo
    private func loadPrintSettings() {
        
        guard
            let settings = NSPrintOperation.current()?.printInfo.dictionary(),
            let layoutManager = self.layoutManager as? LayoutManager,
            let textStorage = self.textStorage else { return }
        
        // check whether print line numbers
        self.printsLineNumber = {
            guard
                let index = settings[PrintSettingKey.lineNumber.rawValue] as? Int,
                let mode = PrintLineNmuberMode(rawValue: index) else { return false }
            switch mode {
            case .no:
                return false
            case .sameAsDocument:
                return self.documentShowsLineNumber
            case .yes:
                return true
            }
        }()
        
        // adjust paddings considering the line numbers
        self.xOffset = self.printsLineNumber ? kLineFragmentPadding : 0
        
        // check whether print invisibles
        layoutManager.showsInvisibles = {
            guard
                let index = settings[PrintSettingKey.invisibles.rawValue] as? Int,
                let mode = PrintInvisiblesMode(rawValue: index) else { return false }
            switch mode {
            case .no:
                return false
            case .sameAsDocument:
                return self.documentShowsInvisibles
            case .all:
                return true
            }
        }()
        
        // setup syntax highlighting with theme
        let themeName = (settings[PrintSettingKey.theme.rawValue] as? String) ?? BlackAndWhiteThemeName
        if themeName == BlackAndWhiteThemeName {
            layoutManager.removeTemporaryAttribute(NSForegroundColorAttributeName, forCharacterRange: textStorage.string.nsRange)
            self.textColor = .textColor
            self.backgroundColor = .white
            layoutManager.invisiblesColor = .gray
            
        } else {
            if let theme = ThemeManager.shared.theme(name: themeName) {
                self.theme = theme
                self.textColor = theme.textColor
                self.backgroundColor = theme.backgroundColor
                layoutManager.invisiblesColor = theme.invisiblesColor
            }
            
            // perform syntax coloring
            if self.syntaxStyle == nil {
                self.syntaxStyle = SyntaxManager.shared.style(name: self.syntaxName)
                self.syntaxStyle?.textStorage = self.textStorage
            }
            if let controller = NSPrintOperation.current()?.printPanel.accessoryControllers.first as? PrintPanelAccessoryController {
                self.syntaxStyle?.highlightAll { [weak controller] in
                    if let controller = controller, !controller.view.isHidden {
                        controller.needsUpdatePreview = true
                    }
                }
            }
        }
    }
    
    
    /// return attributed string for header/footer
    private func headerFooter(primaryString: String?, primaryAlignment: AlignmentType, secondaryString: String?, secondaryAlignment: AlignmentType) -> NSAttributedString {
        
        // case: empty
        guard primaryString != nil || secondaryString != nil else { return NSAttributedString() }
        
        // case: single content
        if let string = primaryString, secondaryString == nil {
            return NSAttributedString(string: string, attributes: self.headerFooterAttributes(for: primaryAlignment))
        }
        if let string = secondaryString, primaryString == nil {
            return NSAttributedString(string: string, attributes: self.headerFooterAttributes(for: secondaryAlignment))
        }
        guard let primaryString = primaryString, let secondaryString = secondaryString else { fatalError() }
        
        // case: double-sided
        if primaryAlignment == .left && secondaryAlignment == .right {
            return NSAttributedString(string: primaryString + "\t\t" + secondaryString, attributes: self.headerFooterAttributes(for: .left))
        }
        if primaryAlignment == .right && secondaryAlignment == .left {
            return NSAttributedString(string: secondaryString + "\t\t" + primaryString, attributes: self.headerFooterAttributes(for: .left))
        }
        
        // case: two lines
        let primaryAttrString = NSAttributedString(string: primaryString, attributes: self.headerFooterAttributes(for: primaryAlignment))
        let secondaryAttrString = NSAttributedString(string: secondaryString, attributes: self.headerFooterAttributes(for: secondaryAlignment))
        
        return primaryAttrString + NSAttributedString(string: "\n") + secondaryAttrString
    }
    
    
    /// return attributes for header/footer string
    private func headerFooterAttributes(for alignment: AlignmentType) -> [String : AnyObject] {
    
        let paragraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        
        // alignment for two lines
        paragraphStyle.alignment = alignment.textAlignment
        
        // tab stops for double-sided alignment (imitation of [super pageHeader])
        if let printInfo = NSPrintOperation.current()?.printInfo {
            let rightTabLocation = printInfo.paperSize.width - printInfo.topMargin / 2
            paragraphStyle.tabStops = [NSTextTab(type: .centerTabStopType, location: rightTabLocation / 2),
                                       NSTextTab(type: .rightTabStopType, location: rightTabLocation)]
        }
        
        // line break mode to truncate middle
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        
        // font
        guard let font = NSFont.userFont(ofSize: kHeaderFooterFontSize) else {
            return [NSParagraphStyleAttributeName: paragraphStyle]
        }
        
        return [NSParagraphStyleAttributeName: paragraphStyle,
                NSFontAttributeName: font]
    }
    
    
    /// create string for header/footer
    private func printInfoString(type: PrintInfoType) -> String? {
        
        switch type {
        case .documentName:
            return self.documentName
            
        case .syntaxName:
            return self.syntaxName
            
        case .filePath:
            guard let filePath = self.filePath else {  // print document name instead if document doesn't have file path yet
                return self.documentName
            }
            if UserDefaults.standard.bool(forKey: DefaultKey.headerFooterPathAbbreviatingWithTilde) {
                return filePath.abbreviatingWithTildeInSandboxedPath
            } else {
                return filePath
            }
            
        case .printDate:
            return String(format: NSLocalizedString("", comment: ""), self.dateFormatter.string(from: Date()))
            
        case .pageNumber:
            guard let pageNumber = NSPrintOperation.current()?.currentPage else { return nil }
            return String(pageNumber)
            
        case .none:
            return nil
        }
    }
    
    
    /// update text view size considering text orientation
    private func setupPrintSize() {
        
        guard let printInfo = NSPrintOperation.current()?.printInfo else { return }
        
        var frameSize = printInfo.paperSize
        switch self.layoutOrientation {
        case .horizontal:
            frameSize.width -= printInfo.leftMargin + printInfo.rightMargin
            frameSize.width /= printInfo.scalingFactor
        case .vertical:
            frameSize.height -= printInfo.leftMargin + printInfo.rightMargin
            frameSize.height /= printInfo.scalingFactor
        }
        
        self.setFrameSize(frameSize)
        self.sizeToFit()
    }
    
}
