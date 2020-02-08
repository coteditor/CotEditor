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

final class LineNumberView: NSView {
    
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
            self.fontSize = (scale * LineNumberView.fontSizeFactor * textFont.pointSize).round(interval: 0.5)
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
    
    
    // MARK: Public Properties
    
    var orientation: NSLayoutManager.TextLayoutOrientation = .horizontal {
        
        didSet {
            if !self.isHiddenOrHasHiddenAncestor {
                self.invalidateDrawingInfoAndThickness()
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    
    // MARK: Constants
    
    private let minNumberOfDigits = 3
    private let minVerticalThickness: CGFloat = 32
    private let minHorizontalThickness: CGFloat = 20
    
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
    private var opacityObserver: NSObjectProtocol?
    private var textObserver: NSObjectProtocol?
    private var selectionObserver: NSObjectProtocol?
    private var frameObserver: NSObjectProtocol?
    private var scrollObserver: NSObjectProtocol?
    private var colorObserver: NSKeyValueObservation?
    private var scaleObserver: NSKeyValueObservation?
    
    private weak var draggingTimer: Timer?
    
    private var thickness: CGFloat = 32 {
        
        didSet {
            guard thickness != oldValue else { return }
            
            self.invalidateIntrinsicContentSize()
        }
    }
    
    @IBOutlet private weak var textView: NSTextView? {
        
        didSet {
            guard let textView = textView else { return }
            
            self.observeTextView(textView)
        }
    }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.removeTextViewObservers()
        
        if let observer = self.opacityObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        self.draggingTimer?.invalidate()
    }
    
    
    
    // MARK: View Methods
    
    /// view name for VoiceOver
    override func accessibilityLabel() -> String? {
        
        return "line numbers".localized
    }
    
    
    /// make background transparent
    override var isOpaque: Bool {
        
        return self.textView?.isOpaque ?? true
    }
    
    
    /// define the size
    override var intrinsicContentSize: NSSize {
        
        switch self.orientation {
        case .horizontal:
            return NSSize(width: self.thickness, height: NSView.noIntrinsicMetric)
        case .vertical:
            return NSSize(width: NSView.noIntrinsicMetric, height: self.thickness)
        @unknown default: fatalError()
        }
    }
    
    
    /// receiver is about to be attached to / detached from a window
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        
        super.viewWillMove(toWindow: newWindow)
        
        // remove observations before all observed objects are deallocated
        if newWindow == nil {
            self.removeTextViewObservers()
        }
        
        if let observer = self.opacityObserver {
            NotificationCenter.default.removeObserver(observer)
            self.opacityObserver = nil
        }
    }
    
    
    /// observe window opacity change
    override func viewDidMoveToWindow() {
        
        super.viewDidMoveToWindow()
        
        // ignore when detached
        guard let window = self.window else { return }
        
        // perform redraw on window opacity change
        self.opacityObserver = NotificationCenter.default.addObserver(forName: DocumentWindow.didChangeOpacityNotification, object: window, queue: .main) { [weak self] _ in
            guard let self = self else { return assertionFailure() }
            
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
        
        // draw divider (1px)
        self.textColor(.stroke).setStroke()
        switch self.orientation {
        case .horizontal:
            NSBezierPath.strokeLine(from: NSPoint(x: self.bounds.maxX - 0.5, y: dirtyRect.maxY),
                                    to: NSPoint(x: self.bounds.maxX - 0.5, y: dirtyRect.minY))
        case .vertical:
            NSBezierPath.strokeLine(from: NSPoint(x: dirtyRect.minX, y: self.bounds.minY + 0.5),
                                    to: NSPoint(x: dirtyRect.maxX, y: self.bounds.minY + 0.5))
        @unknown default: fatalError()
        }
        
        NSGraphicsContext.restoreGraphicsState()
        
        self.drawNumbers(in: dirtyRect)
    }
    
    
    
    // MARK: Private Methods
    
    /// return text color considering current accesibility setting
    private func textColor(_ strength: ColorStrength = .normal) -> NSColor {
        
        let textColor = self.textView?.textColor ?? .textColor
        
        if NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast, strength != .stroke {
            return textColor
        }
        
        return self.backgroundColor.blended(withFraction: strength.rawValue, of: textColor) ?? textColor
    }
    
    
    /// return background color to fill
    private var backgroundColor: NSColor {
        
        let isDarkBackground = (self.textView as? Themable)?.theme?.isDarkTheme ?? false
        
        if self.isOpaque, let color = self.textView?.backgroundColor {
            return (isDarkBackground ? color.highlight(withLevel: 0.08) : color.shadow(withLevel: 0.06)) ?? color
        } else {
            return isDarkBackground ? NSColor.white.withAlphaComponent(0.08) : NSColor.black.withAlphaComponent(0.06)
        }
    }
    
    
    /// draw line numbers
    private func drawNumbers(in rect: NSRect) {
        
        guard
            let drawingInfo = self.drawingInfo,
            let textView = self.textView,
            let context = NSGraphicsContext.current?.cgContext
            else { return assertionFailure() }
        
        context.saveGState()
        
        context.setFont(Self.lineNumberFont)
        context.setFontSize(drawingInfo.fontSize)
        context.setFillColor(self.textColor().cgColor)
        context.setStrokeColor(self.textColor(.stroke).cgColor)
        
        let isVerticalText = textView.layoutOrientation == .vertical
        let scale = textView.scale
        
        // adjust drawing coordinate
        let relativePoint = self.convert(NSPoint.zero, from: textView)
        let lineBase = (scale * textView.textContainerOrigin.y) + drawingInfo.ascent
        switch textView.layoutOrientation {
        case .horizontal:
            context.translateBy(x: self.thickness, y: relativePoint.y - lineBase)
        case .vertical:
            context.translateBy(x: round(relativePoint.x - lineBase), y: 0)
        @unknown default: fatalError()
        }
        
        // draw labels
        textView.enumerateLineFragments(in: textView.visibleRect) { (line, lineRect) in
            let y = scale * -lineRect.minY
            
            switch line {
            case .new(let lineNumber, let isSelected):
                // draw line number
                if !isVerticalText || isSelected || lineNumber.isMultiple(of: 5) || lineNumber == 1 || lineNumber == self.numberOfLines {
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
                        context.setFont(Self.boldLineNumberFont)
                    }
                    context.showGlyphs(glyphs, at: positions)
                    if isSelected {
                        context.setFillColor(self.textColor().cgColor)
                        context.setFont(Self.lineNumberFont)
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
        
        // adjust thickness
        self.thickness = {
            switch self.orientation {
            case .horizontal:
                let requiredNumberOfDigits = max(self.numberOfLines.numberOfDigits, self.minNumberOfDigits)
                let thickness = CGFloat(requiredNumberOfDigits) * drawingInfo.charWidth + 2 * drawingInfo.padding
                return max(ceil(thickness), self.minVerticalThickness)
            case .vertical:
                let thickness = drawingInfo.fontSize + 2.5 * drawingInfo.tickLength
                return max(ceil(thickness), self.minHorizontalThickness)
            @unknown default: fatalError()
            }
        }()
    }
    
    
    /// observe textView's update to update line number drawing
    private func observeTextView(_ textView: NSTextView) {
        
        self.textObserver = NotificationCenter.default.addObserver(forName: NSText.didChangeNotification, object: textView, queue: .main) { [weak self] (notification) in
            guard
                let self = self,
                let textView = notification.object as? NSTextView
                else { return assertionFailure() }
            
            if self.orientation == .horizontal {
                // -> Count only if really needed since the line counting is high workload, especially by large document.
                self.numberOfLines = (textView.string as NSString).lineNumber(at: textView.string.length)
            }
            
            self.needsDisplay = true
        }
        
        self.selectionObserver = NotificationCenter.default.addObserver(forName: EditorTextView.didLiveChangeSelectionNotification, object: textView, queue: .main) { [weak self] _ in
            self?.needsDisplay = true
        }
        
        self.frameObserver = NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: textView, queue: .main) { [weak self] _ in
            self?.needsDisplay = true
        }
        
        self.scrollObserver = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: textView.enclosingScrollView?.contentView, queue: .main) { [weak self] _ in
            self?.needsDisplay = true
        }
        
        self.colorObserver?.invalidate()
        self.colorObserver = textView.observe(\.backgroundColor) { [weak self] (_, _)  in
            self?.needsDisplay = true
        }
        
        self.scaleObserver?.invalidate()
        self.scaleObserver = textView.observe(\.scale) { [weak self] (_, _)  in
            self?.needsDisplay = true
        }
    }
    
    
    /// remove observers observing textView
    private func removeTextViewObservers() {
        
        if let observer = self.textObserver {
            assert(self.textView != nil)
            
            NotificationCenter.default.removeObserver(observer)
            self.textObserver = nil
        }
        
        if let observer = self.selectionObserver {
            assert(self.textView != nil)
            
            NotificationCenter.default.removeObserver(observer)
            self.selectionObserver = nil
        }
        
        if let observer = self.frameObserver {
            assert(self.textView != nil)
            
            NotificationCenter.default.removeObserver(observer)
            self.frameObserver = nil
        }
        
        if let observer = self.scrollObserver {
            assert(self.textView?.enclosingScrollView?.contentView != nil)
            
            NotificationCenter.default.removeObserver(observer)
            self.scrollObserver = nil
        }
        
        self.colorObserver?.invalidate()
        self.colorObserver = nil
        
        self.scaleObserver?.invalidate()
        self.scaleObserver = nil
    }
    
}



// MARK: Private Helper Extensions

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
            else { return assertionFailure() }
        
        // get start point
        let point = window.convertPoint(toScreen: event.locationInWindow)
        let index = textView.characterIndex(for: point)
        
        let selectedRanges = textView.selectedRanges.map { $0.rangeValue }
        
        // repeat while dragging
        self.draggingTimer = .scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(selectLines),
                                             userInfo: DraggingInfo(index: index, selectedRanges: selectedRanges),
                                             repeats: true)
        self.draggingTimer?.fire()  // for single click event
    }
    
    
    /// end selecting correspondent lines in text view with drag event
    override func mouseUp(with event: NSEvent) {
        
        self.draggingTimer?.invalidate()
    }
    
    
    
