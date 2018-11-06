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
            self.wrappedMarkGlyph = font.glyph(for: "-")
            self.digitGlyphs = (0...9).map { font.glyph(for: Character(String($0))) }
            
            // calculate character width assuming the font is monospace
            self.charWidth = font.advance(for: self.digitGlyphs[8]).width  // use '8' to get width
            
            // calculate margins
            self.padding = self.charWidth
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
    private static let lineNumberFont: CGFont = NSFont.lineNumberFont().cgFont
    private static let boldLineNumberFont: CGFont = NSFont.lineNumberFont(weight: .semibold).cgFont
    
    private enum ColorStrength: CGFloat {
        case normal = 0.75
        case bold = 0.9
        case stroke = 0.2
    }
    
    
    // MARK: Private Properties
    
    private var numberOfLines = 1
    private var drawingInfo: DrawingInfo?
    private var textObserver: NSObjectProtocol?
    private var opacityObserver: NSObjectProtocol?
    
    private weak var draggingTimer: Timer?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation) {
        
        super.init(scrollView: scrollView, orientation: orientation)
        
        // set accessibility
        self.setAccessibilityLabel("line numbers".localized)
        
        guard let textView = scrollView?.documentView as? NSTextView else { assertionFailure(); return }
        
        self.clientView = textView
        
        // observe text change for the total number of lines determining ruleThickness on holizontal text layout
        if orientation == .verticalRuler {
            self.textObserver = NotificationCenter.default.addObserver(forName: NSText.didChangeNotification, object: textView, queue: nil) { [unowned self] _ in
                // -> count only if really needed since the line counting is high workload, especially by large document
                self.numberOfLines = max(self.textView?.numberOfLines ?? 0, 1)
            }
        }
    }
    
    
    required init(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        if let observer = self.textObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = self.opacityObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    
    
    // MARK: Ruler View Methods
    
    /// make background transparent
    override var isOpaque: Bool {
        
        return self.textView?.isOpaque ?? true
    }
    
    
    /// just before view will be attached
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        
        super.viewWillMove(toSuperview: newSuperview)
        
        // ignoe when detached
        guard self.superview != nil else { return }
        
        // set thicnesses at this point because doing it in `init` causes somehow a cash... (2018-10 macOS 10.14)
        self.reservedThicknessForMarkers = 0
        self.reservedThicknessForAccessoryView = 0
        self.invalidateDrawingInfoAndThickness()
    }
    
    
    /// observe window opacity change
    override func viewDidMoveToWindow() {
        
        super.viewDidMoveToWindow()
        
        // ignoe when detached
        guard let window = self.window else { return }
        
        // perform redraw on window opacity change
        self.opacityObserver = NotificationCenter.default.addObserver(forName: DocumentWindow.didChangeOpacityNotification, object: window, queue: .main) { [unowned self] _ in
            self.setNeedsDisplay(self.visibleRect)
        }
    }
    
    
    /// prepare line number drawing
    override func viewWillDraw() {
        
        super.viewWillDraw()
        
        self.invalidateDrawingInfoAndThickness()
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
            let context = NSGraphicsContext.current?.cgContext
            else { return assertionFailure() }
        
        context.saveGState()
        
        context.setFont(LineNumberView.lineNumberFont)
        context.setFontSize(drawingInfo.fontSize)
        context.setFillColor(self.textColor().cgColor)
        context.setStrokeColor(self.textColor(.stroke).cgColor)
        
        let isVerticalText = textView.layoutOrientation == .vertical
        let scale = textView.scale
        
        // adjust drawing coordinate
        let relativePoint = self.convert(NSPoint.zero, from: textView)
        let lineBase = textView.textContainerOrigin.scaled(to: scale).y + drawingInfo.ascent
        switch textView.layoutOrientation {
        case .horizontal:
            context.translateBy(x: self.ruleThickness, y: relativePoint.y + lineBase)
        case .vertical:
            context.translateBy(x: round(relativePoint.x - lineBase), y: self.ruleThickness)
        }
        context.scaleBy(x: 1, y: -1)  // flip
        
        // draw labels
        textView.enumerateLineFragments(in: textView.visibleRect) { (line, lineRect) in
            let y = scale * -lineRect.minY
            
            switch line {
            case .new(let lineNumber, let isSelected):
                // draw line number
                if !isVerticalText || isSelected || lineNumber % 5 == 0 || lineNumber == 1 || lineNumber == self.numberOfLines {
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
                    
                    // draw
                    if isSelected {
                        context.setFillColor(self.textColor(.bold).cgColor)
                        context.setFont(LineNumberView.boldLineNumberFont)
                    }
                    context.showGlyphs(glyphs, at: positions)
                    if isSelected {
                        context.setFillColor(self.textColor().cgColor)
                        context.setFont(LineNumberView.lineNumberFont)
                    }
                }
                
                // draw tick
                if isVerticalText {
                    let rect = CGRect(x: round(y) + 0.5, y: 1, width: 0, height: drawingInfo.tickLength)
                    context.stroke(rect, width: 1)
                }
                
            case .wrapped:
                // draw wrapped mark (-)
                if !isVerticalText {
                    let position = CGPoint(x: -drawingInfo.padding - drawingInfo.charWidth, y: y)
                    context.showGlyphs([drawingInfo.wrappedMarkGlyph], at: [position])
                }
            }
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
    
    
    /// update parameters related to drawing and layout based on textView's status
    private func invalidateDrawingInfoAndThickness() {
        
        guard
            let textFont = self.textView?.font,
            let scale = self.textView?.scale
            else { return assertionFailure() }
        
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
                let thickness = CGFloat(requiredNumberOfDigits) * drawingInfo.charWidth + 2 * drawingInfo.padding
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
        
        return (self % Int(pow(10, Double(place + 1)))) / Int(pow(10, Double(place)))
    }
    
}


private extension FloatingPoint {
    
    func round(interval: Self) -> Self {
        
        return (self / interval).rounded() * interval
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
