//
//  LineNumberView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-03-30.
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
import CoreText

final class LineNumberView: NSRulerView {
    
    private struct DrawingInfo {
        
        let fontSize: CGFloat
        let charWidth: CGFloat
        let ascent: CGFloat
        let wrappedMarkGlyph: CGGlyph
        let digitGlyphs: [CGGlyph]
        let padding: CGFloat
        let tickLength: CGFloat
        
        private let textFont: NSFont
        private let scale: CGFloat
        
        
        init(textFont: NSFont, scale: CGFloat) {
            
            self.textFont = textFont
            self.scale = scale
            
            // calculate font size for number
            self.fontSize = (LineNumberView.fontSizeFactor * scale * textFont.pointSize).round(interval: 0.5)
            self.ascent = scale * textFont.ascender
            
            // prepare glyphs
            let font = CTFontCreateWithGraphicsFont(LineNumberView.lineNumberFont, self.fontSize, nil, nil)
            self.wrappedMarkGlyph = font.glyph(for: "-".utf16.first!)
            self.digitGlyphs = (0...9).map { font.glyph(for: String($0).utf16.first!) }
            
            // calculate character width assuming the font is monospace
            self.charWidth = font.advance(for: self.digitGlyphs[8]).width
            
            // calculate margins
            self.padding = ceil(self.charWidth)
            self.tickLength = ceil(self.charWidth)
        }
        
        
        func isSameSource(textFont: NSFont, scale: CGFloat) -> Bool {
            
            return (self.textFont == textFont) && (self.scale == scale)
        }
        
    }
    
    
    
    // MARK: Constants
    
    private let minNumberOfDigits = 3
    private let minVerticalThickness: CGFloat = 32.0
    private let minHorizontalThickness: CGFloat = 20.0
    
    private static let fontSizeFactor: CGFloat = 0.9
    private static let lineNumberFont: CGFont = LineNumberFont.regular.cgFont
    private static let boldLineNumberFont: CGFont = LineNumberFont.bold.cgFont
    
    private enum ColorStrength: CGFloat {
        case normal = 0.75
        case bold = 0.9
        case stroke = 0.2
    }
    
    
    // MARK: Private Properties
    
    private lazy var numberOfLines = max(self.textView?.numberOfLines ?? 0, 1)
    private var drawingInfo: DrawingInfo?
    
