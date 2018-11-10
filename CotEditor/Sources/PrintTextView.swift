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
//  © 2014-2018 1024jp
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

final class PrintTextView: NSTextView, NSLayoutManagerDelegate, Themable {
    
    // MARK: Constants
    
    static let verticalPrintMargin: CGFloat = 56.0    // default 90.0
    static let horizontalPrintMargin: CGFloat = 24.0  // default 72.0
    
    private let lineFragmentPadding: CGFloat = 20.0
    private let lineNumberPadding: CGFloat = 10.0
    private let headerFooterFontSize: CGFloat = 9.0
    

    // MARK: Public Properties
    
    var filePath: String?
    var documentName: String?
    private(set) var theme: Theme?
    private(set) lazy var syntaxParser = SyntaxParser(textStorage: self.textStorage!)
    
    
    // settings on current window to be set by Document.
    // These values are used if set option is "Same as document's setting"
    var documentShowsLineNumber = false
    var documentShowsInvisibles = false
    
    
    // MARK: Private Properties
    
    private var lineHeight: CGFloat
    private var printsLineNumber = false
    private var xOffset: CGFloat = 0
    private let dateFormatter: DateFormatter
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init() {
        
        // prepare date formatter
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = UserDefaults.standard[.headerFooterDateFormat]
        
        self.lineHeight = UserDefaults.standard[.lineHeight]
        
        // dirty workaround to obtain auto-generated textContainer (2016-07 on OS X 10.11)
        // cf. https://stackoverflow.com/questions/34616892/
        let dummyTextView = NSTextView()
        
        super.init(frame: .zero, textContainer: dummyTextView.textContainer)
        
        // specify text container padding
        // -> If padding is changed while printing, print area can be cropped due to text wrapping
        self.textContainer?.lineFragmentPadding = self.lineFragmentPadding
        
        self.maxSize = .infinite
        
        // replace layoutManager
        let layoutManager = LayoutManager()
        layoutManager.delegate = self
        self.textContainer!.replaceLayoutManager(layoutManager)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        self.layoutManager?.delegate = nil
    }
    
    
    
    // MARK: Text View Methods
    
