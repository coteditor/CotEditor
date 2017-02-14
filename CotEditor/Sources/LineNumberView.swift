/*
 
 LineNumberView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-03-30.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa
import CoreText

final class LineNumberView: NSRulerView {
    
    // MARK: Constants
    
    private let MinNumberOfDigits = 3
    private let MinVerticalThickness: CGFloat = 32.0
    private let MinHorizontalThickness: CGFloat = 20.0
    private let LineNumberPadding: CGFloat = 4.0
    private let FontSizeFactor: CGFloat = 0.9
    
    private let lineNumberFont: CGFont = LineNumberFont.regular.cgFont
    private let boldLineNumberFont: CGFont = LineNumberFont.bold.cgFont
    
    
    // MARK: Private Properties
    
    private var totalNumberOfLines = 0
    private var needsRecountTotalNumberOfLines = true
    
    fileprivate weak var draggingTimer: Timer?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init(scrollView: NSScrollView?, orientation: NSRulerOrientation) {
        
        super.init(scrollView: scrollView, orientation: orientation)
        
        self.clientView = scrollView?.documentView
    }
    
    
    required init(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: Ruler View Methods
    
    /// draw background
    override func draw(_ dirtyRect: NSRect) {
        
        NSGraphicsContext.saveGraphicsState()
        
        // fill background
        self.backgroundColor.withAlphaComponent(0.08).setFill()
        NSBezierPath.fill(dirtyRect)
        
        // draw frame border (1px)
        let textColor = self.textColor
        let borderAlpha = 0.3 * textColor.alphaComponent
        textColor.withAlphaComponent(borderAlpha).setStroke()
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
            let textView = self.textView,
            let string = textView.string,
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer,
            let context = NSGraphicsContext.current()?.cgContext,
            !string.isEmpty else { return }
        
        let length = (string as NSString).length
        let scale = textView.scale
        
        // save graphics context
        context.saveGState()
        
        // setup font
        let masterFont = textView.font ?? NSFont.systemFont(ofSize: 0)
        let masterFontSize = scale * masterFont.pointSize
        let masterAscent = scale * masterFont.ascender
        let fontSize = min(round(self.FontSizeFactor * masterFontSize), masterFontSize)
        let font = CTFontCreateWithGraphicsFont(self.lineNumberFont, fontSize, nil, nil)
        
        context.setFont(self.lineNumberFont)
        context.setFontSize(fontSize)
        context.setFillColor(self.textColor.cgColor)
        
        // prepare glyphs
        var wrappedMarkGlyph = CGGlyph()
        let dash: UniChar = "-".utf16.first!
        CTFontGetGlyphsForCharacters(font, [dash], &wrappedMarkGlyph, 1)
        
        var digitGlyphs = [CGGlyph](repeating: 0, count: 10)
        let numbers: [UniChar] = (0...9).map { String($0).utf16.first! }
        CTFontGetGlyphsForCharacters(font, numbers, &digitGlyphs, 10)
        
        // calc character width as monospaced font
        let charWidth: CGFloat = {
            var advance = CGSize.zero
            CTFontGetAdvancesForGlyphs(font, .horizontal, &digitGlyphs[8], &advance, 1)  // use '8' to get width
            return advance.width
        }()
        
        // prepare frame width
        let lineNumberPadding = round(scale * self.LineNumberPadding)
        let isVerticalText = self.orientation == .horizontalRuler
        let tickLength = ceil(fontSize / 3)
        
        // adjust thickness
        var ruleThickness: CGFloat
        if isVerticalText {
            ruleThickness = max(fontSize + 2.5 * tickLength, self.MinHorizontalThickness)
        } else {
            if self.needsRecountTotalNumberOfLines {
                // -> count only if really needed since the line counting is high workload, especially by large document
                self.totalNumberOfLines = string.numberOfLines(in: string.range, includingLastLineEnding: true)
                self.needsRecountTotalNumberOfLines = false
            }
            
            // use the line number of whole string, namely the possible largest line number
            // -> The view width depends on the number of digits of the total line numbers.
            //    It's quite dengerous to change width of line number view on scrolling dynamically.
            let digits = max(self.totalNumberOfLines.numberOfDigits, self.MinNumberOfDigits)
            ruleThickness = max(CGFloat(digits) * charWidth + 3 * lineNumberPadding, self.MinVerticalThickness)
        }
        ruleThickness = ceil(ruleThickness)
        if ruleThickness != self.ruleThickness {
            self.ruleThickness = ruleThickness
        }
        
        // adjust text drawing coordinate
        let relativePoint = self.convert(NSPoint.zero, from: textView)
        let inset = textView.textContainerOrigin.scaled(to: scale)
        var transform = CGAffineTransform(scaleX: 1.0, y: -1.0)  // flip
        if isVerticalText {
            transform = transform.translatedBy(x: round(relativePoint.x - inset.y - masterAscent), y: -ruleThickness)
        } else {
            transform = transform.translatedBy(x: -lineNumberPadding, y: -relativePoint.y - inset.y - masterAscent)
        }
        context.textMatrix = transform
        
        // get multiple selections
        let selectedLineRanges: [NSRange] = textView.selectedRanges.map { (string as NSString).lineRange(for: $0.rangeValue) }
        
        /// draw line number block
        func drawLineNumber(_ lineNumber: Int, y: CGFloat, isBold: Bool) {
            
            let digit = lineNumber.numberOfDigits
            
            // calculate base position
            var position: CGPoint = {
                if isVerticalText {
                    return CGPoint(x: ceil(y + charWidth * CGFloat(digit) / 2), y: 2 * tickLength)
                } else {
                    return CGPoint(x: ruleThickness, y: y)
                }
            }()
            
            // get glyphs and positions
            var glyphs = [CGGlyph]()
            var positions = [CGPoint]()
            for index in 0..<digit {
                let num = lineNumber.number(at: index)
                position.x -= charWidth
                
                positions.append(position)
                glyphs.append(digitGlyphs[num])
            }
            
            if isBold {
                context.setFont(self.boldLineNumberFont)
            }
            
            // draw
            context.showGlyphs(glyphs, at: positions)
            
            if isBold {
                // back to the regular font
                context.setFont(self.lineNumberFont)
            }
        }
        
        /// draw wrapped mark (-)
        func drawWrappedMark(y: CGFloat) {
            
            let position = CGPoint(x: ruleThickness - charWidth, y: y)
            
            context.showGlyphs([wrappedMarkGlyph], at: [position])
        }
        
        /// draw ticks block for vertical text
        func drawTick(y: CGFloat) {
            
            let x = round(y) + 0.5
            
            let tick = CGMutablePath()
            tick.move(to: CGPoint(x: x, y: 1), transform: transform)
            tick.addLine(to: CGPoint(x: x, y: tickLength), transform: transform)
            context.addPath(tick)
        }
        
        // get glyph range of which line number should be drawn
        let visibleRect = self.scrollView?.documentVisibleRect ?? textView.frame
        let glyphRangeToDraw = layoutManager.glyphRange(forBoundingRectWithoutAdditionalLayout: visibleRect, in: textContainer)
        
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
            let lineRange = string.lineRange(at: charIndex)  // get NSRange
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            glyphIndex = lineGlyphRange.max
            
            // check if line is selected
            let isSelected = selectedLineRanges.contains { selectedRange in
                return (selectedRange.contains(location: lineRange.location) &&
                    (!isVerticalText || (lineRange.location == selectedRange.location || lineRange.max == selectedRange.max)))
            }
            
            while (glyphCount < glyphIndex) {  // handle wrapper lines
                var range = NSRange.notFound
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphCount, effectiveRange: &range, withoutAdditionalLayout: true)
                let isWrappedLine = (lastLineNumber == lineNumber)
                lastLineNumber = lineNumber
                glyphCount = range.max
                
                if isVerticalText && isWrappedLine { continue }
                
                let y = scale * -lineRect.minY
                
                if isWrappedLine {
                    drawWrappedMark(y: y)
                    
                } else {  // new line
                    if isVerticalText {
                        drawTick(y: y)
                    }
                    if !isVerticalText || lineNumber % 5 == 0 || lineNumber == 1 || isSelected ||
                        lineRange.max == length && layoutManager.extraLineFragmentTextContainer == nil  // last line for vertical text
                    {
                        drawLineNumber(lineNumber, y: y, isBold: isSelected)
                    }
                }
            }
        }
        
        // draw the last "extra" line number
        if layoutManager.extraLineFragmentTextContainer != nil {
            let lineRect = layoutManager.extraLineFragmentUsedRect
            let isSelected: Bool = {
                if let lastSelectedRange = selectedLineRanges.last {
                    return (lastSelectedRange.length == 0) && (length == lastSelectedRange.max)
                }
                return false
            }()
            let y = scale * -lineRect.minY
            
            if isVerticalText {
                drawTick(y: y)
            }
            drawLineNumber(lineNumber, y: y, isBold: isSelected)
        }
        
        // draw vertical text tics
        if isVerticalText {
            context.setStrokeColor(textColor.withAlphaComponent(0.3).cgColor)
            context.strokePath()
        }
        
        context.restoreGState()
    }
    
    
    /// make background transparent
    override var isOpaque: Bool {
        
        return false
    }
    
    
    /// remove extra thickness
    override var requiredThickness: CGFloat {
        
        if self.orientation == .horizontalRuler {
            return self.ruleThickness
        }
        return max(self.MinVerticalThickness, self.ruleThickness)
    }
    
    
    /// setter of client view
    override var clientView: NSView? {
        
        willSet {
            // stop observing current textStorage
            if let textView = self.clientView as? NSTextView {
                NotificationCenter.default.removeObserver(self, name: .NSTextDidChange, object: textView)
            }
        }
        
        didSet {
            // observe new textStorage change
            if let textView = self.clientView as? NSTextView {
                NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: .NSTextDidChange, object: textView)
                self.needsRecountTotalNumberOfLines = true
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// return client view casting to textView
    fileprivate var textView: NSTextView? {
        
        return self.clientView as? NSTextView
    }
    
    
    /// return text color considering current accesibility setting
    private var textColor: NSColor {
        
        guard let textColor = self.textView?.textColor else {
            return .textColor
        }
        if NSWorkspace.shared().accessibilityDisplayShouldIncreaseContrast {
            return textColor
        }
        return textColor.withAlphaComponent(0.67)
    }
    
    
    /// return coloring theme
    private var backgroundColor: NSColor {
        
        let isDarkBackground = (self.textView as? Themable)?.theme?.isDarkTheme ?? false
        
        return isDarkBackground ? .white : .black
    }
    
    
    /// update total number of lines determining view thickness on holizontal text layout
    @objc private func textDidChange(_ notification: Notification) {
        
        self.needsRecountTotalNumberOfLines = true
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
            return "AvenirNextCondensed-Bold"
        }
    }
    
    
    /// system font for fallback
    private var systemFont: NSFont {
        
        if #available(macOS 10.11, *) {
            return .monospacedDigitSystemFont(ofSize: 0, weight: self.weight)
        } else {
            return .paletteFont(ofSize: 0)
        }
    }
    
    
    /// font weight for system font
    @available(macOS 10.11, *)
    private var weight: CGFloat {
        
        switch self {
        case .regular:
            return NSFontWeightRegular
        case .bold:
            return NSFontWeightBold
        }
    }
    
}



// MARK: Private Int helpers

private extension Int {
    
    /// number of digits
    var numberOfDigits: Int {
        
        return Int(log10(Double(self))) + 1
    }
    
    
    /// number at the desired place
    func number(at place: Int) -> Int {
        
        return ((self % Int(pow(10, Double(place + 1)))) / Int(pow(10, Double(place))))
    }
    
}



// MARK:
// MARK: Line Selecting

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
        let point = window.convertToScreen(NSRect(origin: event.locationInWindow, size: NSSize.zero)).origin
        let index = textView.characterIndex(for: point)
        
        // repeat while dragging
        self.draggingTimer = .scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(selectLines),
                                             userInfo: DraggingInfo(index: index, selectedRanges: textView.selectedRanges as [NSRange]),
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
            let textView = self.textView,
            let string = textView.string as NSString?
            else { return }
        
        let draggingInfo = timer?.userInfo as? DraggingInfo
        let point = NSEvent.mouseLocation()  // screen based point
        
        // scroll text view if needed
        let pointedRect = window.convertFromScreen(NSRect(origin: point, size: NSSize.zero))
        let targetRect = textView.convert(pointedRect, to: nil)
        textView.scrollToVisible(targetRect)
        
        // select lines
        let currentIndex = textView.characterIndex(for: point)
        let clickedIndex = draggingInfo?.index ?? currentIndex
        let currentLineRange = string.lineRange(at: currentIndex)
        let clickedLineRange = string.lineRange(at: clickedIndex)
        var range = currentLineRange.union(clickedLineRange)
        
        let affinity: NSSelectionAffinity = (currentIndex < clickedIndex) ? .upstream : .downstream
        
        // with Command key (add selection)
        if NSEvent.modifierFlags().contains(.command) {
            let originalSelectedRanges = draggingInfo?.selectedRanges ?? textView.selectedRanges as [NSRange]
            var selectedRanges = [NSRange]()
            var intersects = false
            
            for selectedRange in originalSelectedRanges {
                if selectedRange.location <= range.location && range.max <= selectedRange.max {  // exclude
                    let range1 = NSRange(location: selectedRange.location, length: range.location - selectedRange.location)
                    let range2 = NSRange(location: range.max, length: selectedRange.max - range.max)
                    
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
        if NSEvent.modifierFlags().contains(.shift) {
            let selectedRange = textView.selectedRange
            if selectedRange.contains(location: currentIndex) {  // reduce
                let inUpperSelection = (currentIndex - selectedRange.location) < selectedRange.length / 2
                if inUpperSelection {  // clicked upper half section of selected range
                    range = NSRange(location: currentIndex, length: selectedRange.max - currentIndex)
                } else {
                    range = selectedRange
                    range.length -= selectedRange.max - currentLineRange.max
                }
            } else {  // expand
                range.formUnion(selectedRange)
            }
        }
        
        textView.setSelectedRange(range, affinity: affinity, stillSelecting: false)
    }
    
}