    private weak var draggingTimer: Timer?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation) {
        
        super.init(scrollView: scrollView, orientation: orientation)
        
        guard let textView = scrollView?.documentView as? NSTextView else { assertionFailure(); return }
        
        self.clientView = textView
        
        // observe new textStorage change
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: NSText.didChangeNotification, object: textView)
    }
    
    
    required init(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Ruler View Methods
    
    /// remove extra thickness
    override var requiredThickness: CGFloat {
        
        return self.ruleThickness
    }
    
    
    /// make background transparent
    override var isOpaque: Bool {
        
        return self.textView?.isOpaque ?? true
    }
    
    
    /// observe window opacity change
    override func viewDidMoveToWindow() {
        
        super.viewDidMoveToWindow()
        
        guard let window = self.window else { return }
        
        NotificationCenter.default.addObserver(self, selector: #selector(didWindowOpacityChange),
                                               name: DocumentWindow.didChangeOpacityNotification,
                                               object: window)
    }
    
    
    /// prepare line number drawing
    override func viewWillDraw() {
        
        super.viewWillDraw()
        
        guard
            let textFont = self.textView?.font,
            let scale = self.textView?.scale
            else { return }
        
        let drawingInfo: DrawingInfo
        if let lastDrawingInfo = self.drawingInfo, lastDrawingInfo.isSameSource(textFont: textFont, scale: scale) {
            drawingInfo = lastDrawingInfo
        } else {
            // -> update drawing info only when needed
            drawingInfo = DrawingInfo(textFont: textFont, scale: scale)
            self.drawingInfo = drawingInfo
        }
        
        // adjust thickness if needed
        let ruleThickness: CGFloat = {
            switch self.orientation {
            case .verticalRuler:
                let requiredNumberOfDigits = max(self.numberOfLines.numberOfDigits, self.minNumberOfDigits)
                let thickness = CGFloat(requiredNumberOfDigits) * drawingInfo.charWidth + 2.5 * drawingInfo.padding
                return max(thickness, self.minVerticalThickness)
            case .horizontalRuler:
                let thickness = drawingInfo.fontSize + 2.5 * drawingInfo.tickLength
                return max(thickness, self.minHorizontalThickness)
            }
        }()
        if ceil(ruleThickness) != self.ruleThickness {
            self.ruleThickness = ceil(ruleThickness)
        }
    }
    
    
    /// draw background
    override func draw(_ dirtyRect: NSRect) {
        
        NSGraphicsContext.saveGraphicsState()
        
        // fill background
        self.backgroundColor.setFill()
        dirtyRect.fill()
        
        // draw frame border (1px)
        self.textColor(.stroke).setStroke()
        switch self.orientation {
        case .verticalRuler:
            NSBezierPath.strokeLine(from: NSPoint(x: self.frame.maxX - 0.5, y: dirtyRect.maxY),
                                    to: NSPoint(x: self.frame.maxX - 0.5, y: dirtyRect.minY))
        case .horizontalRuler:
            NSBezierPath.strokeLine(from: NSPoint(x: dirtyRect.minX, y: self.frame.maxY - 0.5),
                                    to: NSPoint(x: dirtyRect.maxX, y: self.frame.maxY - 0.5))
        }
        
        NSGraphicsContext.restoreGraphicsState()
        
        self.drawHashMarksAndLabels(in: dirtyRect)
    }
    
    
    /// draw line numbers
    override func drawHashMarksAndLabels(in rect: NSRect) {
        
        guard
            let drawingInfo = self.drawingInfo,
            let textView = self.textView,
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer,
            let context = NSGraphicsContext.current?.cgContext
            else { return }
        
        let string = textView.string
        let lastCharIndex = (string as NSString).length
        let selectedLineRanges = textView.selectedRanges.map { (string as NSString).lineRange(for: $0.rangeValue) }
        let isVerticalText = self.orientation == .horizontalRuler
        let scale = textView.scale
        
        context.saveGState()
        
        context.setFont(LineNumberView.lineNumberFont)
        context.setFontSize(drawingInfo.fontSize)
        context.setFillColor(self.textColor().cgColor)
        
        // adjust text drawing coordinate
        context.textMatrix = {
            let relativePoint = self.convert(NSPoint.zero, from: textView)
            let inset = textView.textContainerOrigin.scaled(to: scale)
            let flip = CGAffineTransform(scaleX: 1.0, y: -1.0)
            
            return isVerticalText
                ? flip.translatedBy(x: round(relativePoint.x - inset.y - drawingInfo.ascent), y: -self.ruleThickness)
                : flip.translatedBy(x: self.ruleThickness, y: -relativePoint.y - inset.y - drawingInfo.ascent)
        }()
        
        /// draw line number block
        func drawLineNumber(_ lineNumber: Int, y: CGFloat, isBold: Bool) {
            
            let digit = lineNumber.numberOfDigits
            
            // calculate base position
            let basePosition: CGPoint = isVerticalText
                ? CGPoint(x: ceil(y + drawingInfo.charWidth * CGFloat(digit) / 2), y: 2 * drawingInfo.tickLength)
                : CGPoint(x: -drawingInfo.padding, y: y)
            
            // get glyphs and positions
            let positions: [CGPoint] = (0..<digit)
                .map { basePosition.offsetBy(dx: -CGFloat($0 + 1) * drawingInfo.charWidth) }
            let glyphs: [CGGlyph] = (0..<digit)
                .map { lineNumber.number(at: $0) }
                .map { drawingInfo.digitGlyphs[$0] }
            
            if isBold {
                context.setFillColor(self.textColor(.bold).cgColor)
                context.setFont(LineNumberView.boldLineNumberFont)
            }
            
            // draw
            context.showGlyphs(glyphs, at: positions)
            
            if isBold {
                // restore the regular font
                context.setFillColor(self.textColor().cgColor)
                context.setFont(LineNumberView.lineNumberFont)
            }
        }
        
        /// draw wrapped mark (-)
        func drawWrappedMark(y: CGFloat) {
            
            let position = CGPoint(x: -drawingInfo.padding - drawingInfo.charWidth, y: y)
            
            context.showGlyphs([drawingInfo.wrappedMarkGlyph], at: [position])
        }
        
        /// draw ticks block for vertical text
        func drawTick(y: CGFloat) {
            
            let rect = CGRect(x: round(y), y: 1, width: 1, height: drawingInfo.tickLength)
            let tick = CGPath(rect: rect, transform: &context.textMatrix)
            
            context.addPath(tick)
        }
        
        // get glyph range of which line number should be drawn
        let visibleRect = textView.visibleRect.offset(by: -textView.textContainerOrigin)
        let glyphRangeToDraw = layoutManager.glyphRange(forBoundingRectWithoutAdditionalLayout: visibleRect, in: textContainer)
        
        // count up lines until visible
        let firstVisibleIndex = layoutManager.characterIndexForGlyph(at: glyphRangeToDraw.location)
        var lineNumber = string.lineNumber(at: firstVisibleIndex)
        
        // draw visible line numbers
        var glyphIndex = glyphRangeToDraw.location
        while glyphIndex < glyphRangeToDraw.upperBound {  // count "real" lines
            let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let lineRange = string.lineRange(at: characterIndex)
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let isSelected = selectedLineRanges.contains { lineRange.intersection($0) != nil }
            glyphIndex = lineGlyphRange.upperBound
            
            var wrappedLineGlyphIndex = lineGlyphRange.location
            while wrappedLineGlyphIndex < glyphIndex {  // handle wrapped lines
                var range = NSRange.notFound
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: wrappedLineGlyphIndex, effectiveRange: &range, withoutAdditionalLayout: true)
                let y = scale * -lineRect.minY
                wrappedLineGlyphIndex = range.upperBound
                
                if range.location == lineGlyphRange.location {  // first line
                    if isVerticalText {
                        drawTick(y: y)
                    }
                    if !isVerticalText || lineNumber % 5 == 0 || lineNumber == 1 || isSelected ||
                        (lineRange.upperBound == lastCharIndex && layoutManager.extraLineFragmentTextContainer == nil)  // last line for vertical text
                    {
                        drawLineNumber(lineNumber, y: y, isBold: isSelected)
                    }
                    
                } else {  // wrapped line
                    guard !isVerticalText else { break }
                    
                    drawWrappedMark(y: y)
                }
            }
            lineNumber += 1
        }
        
        // draw the last "extra" line number
        let extraLineRect = layoutManager.extraLineFragmentUsedRect
        if !extraLineRect.isEmpty, extraLineRect.intersects(textView.visibleRect) {
            let isSelected = (selectedLineRanges.last?.location == lastCharIndex)
            let y = scale * -extraLineRect.minY
            
            if isVerticalText {
                drawTick(y: y)
            }
            drawLineNumber(self.numberOfLines, y: y, isBold: isSelected)
        }
        
        // draw vertical line ticks
        if !context.isPathEmpty {
            context.setFillColor(self.textColor(.stroke).cgColor)
            context.fillPath()
        }
        
        context.restoreGState()
    }
    
    
    
    // MARK: Private Methods
    
    /// return client view casting to textView
    private var textView: NSTextView? {
        
        return self.clientView as? NSTextView
    }
    
    
    /// return text color considering current accesibility setting
    private func textColor(_ strength: ColorStrength = .normal) -> NSColor {
        
        let textColor = self.textView?.textColor ?? .textColor
        
        if NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast, strength != .stroke {
            return textColor
        }
        
        return self.backgroundColor.blended(withFraction: strength.rawValue, of: textColor) ?? textColor
    }
    
    
    /// return coloring theme
    private var backgroundColor: NSColor {
        
        let isDarkBackground = (self.textView as? Themable)?.theme?.isDarkTheme ?? false
        
        if self.isOpaque, let color = self.textView?.backgroundColor {
            return (isDarkBackground ? color.highlight(withLevel: 0.08) : color.shadow(withLevel: 0.06)) ?? color
        } else {
            return isDarkBackground ? NSColor.white.withAlphaComponent(0.08) : NSColor.black.withAlphaComponent(0.06)
        }
    }
    
    
    /// update total number of lines determining view thickness on holizontal text layout
    @objc private func textDidChange(_ notification: Notification) {
        
        // -> count only if really needed since the line counting is high workload, especially by large document
        self.numberOfLines = max(self.textView?.numberOfLines ?? 0, 1)
    }
    
    
    /// window's opacity did change
    @objc private func didWindowOpacityChange(_ notification: Notification?) {
        
        // redraw visible area
        self.setNeedsDisplay(self.visibleRect)
    }
    
}



