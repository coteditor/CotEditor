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
//  © 2014-2023 1024jp
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
import Combine
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
            self.fontSize = scale * fontSize
            
            // prepare glyphs
            let font = CTFontCreateWithGraphicsFont(LineNumberView.lineNumberFont, self.fontSize, nil, nil)
            self.wrappedMarkGlyph = font.glyph(for: "-")
            self.digitGlyphs = (0...9).map { font.glyph(for: Character(String($0))) }
            
            // calculate character width assuming the font is monospace
            self.charWidth = font.advance(for: self.digitGlyphs[8]).width  // use '8' to get width
            
            // calculate margins
            self.padding = self.charWidth
            self.tickLength = scale * fontSize / 3
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
    private let minVerticalThickness = 32.0
    private let minHorizontalThickness = 20.0
    
    private static let lineNumberFont: CGFont = NSFont.lineNumberFont().cgFont
    private static let boldLineNumberFont: CGFont = NSFont.lineNumberFont(weight: .medium).cgFont
    private static let highContrastBoldLineNumberFont: CGFont = NSFont.lineNumberFont(weight: .semibold).cgFont
    
    private enum ColorStrength: CGFloat {
        
        case normal = 0.6
        case bold = 1.0
        case stroke = 0.4
        case separator = 0.85
        
        static let highContrastCoefficient = 0.4
    }
    
    
    // MARK: Private Properties
    
    private var drawingInfo: DrawingInfo?
    private var thickness = 32.0
    
    @Invalidating(.display) private var textColor: NSColor = .textColor
    @Invalidating(.display) private var backgroundColor: NSColor = .textBackgroundColor
    @Invalidating(.display) private var drawsSeparator = false
    
    private var settingObserver: AnyCancellable?
    private var opacityObserver: AnyCancellable?
    private var textViewSubscriptions: Set<AnyCancellable> = []
    
    private var draggingInfo: DraggingInfo?
    
    @IBOutlet private weak var textView: NSTextView? {
        
        didSet {
            guard let textView else { return }
            
            self.observeTextView(textView)
            self.invalidateDrawingInfo()
        }
    }
    
    
    
    // MARK: -
    // MARK: View Methods
    
    /// view name for VoiceOver
    override func accessibilityLabel() -> String? {
        
        String(localized: "Line Numbers")
    }
    
    
    /// make background transparent
    override var isOpaque: Bool {
        
        self.textView?.isOpaque ?? true
    }
    
    
    /// define the size
    override var intrinsicContentSize: NSSize {
        
        switch self.orientation {
            case .horizontal: NSSize(width: self.thickness, height: NSView.noIntrinsicMetric)
            case .vertical:   NSSize(width: NSView.noIntrinsicMetric, height: self.thickness)
            @unknown default: fatalError()
        }
    }
    
    
    /// receiver is about to be attached to / detached from a window
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        
        super.viewWillMove(toWindow: newWindow)
        
        // remove observations before all observed objects are deallocated
        if newWindow == nil {
            assert(self.textView?.enclosingScrollView?.contentView != nil)
            
            self.textViewSubscriptions.removeAll()
        }
        
        // redraw on window opacity change
        self.opacityObserver = newWindow?.publisher(for: \.isOpaque)
            .sink { [weak self] _ in self?.needsDisplay = true }
        
        // redraw on setting change
        self.settingObserver = UserDefaults.standard.publisher(for: .showLineNumberSeparator, initial: true)
            .sink { [weak self] in self?.drawsSeparator = $0 }
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
        
        // draw separator
        if self.drawsSeparator {
            let lineRect: NSRect = switch (self.orientation, self.textView?.baseWritingDirection) {
                case (.vertical, _):    NSRect(x: 0, y: 0, width: self.frame.width, height: 1)
                case (_, .rightToLeft): NSRect(x: 0, y: 0, width: 1, height: self.frame.height)
                default:                NSRect(x: self.frame.width - 1, y: 0, width: 1, height: self.frame.height)
            }
            
            NSGraphicsContext.saveGraphicsState()
            self.foregroundColor(.separator).set()
            self.backingAlignedRect(lineRect, options: .alignAllEdgesOutward)
                .intersection(dirtyRect)
                .fill()
            NSGraphicsContext.restoreGraphicsState()
        }
        
        self.drawNumbers(in: dirtyRect)
    }
    
    
    
    // MARK: Private Methods
    
    /// total number of lines in the text view
    private var numberOfLines: Int {
        
        guard let textView = self.textView else { return 1 }
        
        assert(textView.layoutManager is any LineRangeCacheable)
        
        return textView.lineNumber(at: textView.string.length)
    }
    
    
    /// return foreground color by considering the current accessibility setting
    private func foregroundColor(_ strength: ColorStrength = .normal) -> NSColor {
        
        let fraction = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
            ? strength.rawValue + ColorStrength.highContrastCoefficient
            : strength.rawValue
        
        return fraction < 1
            ? self.textColor.withAlphaComponent(1 - fraction)
            : self.textColor
    }
    
    
    /// return line number font for selected lines by considering the current accessibility setting
    private var boldLineNumberFont: CGFont {
        
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
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
                context.translateBy(x: (relativePoint.x - lineBase).rounded(), y: 0)
            @unknown default: fatalError()
        }
        
        // draw labels
        let options: NSTextView.LineEnumerationOptions = isVerticalText ? [.bySkippingWrappedLine] : []
        textView.enumerateLineFragments(in: textView.visibleRect, options: options) { (lineRect, line, lineNumber) in
            let y = scale * -lineRect.minY
            
            switch line {
                case .new(let isSelected):
                    // draw line number
                    if !isVerticalText || isSelected || lineNumber.isMultiple(of: 5) || lineNumber == 1 || lineNumber == self.numberOfLines {
                        let digits = lineNumber.digits
                        
                        // calculate base position
                        let basePosition: CGPoint = isVerticalText
                            ? CGPoint(x: (y + drawingInfo.charWidth * CGFloat(digits.count) / 2).rounded(.up), y: 3 * drawingInfo.tickLength)
                            : CGPoint(x: -drawingInfo.padding, y: y)
                        
                        // get glyphs and positions
                        let positions: [CGPoint] = (0..<digits.count)
                            .map { basePosition.offsetBy(dx: -CGFloat($0 + 1) * drawingInfo.charWidth) }
                        let glyphs: [CGGlyph] = digits
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
                        let rect = CGRect(x: y.rounded() + 0.5, y: 1, width: 0, height: drawingInfo.tickLength)
                        context.stroke(rect, width: scale)
                    }
                    
                case .wrapped:
                    // draw wrapped mark (-)
                    let position = CGPoint(x: -drawingInfo.padding - drawingInfo.charWidth, y: y)
                    context.showGlyphs([drawingInfo.wrappedMarkGlyph], at: [position])
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
                    let requiredNumberOfDigits = max(self.numberOfLines.digits.count, self.minNumberOfDigits)
                    let thickness = CGFloat(requiredNumberOfDigits) * drawingInfo.charWidth + 2 * drawingInfo.padding
                    return max(thickness.rounded(.up), self.minVerticalThickness)
                    
                case .vertical:
                    let thickness = drawingInfo.fontSize + 4 * drawingInfo.tickLength
                    return max(thickness.rounded(.up), self.minHorizontalThickness)
                    
                @unknown default: fatalError()
            }
        }()
        
        guard thickness != self.thickness else { return }
        
        self.thickness = thickness
        self.invalidateIntrinsicContentSize()
    }
    
    
    /// observe textView's update to update line number drawing
    private func observeTextView(_ textView: NSTextView) {
        
        assert(textView.enclosingScrollView?.contentView != nil)
        
        self.textViewSubscriptions.removeAll()
        
        // observe content change
        NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: nil)
            .compactMap { $0.object as? NSTextStorage }
            .filter { $0.editedMask.contains(.editedCharacters) }
            .receive(on: RunLoop.main)  // touch textView on main thread
            .filter { [weak self] in $0 == self?.textView?.textStorage }
            .sink { [weak self] _ in
                // -> The digit of the line numbers affect thickness.
                if self?.orientation == .horizontal {
                    self?.invalidateThickness()
                }
                self?.needsDisplay = true
            }
            .store(in: &self.textViewSubscriptions)
        
        NotificationCenter.default.publisher(for: EditorTextView.didLiveChangeSelectionNotification, object: textView)
            .sink { [weak self] _ in self?.needsDisplay = true }
            .store(in: &self.textViewSubscriptions)
        
        NotificationCenter.default.publisher(for: NSView.frameDidChangeNotification, object: textView)
            .sink { [weak self] _ in self?.needsDisplay = true }
            .store(in: &self.textViewSubscriptions)
        
        NotificationCenter.default.publisher(for: NSView.boundsDidChangeNotification, object: textView.enclosingScrollView?.contentView)
            .sink { [weak self] _ in self?.needsDisplay = true }
            .store(in: &self.textViewSubscriptions)
        
        textView.publisher(for: \.defaultParagraphStyle?.lineHeightMultiple)
            .sink { [weak self] _ in self?.needsDisplay = true }
            .store(in: &self.textViewSubscriptions)
        
        textView.publisher(for: \.textColor, options: .initial)
            .compactMap { $0 }
            .sink { [weak self] in self?.textColor = $0 }
            .store(in: &self.textViewSubscriptions)
        
        textView.publisher(for: \.backgroundColor, options: .initial)
            .sink { [weak self] in self?.backgroundColor = $0 }
            .store(in: &self.textViewSubscriptions)
        
        textView.publisher(for: \.font)
            .sink { [weak self] _ in self?.invalidateDrawingInfo() }
            .store(in: &self.textViewSubscriptions)
        
        textView.publisher(for: \.scale)
            .sink { [weak self] _ in self?.invalidateDrawingInfo() }
            .store(in: &self.textViewSubscriptions)
    }
}



