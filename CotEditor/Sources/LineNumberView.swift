/*
 
 LineNumberView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-03-30.
 
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
import CoreText

class LineNumberView: NSRulerView {
    
    // MARK: Constants
    
    private let MinNumberOfDigits = 3
    private let MinVerticalThickness: CGFloat = 32.0
    private let MinHorizontalThickness: CGFloat = 20.0
    private let LineNumberPadding: CGFloat = 4.0
    private let FontSizeFactor: CGFloat = 0.9
    
    private let LineNumberFont = CGFont("AvenirNextCondensed-Regular") ?? CGFont(NSFont.paletteFont(ofSize: 0).fontName)!
    private let BoldLineNumberFont = CGFont("AvenirNextCondensed-Bold") ?? CGFont(NSFont.paletteFont(ofSize: 0).fontName)!
    
    
    // MARK: Private Properties
    
    private var totalNumberOfLines = 0
    private var needsRecountTotalNumberOfLines = true
    private var draggingTimer: Timer?
    
    
    
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
        
        self.drawHashMarksAndLabels(in: dirtyRect)
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    /// draw line numbers
    override func drawHashMarksAndLabels(in rect: NSRect) {
        
        guard let textView = self.textView, let string = textView.string as NSString?, string.length > 0 else { return }
        
        let length = string.length
        let textColor = self.textColor
        let layoutManager = textView.layoutManager!
        let scale = textView.convert(NSMakeSize(1.0, 1.0), to: nil).width
        
        // set graphics context
        let context = NSGraphicsContext.current()!.cgContext
        context.saveGState()
        
        // setup font
        let masterFontSize = scale * (textView.font?.pointSize ?? NSFont.systemFontSize())
        let fontSize = min(round(self.FontSizeFactor * masterFontSize), masterFontSize)
        let font = CTFontCreateWithGraphicsFont(self.LineNumberFont, fontSize, nil, nil)
        let ascent = CTFontGetAscent(font)
        
        context.setFont(self.LineNumberFont)
        context.setFontSize(fontSize)
        context.setFillColor(textColor.cgColor)
        
        // prepare glyphs
        var dash: UniChar = "-".character(at: 0)
        var wrappedMarkGlyph = CGGlyph()
        CTFontGetGlyphsForCharacters(font, &dash, &wrappedMarkGlyph, 1)
        
        var digitGlyphs = [CGGlyph](repeating: 0, count: 10)
        let numbers: [UniChar] = (0...9).map { String($0).utf16.first! }
        CTFontGetGlyphsForCharacters(font, numbers, &digitGlyphs, 10)
        
        // calc character width as monospaced font
        var advance = CGSize()
        CTFontGetAdvancesForGlyphs(font, .horizontal, &digitGlyphs[8], &advance, 1)  // use '8' to get width
        let charWidth = advance.width
        
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
                self.totalNumberOfLines = (string as String).numberOfLines(in: string.range, includingLastLineEnding: true)
                self.needsRecountTotalNumberOfLines = false
            }
            
            // use the line number of whole string, namely the possible largest line number
            // -> The view width depends on the number of digits of the total line numbers.
            //    It's quite dengerous to change width of line number view on scrolling dynamically.
            let digits = max(numberOfDigits(in: self.totalNumberOfLines), self.MinNumberOfDigits)
            ruleThickness = max(CGFloat(digits) * charWidth + 3 * lineNumberPadding, self.MinVerticalThickness)
        }
        ruleThickness = ceil(ruleThickness)
        if ruleThickness != self.ruleThickness {
            self.ruleThickness = ruleThickness
        }
        
        // adjust text drawing coordinate
        let relativePoint = self.convert(NSPoint(), from: textView)
        let inset = textView.textContainerOrigin
        var transform = CGAffineTransform(scaleX: 1.0, y: -1.0)  // flip
        if isVerticalText {
            transform = transform.translateBy(x: round(relativePoint.x - scale * inset.y - ascent), y: -ruleThickness)
        } else {
            transform = transform.translateBy(x: -lineNumberPadding, y: -relativePoint.y - scale * inset.y - ascent)
        }
        context.textMatrix = transform
        
        // get multiple selections
        var selectedLineRanges = [NSRange]()
        for rangeValue in textView.selectedRanges {
            let selectedLineRange = string.lineRange(for: rangeValue.rangeValue)
            selectedLineRanges.append(selectedLineRange)
        }
        
        /// draw line number block
        func drawLineNumber(_ lineNumber: Int, y: CGFloat, isBold: Bool) {
            
            let digit = numberOfDigits(in: lineNumber)
            
            // calculate base position
            var position: CGPoint
            if isVerticalText {
                position = CGPoint(x: ceil(y + charWidth * CGFloat(digit) / 2), y: 2 * tickLength)
            } else {
                position = CGPoint(x: ruleThickness, y: y)
            }
            
            // get glyphs and positions
            var glyphs = [CGGlyph]()
            var positions = [CGPoint]()
            for index in 0..<digit {
                let num = number(at: index, number: lineNumber)
                position.x -= charWidth
                
                positions.append(position)
                glyphs.append(digitGlyphs[num])
            }
            
            if isBold {
                context.setFont(self.BoldLineNumberFont)
            }
            
            // draw
            context.showGlyphs(glyphs, atPositions: positions, count: digit)
            
            if isBold {
                // back to the regular font
                context.setFont(self.LineNumberFont)
            }
        }
        
        /// draw ticks block for vertical text
        func drawTick(y: CGFloat) {
            
            let x = round(y) + 0.5
            
            let tick = CGMutablePath()
            tick.moveTo(&transform, x: x, y: 0)
            tick.addLineTo(&transform, x: x, y: tickLength)
            context.addPath(tick)
        }
        
        // get glyph range of which line number should be drawn
        let glyphRangeToDraw = layoutManager.glyphRange(forBoundingRectWithoutAdditionalLayout: self.scrollView!.documentVisibleRect, in: textView.textContainer!)
        
        // count up lines until visible
        let undisplayedRange = NSRange(location: 0, length: layoutManager.characterIndexForGlyph(at: glyphRangeToDraw.location))
        var lineNumber = max((string as String).numberOfLines(in: undisplayedRange, includingLastLineEnding: true), 1)  // start with 1
        
        // draw visible line numbers
        var glyphCount = glyphRangeToDraw.location
        var glyphIndex = glyphRangeToDraw.location
        var lastLineNumber = 0
        
        while glyphIndex < glyphRangeToDraw.max {  // count "real" lines
            defer {
                lineNumber += 1
            }
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let lineRange = string.lineRange(for: NSMakeRange(charIndex, 0))  // get NSRange
            let lineCharacterRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            glyphIndex = lineCharacterRange.max
            
            // check if line is selected
            var isSelected = false
            for selectedRange in selectedLineRanges {
                if NSLocationInRange(lineRange.location, selectedRange) &&
                    (!isVerticalText || (lineRange.location == selectedRange.location || lineRange.max == selectedRange.max)) {
                    isSelected = true
                    break
                }
            }
            
            while (glyphCount < glyphIndex) {  // handle wrapper lines
                var range = NotFoundRange
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphCount, effectiveRange: &range, withoutAdditionalLayout: true)
                let isWrappedLine = (lastLineNumber == lineNumber)
                lastLineNumber = lineNumber
                glyphCount = range.max
                
                if isVerticalText && isWrappedLine { continue }
                
                let y = scale * -lineRect.minY
                
                if isWrappedLine {
                    var position = CGPoint(x: ruleThickness - charWidth, y: y)
                    context.showGlyphs(&wrappedMarkGlyph, atPositions: &position, count: 1)  // draw wrapped mark
                    
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
                } else {
                    return false
                }
            }()
            let y = scale * -lineRect.minY
            
            if isVerticalText {
                drawTick(y: y)
            }
            drawLineNumber(lineNumber, y: y, isBold: isSelected)
        }
        
        // draw vertical text tics
        if isVerticalText {
            context.setStrokeColor(textColor.withAlphaComponent(0.6).cgColor)
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
    private var textView: NSTextView? {
        
        return self.clientView as? NSTextView
    }
    
    
    /// return text color considering current accesibility setting
    private var textColor: NSColor {
        
        guard let textColor = self.textView?.textColor else {
            return .textColor()
        }
        if NSWorkspace.shared().accessibilityDisplayShouldIncreaseContrast {
            return textColor
        }
        return textColor.withAlphaComponent(0.67)
    }
    
    
    /// return coloring theme
    private var backgroundColor: NSColor {
        
        let isDarkBackground = (self.textView as? Themable)?.theme?.isDarkTheme ?? false
        
        return isDarkBackground ? .white() : .black()
    }
    
    
    /// update total number of lines determining view thickness on holizontal text layout
    func textDidChange(_ notification: Notification) {
        
        self.needsRecountTotalNumberOfLines = true
    }
    
}



// MARK: Private C Functions

/// digits of input number
private func numberOfDigits(in number: Int) -> Int {
    
    return Int(log10(Double(number))) + 1
}


/// number at the desired place of input number
private func number(at place: Int, number: Int) -> Int {
    
    return ((number % Int(pow(10, Double(place + 1)))) / Int(pow(10, Double(place))))
}



// MARK:
// MARK: Line Selecting

private class DraggingInfo {
    let index: Int
    let selectedRanges: [NSRange]
    
    init(index: Int, selectedRanges: [NSRange]) {
        self.index = index
        self.selectedRanges = selectedRanges
    }
}


extension LineNumberView {
    
    // MARK: View Methods
    
    /// start selecting correspondent lines in text view with drag / click event
    override func mouseDown(_ event: NSEvent) {
        
        guard let textView = self.textView else { return }
        
        // get start point
        let point = self.window!.convertToScreen(NSRect(origin: event.locationInWindow, size: NSSize())).origin
        let index = textView.characterIndex(for: point)
        
        // repeat while dragging
        self.draggingTimer = .scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(selectLines(_:)),
                                             userInfo: DraggingInfo(index: index,
                                                                    selectedRanges: textView.selectedRanges as! [NSRange]), repeats: true)
        
        self.selectLines(nil)  // for single click event
    }
    
    
    /// end selecting correspondent lines in text view with drag event
    override func mouseUp(_ event: NSEvent) {
        
        self.draggingTimer?.invalidate()
        
        // settle selection
        //   -> in `selectLines:`, `stillSelecting` flag is always YES
        if let ranges = self.textView?.selectedRanges {
            self.textView?.selectedRanges = ranges
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// select lines while dragging event
    func selectLines(_ timer: Timer?) {
        
        guard let textView = self.textView, let string: NSString = textView.string else { return }
        
        let draggingInfo = timer?.userInfo as? DraggingInfo
        let point = NSEvent.mouseLocation()  // screen based point
        
        // scroll text view if needed
        let pointedRect = self.window!.convertFromScreen(NSRect(origin: point, size: NSSize()))
        let targetRect = textView.convert(pointedRect, to: nil)
        textView.scrollToVisible(targetRect)
        
        // select lines
        let currentIndex = textView.characterIndex(for: point)
        let clickedIndex = draggingInfo?.index ?? currentIndex
        let currentLineRange = string.lineRange(for: NSRange(location: currentIndex, length: 0))
        let clickedLineRange = string.lineRange(for: NSRange(location: clickedIndex, length: 0))
        var range = NSUnionRange(currentLineRange, clickedLineRange)
        
        let affinity: NSSelectionAffinity = (currentIndex < clickedIndex) ? .upstream : .downstream
        
        // with Command key (add selection)
        if NSEvent.modifierFlags().contains(.command) {
            let originalSelectedRanges = draggingInfo?.selectedRanges ?? textView.selectedRanges as! [NSRange]
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
            
            textView.setSelectedRanges(selectedRanges, affinity: affinity, stillSelecting: false)
            
            return
        }
        
        // with Shift key (expand selection)
        if NSEvent.modifierFlags().contains(.shift) {
            let selectedRange = textView.selectedRange()
            if NSLocationInRange(currentIndex, selectedRange) {  // reduce
                let inUpperSelection = (currentIndex - selectedRange.location) < selectedRange.length / 2
                if inUpperSelection {  // clicked upper half section of selected range
                    range = NSRange(location: currentIndex, length: selectedRange.max - currentIndex)
                } else {
                    range = selectedRange
                    range.length -= selectedRange.max - currentLineRange.max
                }
            } else {  // expand
                range = NSUnionRange(range, selectedRange)
            }
        }
        
        textView.setSelectedRange(range, affinity: affinity, stillSelecting: false)
    }
    
}