// MARK: Line Number Font

private enum LineNumberFont {
    
    case regular
    case bold
    
    
    
    var font: NSFont {
        
        return NSFont(name: self.fontName, size: 0) ?? self.systemFont
    }
    
    
    var cgFont: CGFont {
        
        return CTFontCopyGraphicsFont(self.font, nil)
    }
    
    
    /// name of the first candidate font
    private var fontName: String {
        
        switch self {
        case .regular:
            return "AvenirNextCondensed-Regular"
        case .bold:
            return "AvenirNextCondensed-DemiBold"
        }
    }
    
    
    /// system font for fallback
    private var systemFont: NSFont {
        
        return .monospacedDigitSystemFont(ofSize: 0, weight: self.weight)
    }
    
    
    /// font weight for system fonts
    private var weight: NSFont.Weight {
        
        switch self {
        case .regular:
            return .regular
        case .bold:
            return .semibold
        }
    }
    
}



// MARK: Private Helper Extensions

private extension NSTextView {
    
    var numberOfLines: Int {
        
        return self.string.numberOfLines(includingLastLineEnding: true)
    }
    
}


private extension Int {
    
    /// number of digits
    var numberOfDigits: Int {
        
        guard self > 0 else { return 1 }
        
        return Int(log10(Double(self))) + 1
    }
    
    
    /// number at the desired place
    func number(at place: Int) -> Int {
        
        return ((self % Int(pow(10, Double(place + 1)))) / Int(pow(10, Double(place))))
    }
    
}


