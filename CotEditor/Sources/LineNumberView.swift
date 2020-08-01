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
import CoreText.CTFont

final class LineNumberView: NSView {
    
    private struct DrawingInfo {
        
        let fontSize: CGFloat
        let charWidth: CGFloat
        let wrappedMarkGlyph: CGGlyph
        let digitGlyphs: [CGGlyph]
        let padding: CGFloat
        let tickLength: CGFloat
        
        
        init(fontSize: CGFloat, scale: CGFloat) {
            
            // calculate font size for number
            self.fontSize = (scale * LineNumberView.fontSizeFactor * fontSize).rounded(interval: 0.5)
            
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
        
    }
    
    
    // MARK: Public Properties
    
    var orientation: NSLayoutManager.TextLayoutOrientation = .horizontal {
        
        didSet {
            if !self.isHiddenOrHasHiddenAncestor {
                self.invalidateThickness()
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
    private static let boldLineNumberFont: CGFont = NSFont.lineNumberFont(weight: .medium).cgFont
    private static let highContrastBoldLineNumberFont: CGFont = NSFont.lineNumberFont(weight: .semibold).cgFont
    
    private enum ColorStrength: CGFloat {
        
        case normal = 0.5
        case bold = 1.0
        case stroke = 0.2
        
        static let highContrastCoefficient: CGFloat = 0.4
    }
    
    
    // MARK: Private Properties
    
    private var drawingInfo: DrawingInfo?
    private var thickness: CGFloat = 32
    
    private var opacityObserver: NotificationObservation?
    private var textObserver: NotificationObservation?
    private var selectionObserver: NotificationObservation?
    private var frameObserver: NotificationObservation?
    private var scrollObserver: NotificationObservation?
    private var colorObserver: NSKeyValueObservation?
    private var fontObserver: NSKeyValueObservation?
    private var scaleObserver: NSKeyValueObservation?
    
    private weak var draggingTimer: Timer?
    
    @IBOutlet private weak var textView: NSTextView? {
        
        didSet {
            guard let textView = textView else { return }
            
            self.observeTextView(textView)
            self.invalidateDrawingInfo()
        }
    }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.removeTextViewObservers()
        
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
        
        // perform redraw on window opacity change
        self.opacityObserver?.invalidate()
        if let window = newWindow {
            self.opacityObserver = NotificationCenter.default.addObserver(forName: DocumentWindow.didChangeOpacityNotification, object: window, queue: .main) { [weak self] _ in
                self?.needsDisplay = true
            }
        } else {
            self.opacityObserver = nil
        }
    }
    
    
    /// draw background
    override func draw(_ dirtyRect: NSRect) {
        
        // fill background
        if self.isOpaque {
            NSGraphicsContext.saveGraphicsState()
            
            self.backgroundColor.setFill()
            dirtyRect.fill()
            
            NSGraphicsContext.restoreGraphicsState()
        }
        
        self.drawNumbers(in: dirtyRect)
    }
    
    
    
    // MARK: Private Methods
    
    /// total number of lines in the text view
    private var numberOfLines: Int {
        
        guard let textView = self.textView else { return 1 }
        
        assert(textView.layoutManager is LineRangeCacheable)
        
        return textView.lineNumber(at: textView.string.length)
    }
    
    
    /// return foreground color by considering the current accesibility setting
    private func foregroundColor(_ strength: ColorStrength = .normal) -> NSColor {
        
        let textColor = self.textView?.textColor ?? .textColor
        let fraction = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
            ? strength.rawValue + ColorStrength.highContrastCoefficient
            : strength.rawValue
        
        guard fraction < 1 else { return textColor }
        
        return textColor.blended(withFraction: 1 - fraction, of: backgroundColor) ?? textColor
    }
    
    
    /// return background color to fill
    private var backgroundColor: NSColor {
        
        return self.textView?.backgroundColor ?? .textBackgroundColor
    }
    
    
    /// return line number font for selected lines by considering the current accesibility setting
    private var boldLineNumberFont: CGFont {
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
            ? Self.highContrastBoldLineNumberFont
            : Self.boldLineNumberFont
    }
    
    /// draw line numbers
    private func drawNumbers(in rect: NSRect) {
        
        guard
            let drawingInfo = self.drawingInfo,
            let textView = self.textView,
            let layoutManager = textView.layoutManager as? LayoutManager,
            let context = NSGraphicsContext.current?.cgContext
            else { return assertionFailure() }
        
        context.saveGState()
        
        context.setFont(Self.lineNumberFont)
        context.setFontSize(drawingInfo.fontSize)
        context.setFillColor(self.foregroundColor().cgColor)
        context.setStrokeColor(self.foregroundColor(.stroke).cgColor)
        
        let isVerticalText = textView.layoutOrientation == .vertical
        let scale = textView.scale
        
        // adjust drawing coordinate
        let relativePoint = self.convert(NSPoint.zero, from: textView)
        let baselineOffset = layoutManager.baselineOffset(for: textView.layoutOrientation)
        let lineBase = scale * (textView.textContainerOrigin.y + baselineOffset)
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
                            context.setFillColor(self.foregroundColor(.bold).cgColor)
                            context.setFont(self.boldLineNumberFont)
                        }
                        context.showGlyphs(glyphs, at: positions)
                        if isSelected {
                            context.setFillColor(self.foregroundColor().cgColor)
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
    
    
    /// Update parameters related to drawing and layout based on textView's status.
    private func invalidateDrawingInfo() {
        
        guard
            let textView = self.textView,
            let textFont = textView.font
            else { return assertionFailure() }
        
        self.drawingInfo = DrawingInfo(fontSize: textFont.pointSize, scale: textView.scale)
        
        self.invalidateThickness()
        self.needsDisplay = true
    }
    
    
    /// Update receiver's thickness based on drawingInfo and textView's status.
    private func invalidateThickness() {
        
        guard let drawingInfo = self.drawingInfo else { return assertionFailure() }
        
        let thickness: CGFloat = {
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
        
        guard thickness != self.thickness else { return }
        
        self.thickness = thickness
        self.invalidateIntrinsicContentSize()
    }
    
    
    /// observe textView's update to update line number drawing
    private func observeTextView(_ textView: NSTextView) {
        
        self.textObserver?.invalidate()
        self.textObserver = NotificationCenter.default.addObserver(forName: NSText.didChangeNotification, object: textView, queue: .main) { [weak self] _ in
            // -> The digit of the line numbers affect thickness.
            if self?.orientation == .horizontal {
                self?.invalidateThickness()
            }
            self?.needsDisplay = true
        }
        
        self.selectionObserver?.invalidate()
        self.selectionObserver = NotificationCenter.default.addObserver(forName: EditorTextView.didLiveChangeSelectionNotification, object: textView, queue: .main) { [weak self] _ in
            self?.needsDisplay = true
        }
        
        self.frameObserver?.invalidate()
        self.frameObserver = NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: textView, queue: .main) { [weak self] _ in
            self?.needsDisplay = true
        }
        
        self.scrollObserver?.invalidate()
        self.scrollObserver = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: textView.enclosingScrollView?.contentView, queue: .main) { [weak self] _ in
            self?.needsDisplay = true
        }
        
        self.colorObserver?.invalidate()
        self.colorObserver = textView.observe(\.backgroundColor) { [weak self] (_, _)  in
            self?.needsDisplay = true
        }
        
        self.fontObserver?.invalidate()
        self.fontObserver = textView.observe(\.font) { [weak self] (_, _)  in
            self?.invalidateDrawingInfo()
        }
        
        self.scaleObserver?.invalidate()
        self.scaleObserver = textView.observe(\.scale) { [weak self] (_, _)  in
            self?.invalidateDrawingInfo()
        }
    }
    
    
    /// remove observers observing textView
    private func removeTextViewObservers() {
        
        assert(self.textView != nil)
        assert(self.textView?.enclosingScrollView?.contentView != nil || self.scrollObserver == nil)
        
        self.textObserver?.invalidate()
        self.textObserver = nil
        
        self.selectionObserver?.invalidate()
        self.selectionObserver = nil
        
        self.frameObserver?.invalidate()
        self.frameObserver = nil
        
        self.scrollObserver?.invalidate()
        self.scrollObserver = nil
        
        self.colorObserver?.invalidate()
        self.colorObserver = nil
        
        self.fontObserver?.invalidate()
        self.fontObserver = nil
        
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
    
    func rounded(interval: Self) -> Self {
        
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
        
        let selectedRanges = textView.selectedRanges.map(\.rangeValue)
        
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