    /// job title
    override var printJobTitle: String {
        
        return self.documentName ?? super.printJobTitle
    }
    
    
    /// prepare for drawing
    override func beginDocument() {
        
        super.beginDocument()
        
        guard let printInfo = NSPrintOperation.current?.printInfo else { return }
        
        self.applyPrintSettings(printInfo: printInfo)
        self.resizeFrame(printInfo: printInfo)
        
    }
    
    
    /// draw
    override func draw(_ dirtyRect: NSRect) {
        
        // store graphics state to keep line number area drawable
        //   -> Otherwise, line numbers can be cropped. (2016-03 by 1024jp)
        NSGraphicsContext.saveGraphicsState()
        
        super.draw(dirtyRect)
        
        NSGraphicsContext.restoreGraphicsState()
        
        // draw line numbers if needed
        if self.printsLineNumber {
            // prepare text attributes for line numbers
            let fontSize = round(0.9 * (self.font?.pointSize ?? 12))
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.lineNumberFont(ofSize: fontSize),
                                                        .foregroundColor: self.textColor ?? .textColor]
            
            // calculate character width by treating the font as a mono-space font
            let charSize = NSAttributedString(string: "8", attributes: attrs).size()
            
            // adjust values for line number drawing
            let horizontalOrigin = self.textContainerOrigin.x + self.lineFragmentPadding - self.lineNumberPadding
            
            // vertical text
            let isVerticalText = self.layoutOrientation == .vertical
            if isVerticalText {
                // rotate axis
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current?.cgContext.rotate(by: -CGFloat.pi / 2)
            }
            
            self.enumerateLineFragments(in: dirtyRect, includingExtraLine: false) { (line, lineRect) in
                guard let numberString: String = {
                    switch line {
                    case .new(let lineNumber, _):
                        if isVerticalText, lineNumber != 1, lineNumber % 5 != 0 {
                            return "·"  // draw real number only in every 5 times
                        }
                        return String(lineNumber)
                        
                    case .wrapped:
                        guard !isVerticalText else { return nil }
                        return "-"
                    }
                    }() else { return }
                
                // adjust position to draw
                var point = NSPoint(x: horizontalOrigin, y: lineRect.maxY - charSize.height)
                let digit = numberString.count
                if isVerticalText {
                    let width = charSize.width * CGFloat(digit) + charSize.height
                    point = NSPoint(x: -point.y - width / 2,
                                    y: point.x - charSize.height)
                } else {
                    point.x -= CGFloat(digit) * charSize.width  // align right
                }
                
                // draw number
                NSAttributedString(string: numberString, attributes: attrs).draw(at: point)
            }
            
            if isVerticalText {
                NSGraphicsContext.restoreGraphicsState()
            }
        }
    }
    
    
    /// return page header attributed string
    override var pageHeader: NSAttributedString {
        
        return self.headerFooter(for: .header)
    }
    
    
    /// return page footer attributed string
    override var pageFooter: NSAttributedString {
        
        return self.headerFooter(for: .footer)
    }
    
    
    /// view's opacity
    override var isOpaque: Bool {
        
        return true
    }
    
    
    /// the top/left point of text container
    override var textContainerOrigin: NSPoint {
        
        return NSPoint(x: self.xOffset, y: 0)
    }
    
    
    /// set printing font
    override var font: NSFont? {
        
        willSet {
            // set tab width
            let paragraphStyle = NSParagraphStyle.default.mutable
            let tabWidth = UserDefaults.standard[.tabWidth]
            
            paragraphStyle.tabStops = []
            paragraphStyle.defaultTabInterval = CGFloat(tabWidth) * (newValue?.spaceWidth ?? 0)
            paragraphStyle.lineHeightMultiple = self.lineHeight
            self.defaultParagraphStyle = paragraphStyle
            
            // apply to current string
            if let textStorage = self.textStorage {
                textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: textStorage.string.nsRange)
            }
            
            // set font also to layout manager
            if let layoutManager = self.layoutManager as? LayoutManager {
                layoutManager.textFont = newValue
            }
        }
    }
    
    
    
    // MARK: Layout Manager Delegate
    
    func layoutManager(_ layoutManager: NSLayoutManager, shouldUseTemporaryAttributes attrs: [NSAttributedString.Key: Any] = [:], forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: NSRangePointer?) -> [NSAttributedString.Key: Any]? {
        
        return attrs
    }
    
    
    
    // MARK: Private Methods
    
    /// parse current print settings in printInfo
    private func applyPrintSettings(printInfo: NSPrintInfo) {
        
        guard let layoutManager = self.layoutManager as? LayoutManager else { return }
        
        let settings = printInfo.dictionary() as! [NSPrintInfo.AttributeKey: Any]
        
        // check whether print line numbers
        self.printsLineNumber = {
            switch PrintLineNmuberMode(settings[.lineNumber] as? Int) {
            case .no:
                return false
            case .sameAsDocument:
                return self.documentShowsLineNumber
            case .yes:
                return true
            }
        }()
        
        // adjust paddings considering the line numbers
        self.xOffset = self.printsLineNumber ? self.lineFragmentPadding : 0
        
        // check whether print invisibles
        layoutManager.showsInvisibles = {
            switch PrintInvisiblesMode(settings[.invisibles] as? Int) {
            case .no:
                return false
            case .sameAsDocument:
                return self.documentShowsInvisibles
            case .all:
                return true
            }
        }()
        
        // set theme
        assert(settings[.theme] != nil)
        let lastThemeName = self.theme?.name
        let themeName = (settings[.theme] as? String) ?? ThemeName.blackAndWhite
        let theme = ThemeManager.shared.setting(name: themeName)
        if let theme = theme {
            self.theme = theme
            self.textColor = theme.text.color
            self.backgroundColor = theme.background.color
            layoutManager.invisiblesColor = theme.invisibles.color
            
        } else {  // black and white
            self.theme = nil
            self.textColor = .textColor
            self.backgroundColor = .textBackgroundColor
            layoutManager.invisiblesColor = .secondaryLabelColor
        }
        
        guard lastThemeName != theme?.name else { return }
        
        // perform syntax highlight
        weak var controller = NSPrintOperation.current?.printPanel.accessoryControllers.first as? PrintPanelAccessoryController
        _ = self.syntaxParser.highlightAll {
            DispatchQueue.main.async {
                guard let controller = controller, !controller.view.isHidden else { return }
                
                controller.needsUpdatePreview = true
            }
        }
    }
    
    
    /// resize frame considering layout orientation
    private func resizeFrame(printInfo: NSPrintInfo) {
        
        // calculate view size for print considering text orientation
        var printSize = printInfo.paperSize
        switch self.layoutOrientation {
        case .horizontal:
            printSize.width -= printInfo.leftMargin + printInfo.rightMargin
            printSize.width /= printInfo.scalingFactor
        case .vertical:
            printSize.height -= printInfo.leftMargin + printInfo.rightMargin
            printSize.height /= printInfo.scalingFactor
        }
        
        // adjust frame size
        self.frame.size = printSize
        self.sizeToFit()
        let usedHeight = self.layoutManager!.usedRect(for: self.textContainer!).height
        switch self.layoutOrientation {
        case .horizontal:
            self.frame.size.height = usedHeight
        case .vertical:
            self.frame.size.width = usedHeight
        }
    }
    
    
    /// return attributed string for header/footer
    private func headerFooter(for location: HeaderFooterLocation) -> NSAttributedString {
        
        let keys = location.keys
        
        guard
            let settings = NSPrintOperation.current?.printInfo.dictionary() as? [NSPrintInfo.AttributeKey: Any],
            (settings[keys.needsDraw] as? Bool) ?? false
            else { return NSAttributedString() }
        
        let primaryInfoType = PrintInfoType(settings[keys.primaryContent] as? Int)
        let primaryAlignment = AlignmentType(settings[keys.primaryAlignment] as? Int)
        let secondaryInfoType = PrintInfoType(settings[keys.secondaryContent] as? Int)
        let secondaryAlignment = AlignmentType(settings[keys.secondaryAlignment] as? Int)
        
        let primaryString = self.printInfoString(type: primaryInfoType)
        let secondaryString = self.printInfoString(type: secondaryInfoType)
        
        switch (primaryString, secondaryString) {
        // case: empty
        case (nil, nil):
            return NSAttributedString()
            
        // case: single content
        case let (.some(string), nil):
            return NSAttributedString(string: string, attributes: self.headerFooterAttributes(for: primaryAlignment))
        case let (nil, .some(string)):
            return NSAttributedString(string: string, attributes: self.headerFooterAttributes(for: secondaryAlignment))
            
        case let (.some(primaryString), .some(secondaryString)):
            switch (primaryAlignment, secondaryAlignment) {
            // case: double-sided
            case (.left, .right):
                return NSAttributedString(string: primaryString + "\t\t" + secondaryString, attributes: self.headerFooterAttributes(for: .left))
            case (.right, .left):
                return NSAttributedString(string: secondaryString + "\t\t" + primaryString, attributes: self.headerFooterAttributes(for: .left))
                
            // case: two lines
            default:
                let primaryAttrString = NSAttributedString(string: primaryString, attributes: self.headerFooterAttributes(for: primaryAlignment))
                let secondaryAttrString = NSAttributedString(string: secondaryString, attributes: self.headerFooterAttributes(for: secondaryAlignment))
                
                return primaryAttrString + NSAttributedString(string: "\n") + secondaryAttrString
            }
        }
    }
    
    
    /// return attributes for header/footer string
    private func headerFooterAttributes(for alignment: AlignmentType) -> [NSAttributedString.Key: Any] {
    
        let paragraphStyle = NSParagraphStyle.default.mutable
        
        // alignment for two lines
        paragraphStyle.alignment = alignment.textAlignment
        
        // tab stops for double-sided alignment (imitation of [super pageHeader])
        if let printInfo = NSPrintOperation.current?.printInfo {
            let rightTabLocation = printInfo.paperSize.width - printInfo.topMargin / 2
            paragraphStyle.tabStops = [NSTextTab(type: .centerTabStopType, location: rightTabLocation / 2),
                                       NSTextTab(type: .rightTabStopType, location: rightTabLocation)]
        }
        
        // line break mode to truncate middle
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        
        // font
        guard let font = NSFont.userFont(ofSize: self.headerFooterFontSize) else {
            return [.paragraphStyle: paragraphStyle]
        }
        
        return [.paragraphStyle: paragraphStyle,
                .font: font]
    }
    
    
    /// create string for header/footer
    private func printInfoString(type: PrintInfoType) -> String? {
        
        switch type {
        case .documentName:
            return self.documentName
            
        case .syntaxName:
            return self.syntaxParser.style.name
            
        case .filePath:
            guard let filePath = self.filePath else {  // print document name instead if document doesn't have file path yet
                return self.documentName
            }
            if UserDefaults.standard[.headerFooterPathAbbreviatingWithTilde] {
                return filePath.abbreviatingWithTildeInSandboxedPath
            }
            return filePath
            
        case .printDate:
            return String(format: "Printed on %@".localized, self.dateFormatter.string(from: Date()))
            
        case .pageNumber:
            guard let pageNumber = NSPrintOperation.current?.currentPage else { return nil }
            return String(pageNumber)
            
        case .none:
            return nil
        }
    }
    
}