private extension FloatingPoint {
    
    func round(interval: Self) -> Self {
        
        return (self / interval).rounded() * interval
    }
}


private extension CTFont {
    
    func advance(for glyph: CGGlyph, orientation: CTFontOrientation = .horizontal) -> CGSize {
        
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(self, orientation, [glyph], &advance, 1)  // use '8' to get width
        return advance
    }
    
    
    func glyph(for uniChar: UniChar) -> CGGlyph {
        
        var glyph = CGGlyph()
        CTFontGetGlyphsForCharacters(self, [uniChar], &glyph, 1)
        return glyph
    }
    
}



// MARK: - Line Selecting

private struct DraggingInfo {
    
    let index: Int
    let selectedRanges: [NSRange]
}


extension LineNumberView {
    
    // MARK: View Methods
    
    /// start selecting correspondent lines in text view with drag / click event
    override func mouseDown(with event: NSEvent) {
        
        guard
            let window = self.window,
            let textView = self.textView
            else { return }
        
        // get start point
        let point = window.convertToScreen(NSRect(origin: event.locationInWindow, size: .zero)).origin
        let index = textView.characterIndex(for: point)
        
        // repeat while dragging
        self.draggingTimer = .scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(selectLines),
                                             userInfo: DraggingInfo(index: index, selectedRanges: textView.selectedRanges as! [NSRange]),
                                             repeats: true)
        
        self.selectLines(nil)  // for single click event
    }
    
    
    /// end selecting correspondent lines in text view with drag event
    override func mouseUp(with event: NSEvent) {
        
        self.draggingTimer?.invalidate()
        
        // settle selection
        //   -> in `selectLines:`, `stillSelecting` flag is always YES
        if let ranges = self.textView?.selectedRanges {
            self.textView?.selectedRanges = ranges
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// select lines while dragging event
    @objc private func selectLines(_ timer: Timer?) {
        
        guard
            let window = self.window,
            let textView = self.textView
            else { return }
        
        let string = textView.string as NSString
        let draggingInfo = timer?.userInfo as? DraggingInfo
        let point = NSEvent.mouseLocation  // screen based point
        
        // scroll text view if needed
        let pointedRect = window.convertFromScreen(NSRect(origin: point, size: .zero))
        let targetRect = textView.convert(pointedRect, from: nil)
        textView.scrollToVisible(targetRect)
        
        // select lines
        let currentIndex = textView.characterIndex(for: point)
        let clickedIndex = draggingInfo?.index ?? currentIndex
        let currentLineRange = string.lineRange(at: currentIndex)
        let clickedLineRange = string.lineRange(at: clickedIndex)
        var range = currentLineRange.union(clickedLineRange)
        
        let affinity: NSSelectionAffinity = (currentIndex < clickedIndex) ? .upstream : .downstream
        
        // with Command key (add selection)
        if NSEvent.modifierFlags.contains(.command) {
            let originalSelectedRanges = draggingInfo?.selectedRanges ?? textView.selectedRanges as! [NSRange]
            var selectedRanges = [NSRange]()
            var intersects = false
            
            for selectedRange in originalSelectedRanges {
                if selectedRange.location <= range.location, range.upperBound <= selectedRange.upperBound {  // exclude
                    let range1 = NSRange(selectedRange.location..<range.location)
                    let range2 = NSRange(range.upperBound..<selectedRange.upperBound)
                    
                    if range1.length > 0 {
                        selectedRanges.append(range1)
                    }
                    if range2.length > 0 {
                        selectedRanges.append(range2)
                    }
                    
                    intersects = true
                    continue
                }
                
                // add
                selectedRanges.append(selectedRange)
            }
            
            if !intersects {  // add current dragging selection
                selectedRanges.append(range)
            }
            
            textView.setSelectedRanges(selectedRanges as [NSValue], affinity: affinity, stillSelecting: false)
            
            return
        }
        
        // with Shift key (expand selection)
        if NSEvent.modifierFlags.contains(.shift) {
            let selectedRange = textView.selectedRange
            if selectedRange.contains(currentIndex) {  // reduce
                let inUpperSelection = (currentIndex - selectedRange.location) < selectedRange.length / 2
                if inUpperSelection {  // clicked upper half section of selected range
                    range = NSRange(currentIndex..<selectedRange.upperBound)
                } else {
                    range = selectedRange
                    range.length -= selectedRange.upperBound - currentLineRange.upperBound
                }
            } else {  // expand
                range.formUnion(selectedRange)
            }
        }
        
        textView.setSelectedRange(range, affinity: affinity, stillSelecting: false)
    }
    
}
