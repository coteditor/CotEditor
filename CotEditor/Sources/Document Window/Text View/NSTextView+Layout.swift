//
//  NSTextView+Layout.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-31.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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

// MARK: Range

extension NSTextView {
    
    /// The range of visible characters.
    ///
    /// - Note: This API requires TextKit 1.
    final var visibleRange: NSRange? {
        
        self.range(for: self.visibleRect, withoutAdditionalLayout: true)
    }
    
    
    /// Returns the range of characters in the given rect.
    ///
    /// - Note: This API requires TextKit 1.
    final func range(for rect: NSRect, withoutAdditionalLayout: Bool = false) -> NSRange? {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
        else { return nil }
        
        let visibleRect = rect.offset(by: -self.textContainerOrigin)
        let glyphRange = withoutAdditionalLayout
            ? layoutManager.glyphRange(forBoundingRectWithoutAdditionalLayout: visibleRect, in: textContainer)
            : layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        
        return layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
    }
    
    
    /// Returns bounding rectangle (in text view coordinates) enclosing all the given character range.
    ///
    /// - Note: This API requires TextKit 1.
    final func boundingRect(for range: NSRange) -> NSRect? {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
        else { return nil }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        return boundingRect.offset(by: self.textContainerOrigin)
    }
    
    
    /// Returns bounding rectangles (in text view coordinates) enclosing all the given character range.
    ///
    /// - Note: This API requires TextKit 1.
    final func boundingRects(for range: NSRange) -> [NSRect] {
        
        var count = 0
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer,
            let rectArray = layoutManager.rectArray(forCharacterRange: range, withinSelectedCharacterRange: range,
                                                    in: textContainer, rectCount: &count)
        else { return [] }
        
        return (0..<count).map { rectArray[$0].offset(by: self.textContainerOrigin) }
    }
}


// MARK: - Scaling

// cf. https://developer.apple.com/library/mac/qa/qa1346/_index.html

extension NSTextView {
    
    // MARK: Public Methods
    
    /// The current zooming scale.
    @objc final var scale: CGFloat {
        
        get {
            self.convert(.unit, to: nil).width
        }
        
        set {
            assert(newValue > 0)
            
            // sanitize value
            let scale = self.enclosingScrollView
                .map { $0.minMagnification...$0.maxMagnification }
                .map { newValue.clamped(to: $0) } ?? newValue
            
            guard scale != self.scale else { return }
            
            // scale
            self.willChangeValue(for: \.scale)
            self.scaleUnitSquare(to: self.convert(.unit, from: nil))  // reset scale
            self.scaleUnitSquare(to: NSSize(width: scale, height: scale))
            self.didChangeValue(for: \.scale)
            
            // reset minimum size for unwrap mode
            let visibleRect = self.enclosingScrollView?.documentVisibleRect ?? self.visibleRect
            self.minSize = visibleRect.size
            
            // update view size
            // -> For in the case by scaling-down when the view becomes bigger than text content width
            //    but doesn't stretch enough to the right edge of the scroll view.
            self.sizeToFit()
            
            self.needsDisplay = true
            self.invalidateRestorableState()
        }
    }
    
    
    /// Zooms to the scale keeping passed-in point position in scroll view.
    ///
    /// - Note: This API requires TextKit 1.
    final func setScale(_ scale: CGFloat, centeredAt point: NSPoint) {
        
        let currentScale = self.scale
        
        guard scale != currentScale else { return }
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
        else { return assertionFailure() }
        
        // store current coordinate
        let centerGlyphIndex = layoutManager.glyphIndex(for: point.offset(by: self.textContainerOrigin), in: textContainer)
        let isVertical = (self.layoutOrientation == .vertical)
        let visibleRect = self.visibleRect
        let visibleOrigin = NSPoint(x: visibleRect.minX, y: isVertical ? visibleRect.maxY : visibleRect.minY)
        let centerFromClipOrigin = point.offset(by: -visibleOrigin).scaled(to: currentScale)  // from top-left
        
        self.scale = scale
        
        guard self.scale != currentScale else { return }
        
        // adjust scroller to keep position of the glyph at the passed-in center point
        let newCenterFromClipOrigin = centerFromClipOrigin.scaled(to: 1.0 / self.scale)
        let glyphRange = NSRange(location: centerGlyphIndex, length: 1)
        let newCenter = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let scrollPoint = NSPoint(x: point.x, y: newCenter.midY).offset(by: -newCenterFromClipOrigin)
        self.scroll(scrollPoint)
    }
    
    
    /// Zooms to the scale keeping current visible rect position in scroll view.
    ///
    /// - Note: This API requires TextKit 1.
    final func setScaleKeepingVisibleArea(_ scale: CGFloat) {
        
        self.setScale(scale, centeredAt: self.visibleRect.mid)
    }
}


// MARK: - Wrapping

extension NSTextView {
    
    /// Whether soft wraps lines.
    ///
    /// - Note: This API requires TextKit 1.
    final var wrapsLines: Bool {
        
        get {
            self.textContainer?.widthTracksTextView ?? false
        }
        
        set {
            guard newValue != self.wrapsLines else { return }
            
            guard let textContainer = self.textContainer else { return assertionFailure() }
            
            let visibleRange = self.visibleRange
            let isVertical = (self.layoutOrientation == .vertical)
            
            if isVertical {
                self.enclosingScrollView?.hasVerticalScroller = !newValue
                self.isVerticallyResizable = !newValue
            } else {
                self.enclosingScrollView?.hasHorizontalScroller = !newValue
                self.isHorizontallyResizable = !newValue
            }
            
            if newValue {
                let width = self.visibleRect.width
                self.frame.size[keyPath: isVertical ? \NSSize.height : \NSSize.width] = width * self.scale
                textContainer.size.width = width
                textContainer.widthTracksTextView = true
            } else {
                textContainer.widthTracksTextView = false
                textContainer.size = self.infiniteSize
            }
            
            if let visibleRange, var visibleRect = self.boundingRect(for: visibleRange) {
                if self.baseWritingDirection == .rightToLeft {
                    visibleRect.origin.x = self.frame.width
                }
                visibleRect.size.width = 0
                visibleRect = visibleRect.inset(by: -self.textContainerInset)
                self.scrollToVisible(visibleRect)
            }
        }
    }
    
    
    /// Returns the infinite size for textContainer considering writing orientation state.
    final var infiniteSize: CGSize {
        
        // infinite size doesn't work with RTL (2018-01 macOS 10.13).
        (self.baseWritingDirection == .rightToLeft)
            ? CGSize(width: 9_999_999, height: CGSize.infinite.height)
            : .infinite
    }
}