// MARK: -

private enum HeaderFooterLocation {
    
    case header
    case footer
    
    
    struct Keys {
        
        var needsDraw: NSPrintInfo.AttributeKey
        var primaryContent: NSPrintInfo.AttributeKey
        var primaryAlignment: NSPrintInfo.AttributeKey
        var secondaryContent: NSPrintInfo.AttributeKey
        var secondaryAlignment: NSPrintInfo.AttributeKey
    }
    
    
    var keys: Keys {
        
        switch self {
        case .header:
            return Keys(needsDraw: .printsHeader,
                        primaryContent: .primaryHeaderContent,
                        primaryAlignment: .primaryHeaderAlignment,
                        secondaryContent: .secondaryHeaderContent,
                        secondaryAlignment: .secondaryHeaderAlignment)
            
        case .footer:
            return Keys(needsDraw: .printsFooter,
                        primaryContent: .primaryFooterContent,
                        primaryAlignment: .primaryFooterAlignment,
                        secondaryContent: .secondaryFooterContent,
                        secondaryAlignment: .secondaryFooterAlignment)
        }
    }
    
}



private extension AlignmentType {
    
    var textAlignment: NSTextAlignment {
        
        switch self {
        case .left:
            return .left
        case .center:
            return .center
        case .right:
            return .right
        }
    }
}
