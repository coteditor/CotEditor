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
//  © 2014-2025 1024jp
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
    
    private struct DrawingInfo: Equatable {
        
        var fontSize: CGFloat
        var charWidth: CGFloat
        var digitGlyphs: [CGGlyph]
        var padding: CGFloat
        var tickLength: CGFloat
        
        
        init(font: CGFont, fontSize: CGFloat, scale: CGFloat) {
            
            // calculate font size for number
            self.fontSize = scale * fontSize
            
            // prepare glyphs
            let ctFont = CTFontCreateWithGraphicsFont(font, self.fontSize, nil, nil)
            self.digitGlyphs = (0...9).map { ctFont.glyph(for: Character(String($0))) }
            
            // calculate character width by assuming the font is monospace
            self.charWidth = ctFont.advance(for: self.digitGlyphs[8]).width  // use '8' to get width
            
            // calculate margins
            self.padding = self.charWidth
            self.tickLength = scale * fontSize / 3
        }
    }
    
    
    private enum ColorStrength: Double {
        
        case normal = 0.6
        case bold = 1.0
        case stroke = 0.4
        case separator = 0.85
        
        static let highContrastCoefficient = 0.4
    }
    
    
    // MARK: Public Properties
    
    weak var textView: NSTextView?  { didSet { self.updateTextView(textView) } }
    
    var orientation: NSLayoutManager.TextLayoutOrientation = .horizontal {
        
        didSet {
            if !self.isHiddenOrHasHiddenAncestor {
                self.invalidateThickness()
            }
        }
    }
    
    @Invalidating(.display) var layoutDirection: NSUserInterfaceLayoutDirection = .leftToRight
    @Invalidating(.display) var drawsSeparator = false
    
    
    // MARK: Private Properties
    
    private let lineNumberFont: CGFont = NSFont.lineNumberFont().cgFont
    private let boldLineNumberFont: CGFont = NSFont.lineNumberFont(weight: .medium).cgFont
    private let highContrastBoldLineNumberFont: CGFont = NSFont.lineNumberFont(weight: .semibold).cgFont
    
    private let minimumNumberOfDigits = 3
    
    private var drawingInfo: DrawingInfo?
    @Invalidating(.display, .intrinsicContentSize) private var thickness: Double = 32
    
    @Invalidating(.display) private var textColor: NSColor = .textColor
    @Invalidating(.display) private var backgroundColor: NSColor = .textBackgroundColor
    
    private var opacityObserver: AnyCancellable?
    private var textStorageObserver: AnyCancellable?
    private var textViewSubscriptions: Set<AnyCancellable> = []
    
    private var draggingInfo: DraggingInfo?
    
    
    // MARK: View Methods
    
    override func accessibilityLabel() -> String? {
        
        String(localized: "Line Numbers", table: "Document", comment: "accessibility label")
    }
    
    
    override var isOpaque: Bool {
        
        self.textView?.isOpaque != false
    }
    
    
    override var intrinsicContentSize: NSSize {
        
        switch self.orientation {
            case .horizontal: NSSize(width: self.thickness, height: NSView.noIntrinsicMetric)
            case .vertical:   NSSize(width: NSView.noIntrinsicMetric, height: self.thickness)
            @unknown default: fatalError()
        }
    }
    
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        
        super.viewWillMove(toWindow: newWindow)
        
        // remove observations before all observed objects are deallocated
        if newWindow == nil {
            self.updateTextView(nil)
        }
        
        // redraw on window opacity change
        self.opacityObserver = newWindow?.publisher(for: \.isOpaque)
            .sink { [weak self] _ in self?.needsDisplay = true }
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        NSGraphicsContext.saveGraphicsState()
        
        let fillView = dirtyRect.intersection(self.bounds)
        
        // fill background
        if self.isOpaque {
            self.backgroundColor.setFill()
            fillView.fill()
        }
        
        // draw separator
        if self.drawsSeparator {
            let lineRect: NSRect = switch (self.orientation, self.layoutDirection) {
                case (.vertical, _):    NSRect(x: 0, y: 0, width: self.frame.width, height: 1)
                case (_, .rightToLeft): NSRect(x: 0, y: 0, width: 1, height: self.frame.height)
                default:                NSRect(x: self.frame.width - 1, y: 0, width: 1, height: self.frame.height)
            }
            
            self.foregroundColor(.separator).set()
            self.backingAlignedRect(lineRect, options: .alignAllEdgesOutward)
                .intersection(fillView)
                .fill()
        }
        
        self.drawNumbers(in: dirtyRect)
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    // MARK: Private Methods
    
    /// The total number of lines in the text view.
    private var numberOfLines: Int {
        
        guard let textView = self.textView else { return 0 }
        
        return textView.lineNumber(at: textView.string.length)
    }
    
    
    /// Returns foreground color by considering the current accessibility setting.
    private func foregroundColor(_ strength: ColorStrength = .normal) -> NSColor {
        
        let fraction = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
            ? strength.rawValue + ColorStrength.highContrastCoefficient
            : strength.rawValue
        
        return fraction < 1
            ? self.textColor.withAlphaComponent(1 - fraction)
            : self.textColor
    }
    
    
    /// Returns line number font for selected lines by considering the current accessibility setting.
    private var effectiveBoldLineNumberFont: CGFont {
        
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
            ? self.highContrastBoldLineNumberFont
            : self.boldLineNumberFont
    }
    
    
    /// Draws line numbers.
    private func drawNumbers(in rect: NSRect) {
        
        guard
            let textView = self.textView,
            let layoutManager = textView.layoutManager as? LayoutManager,
            let drawingInfo = self.drawingInfo
        else { return }
        
        guard
            // -> Requires additionalLayout to obtain glyphRange for markedText. (2018-12 macOS 10.14 SDK)
            let range = textView.range(for: textView.visibleRect),
            let context = NSGraphicsContext.current?.cgContext
        else { return assertionFailure() }
        
        context.setFont(self.lineNumberFont)
        context.setFontSize(drawingInfo.fontSize)
        context.setFillColor(self.foregroundColor().cgColor)
        context.setStrokeColor(self.foregroundColor(.stroke).cgColor)
        
        let isVerticalText = textView.layoutOrientation == .vertical
        let scale = textView.scale
        
        // adjust drawing coordinate
        let relativePoint = self.convert(NSPoint.zero, from: textView)
        let originOffset = scale * textView.textContainerOrigin.y
        let lineOffset = scale * layoutManager.baselineOffset(for: textView.layoutOrientation)
        switch textView.layoutOrientation {
            case .horizontal:
                context.translateBy(x: self.thickness, y: relativePoint.y - originOffset)
            case .vertical:
                context.translateBy(x: relativePoint.x - originOffset, y: 0)
            @unknown default: fatalError()
        }
        
        // draw labels
        let options: NSTextView.LineEnumerationOptions = isVerticalText ? .onlySelectionBoundary : []
        textView.enumerateLineFragments(in: range, options: options) { (lineRect, lineNumber, isSelected) in
            let y = (scale * -lineRect.minY) - lineOffset
            
            // draw tick
            if isVerticalText {
                let rect = CGRect(x: y.rounded() + 0.5, y: 1, width: 0, height: drawingInfo.tickLength)
                context.stroke(rect, width: scale)
            }
            
            // skip intermediate lines by vertical orientation
            let drawsNumber = !isVerticalText || lineNumber.isMultiple(of: 5) || lineNumber == 1 || lineNumber == self.numberOfLines
            guard isSelected || drawsNumber else { return }
            
            let digits = lineNumber.digits
            
            // calculate base position
            let basePosition = isVerticalText
                ? CGPoint(x: y + drawingInfo.charWidth * Double(digits.count) / 2, y: 3 * drawingInfo.tickLength)
                : CGPoint(x: -drawingInfo.padding, y: y)
            
            // get glyphs and positions
            let positions: [CGPoint] = digits.indices
                .map { basePosition.offsetBy(dx: -Double($0 + 1) * drawingInfo.charWidth) }
            let glyphs: [CGGlyph] = digits
                .map { drawingInfo.digitGlyphs[$0] }
            
            // draw number
            if isSelected {
                context.setFillColor(self.foregroundColor(.bold).cgColor)
                context.setFont(self.effectiveBoldLineNumberFont)
            }
            context.showGlyphs(glyphs, at: positions)
            if isSelected {
                context.setFillColor(self.foregroundColor().cgColor)
                context.setFont(self.lineNumberFont)
            }
        }
    }
    
    
    /// Updates parameters related to drawing and layout based on textView's status.
    private func invalidateDrawingInfo() {
        
        guard
            let textView = self.textView,
            let textFont = textView.font
        else { return assertionFailure() }
        
        let drawingInfo = DrawingInfo(font: self.lineNumberFont, fontSize: textFont.pointSize, scale: textView.scale)
        
        guard self.drawingInfo != drawingInfo else { return }
        
        self.drawingInfo = drawingInfo
        self.needsDisplay = true
        
        self.invalidateThickness()
    }
    
    
    /// Updates receiver's thickness based on drawingInfo and textView's status.
    private func invalidateThickness() {
        
        var thickness: Double = 0
        if let drawingInfo = self.drawingInfo {
            switch self.orientation {
                case .horizontal:
                    let requiredNumberOfDigits = max(self.numberOfLines.digits.count, self.minimumNumberOfDigits)
                    thickness = CGFloat(requiredNumberOfDigits) * drawingInfo.charWidth + 2 * drawingInfo.padding
                    
                case .vertical:
                    thickness = drawingInfo.fontSize + 4 * drawingInfo.tickLength
                    
                @unknown default: break
            }
        }
        
        let minimumThickness: Double = (self.orientation == .vertical) ? 20 : 32
        self.thickness = max(thickness.rounded(.up), minimumThickness)
    }
    
    
    /// Observes textView's update to update line number drawing.
    private func updateTextView(_ textView: NSTextView?) {
        
        guard let textView else {
            self.textStorageObserver?.cancel()
            self.textViewSubscriptions.removeAll()
            return
        }
        
        assert(textView.enclosingScrollView?.contentView != nil)
        
        self.drawingInfo = DrawingInfo(font: self.lineNumberFont, fontSize: textView.font!.pointSize, scale: textView.scale)
        
        self.textViewSubscriptions = [
            // observe contents change
            textView.layoutManager!.publisher(for: \.textStorage, options: .initial)
                .sink { [weak self] in
                    self?.invalidateThickness()
                    self?.textStorageObserver = NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: $0)
                        .map { $0.object as! NSTextStorage }
                        .filter { $0.editedMask.contains(.editedCharacters) }
                        .receive(on: RunLoop.main)  // touch textView on main thread
                        .sink { [weak self] _ in
                            // -> The digit of the line numbers affect thickness.
                            self?.invalidateThickness()
                            self?.needsDisplay = true
                        }
                },
            
            NotificationCenter.default.publisher(for: EditorTextView.didLiveChangeSelectionNotification, object: textView)
                .sink { [weak self] _ in self?.needsDisplay = true },
            
            NotificationCenter.default.publisher(for: NSView.frameDidChangeNotification, object: textView)
                .sink { [weak self] _ in self?.needsDisplay = true },
            
            NotificationCenter.default.publisher(for: NSView.boundsDidChangeNotification, object: textView.enclosingScrollView?.contentView)
                .sink { [weak self] _ in self?.needsDisplay = true },
            
            textView.publisher(for: \.defaultParagraphStyle?.lineHeightMultiple)
                .sink { [weak self] _ in self?.needsDisplay = true },
            
            textView.publisher(for: \.textColor, options: .initial)
                .compactMap(\.self)
                .sink { [weak self] in self?.textColor = $0 },
            
            textView.publisher(for: \.backgroundColor, options: .initial)
                .sink { [weak self] in self?.backgroundColor = $0 },
            
            textView.publisher(for: \.font)
                .sink { [weak self] _ in self?.invalidateDrawingInfo() },
            
            textView.publisher(for: \.scale)
                .sink { [weak self] _ in self?.invalidateDrawingInfo() },
        ]
    }
}