    // MARK: Private Methods
    
    /// select lines while dragging event
    @objc private func selectLines(_ timer: Timer) {
        
        guard
            let window = self.window,
            let textView = self.textView,
            let draggingInfo = timer.userInfo as? DraggingInfo
            else { return assertionFailure() }
        
        // scroll text view if needed
        let pointInScreen = NSEvent.mouseLocation
        let pointInWindow = window.convertPoint(fromScreen: pointInScreen)
        let point = textView.convert(pointInWindow, from: nil)  // textView-based
        textView.scrollToVisible(NSRect(origin: point, size: .zero))
        
        // move focus to textView
        window.makeFirstResponder(textView)
        
        // select lines
        let string = textView.string as NSString
        let currentIndex = textView.characterIndex(for: pointInScreen)
        let clickedIndex = draggingInfo.index
        let currentLineRange = string.lineRange(at: currentIndex)
        let clickedLineRange = string.lineRange(at: clickedIndex)
        var range = currentLineRange.union(clickedLineRange)
        
        let affinity: NSSelectionAffinity = (currentIndex < clickedIndex) ? .upstream : .downstream
        
        // with Command key (add selection)
        if NSEvent.modifierFlags.contains(.command) {
            var selectedRanges = [NSRange]()
            var intersects = false
            
            for selectedRange in draggingInfo.selectedRanges {
                if selectedRange.location <= range.location, range.upperBound <= selectedRange.upperBound {  // exclude
                    let range1 = NSRange(selectedRange.location..<range.location)
                    let range2 = NSRange(range.upperBound..<selectedRange.upperBound)
                    
                    if !range1.isEmpty {
                        selectedRanges.append(range1)
                    }
                    if !range2.isEmpty {
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