// MARK: - Controlling Text View

extension LineNumberView {
    
    fileprivate struct DraggingInfo {
        
        var index: Int
        var selectedRanges: [NSRange]
    }
    
    
    
    // MARK: View Methods
    
    /// scroll parent textView with scroll event
    override func scrollWheel(with event: NSEvent) {
        
        self.textView?.scrollWheel(with: event)
    }
    
    
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
        
        self.draggingInfo = DraggingInfo(index: index, selectedRanges: selectedRanges)
        
        // for single click event
        self.selectLines(with: event)
    }
    
    
    /// select lines while dragging event
    override func mouseDragged(with event: NSEvent) {
        
        self.selectLines(with: event)
    }
    
    
    /// end selecting correspondent lines in text view with drag event
    override func mouseUp(with event: NSEvent) {
        
        self.draggingInfo = nil
    }
    
    
    
    // MARK: Private Methods
    
    /// select lines while dragging event
    private func selectLines(with event: NSEvent) {
        
        guard
            let window = self.window,
            let textView = self.textView,
            let draggingInfo = self.draggingInfo
        else { return assertionFailure() }
        
        // scroll text view if needed
        let point = textView.convert(event.locationInWindow, from: nil)  // textView-based
        textView.scrollToVisible(NSRect(origin: point, size: .zero))
        
        // move focus to textView
        window.makeFirstResponder(textView)
        
        // select lines
        let pointInScreen = window.convertPoint(toScreen: event.locationInWindow)
        let currentIndex = textView.characterIndex(for: pointInScreen)
        let clickedIndex = draggingInfo.index
        let string = textView.string as NSString
        let currentLineRange = string.lineRange(at: currentIndex)
        let clickedLineRange = string.lineRange(at: clickedIndex)
        var range = currentLineRange.union(clickedLineRange)
        
        let affinity: NSSelectionAffinity = (currentIndex < clickedIndex) ? .upstream : .downstream
        
        // with Command key (add selection)
        if event.modifierFlags.contains(.command) {
            var selectedRanges: [NSRange] = []
            var intersects = false
            
            for selectedRange in draggingInfo.selectedRanges {
                if selectedRange.lowerBound <= range.lowerBound, range.upperBound <= selectedRange.upperBound {  // exclude
                    let range1 = NSRange(selectedRange.lowerBound..<range.lowerBound)
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
        if event.modifierFlags.contains(.shift) {
            let selectedRange = textView.selectedRange
            
            if selectedRange.contains(currentIndex) {  // reduce
                let inUpperSelection = (currentIndex - selectedRange.lowerBound) < selectedRange.length / 2
                range = inUpperSelection  // clicked upper half section of selected range
                    ? NSRange(currentIndex..<selectedRange.upperBound)
                    : NSRange(selectedRange.lowerBound..<currentLineRange.upperBound)
                
            } else {  // expand
                range.formUnion(selectedRange)
            }
        }
        
        textView.setSelectedRange(range, affinity: affinity, stillSelecting: false)
    }
}