// MARK: - Controlling Text View

extension LineNumberView {
    
    fileprivate struct DraggingInfo {
        
        var index: Int
        var selectedRanges: [NSRange]
    }
    
    
    // MARK: View Methods
    
    /// Scrolls parent textView with scroll event.
    override func scrollWheel(with event: NSEvent) {
        
        self.textView?.scrollWheel(with: event)
    }
    
    
    /// Starts selecting correspondent lines in text view with a dragging / clicking event.
    override func mouseDown(with event: NSEvent) {
        
        guard
            let textView = self.textView,
            let window = self.window
        else { return assertionFailure() }
        
        // get start point
        let point = window.convertPoint(toScreen: event.locationInWindow)
        let index = textView.characterIndex(for: point)
        
        let selectedRanges = textView.selectedRanges.map(\.rangeValue)
        
        self.draggingInfo = DraggingInfo(index: index, selectedRanges: selectedRanges)
        
        // for single click event
        self.selectLines(with: event)
    }
    
    
    /// Selects lines while dragging event.
    override func mouseDragged(with event: NSEvent) {
        
        self.selectLines(with: event)
    }
    
    
    /// Ends selecting correspondent lines in text view with drag event.
    override func mouseUp(with event: NSEvent) {
        
        self.draggingInfo = nil
    }
    
    
    // MARK: Private Methods
    
    /// Selects lines while dragging event.
    private func selectLines(with event: NSEvent) {
        
        guard
            let textView = self.textView,
            let window = self.window,
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
