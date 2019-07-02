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
//  © 2016-2019 1024jp
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

private extension NSGlyph {
    
    static let verticalTab = NSGlyph(16777215)
}


extension NSTextView {
    
    /// calculate visible range
    var visibleRange: NSRange? {
        
        return self.range(for: self.visibleRect, withoutAdditionalLayout: true)
    }
    
    
    /// calculate range of characters in rect
    func range(for rect: NSRect, withoutAdditionalLayout: Bool = false) -> NSRange? {
        
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
    
    
    /// return bounding rectangle (in text view coordinates) enclosing all the given character range
    func boundingRect(for range: NSRange) -> NSRect? {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { return nil }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // adjust size if the substring of the given range is single vertical tab character.
        if glyphRange.length == 1, layoutManager.glyph(at: glyphRange.location) == .verticalTab {
            let lineHeight = layoutManager.lineFragmentRect(forGlyphAt: range.location, effectiveRange: nil).height
            
            boundingRect.size = CGSize(width: lineHeight / 2, height: lineHeight)
        }
        
        return boundingRect.offset(by: self.textContainerOrigin)
    }
    
    
    /// return bounding rectangles (in text view coordinates) enclosing all the given character range
    func boundingRects(for range: NSRange) -> [NSRect] {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { return [] }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        
        var rects: [NSRect] = []
        layoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: glyphRange, in: textContainer) { (rect, _) in
            rects.append(rect)
        }
        
        return rects.map { $0.offset(by: self.textContainerOrigin) }
    }
    
}



// MARK: - Scaling

// cf. https://developer.apple.com/library/mac/qa/qa1346/_index.html

extension NSTextView {
    
    // MARK: Public Methods
    
    /// current zooming scale
    @objc var scale: CGFloat {
        
        get {
            return self.convert(.unit, to: nil).width
        }
        
        set {
            // sanitize scale
            let scale: CGFloat = {
                guard let scrollView = self.enclosingScrollView else { return newValue }
                
                return newValue.clamped(to: scrollView.minMagnification...scrollView.maxMagnification)
            }()
            
            guard scale != self.scale else { return }
            
            self.willChangeValue(for: \.scale)
            
            // scale
            self.scaleUnitSquare(to: self.convert(.unit, from: nil))  // reset scale
            self.scaleUnitSquare(to: NSSize(width: scale, height: scale))
            
            // ensure bounds origin is {0, 0} for vertical text orientation
            self.translateOrigin(to: self.bounds.origin)
            
            // reset minimum size for unwrap mode
            self.minSize = self.visibleRect.size
            
            self.didChangeValue(for: \.scale)
            
            self.setNeedsDisplay(self.visibleRect)
        }
    }
    
    
    /// zoom to the scale keeping passed-in point position in scroll view
    func setScale(_ scale: CGFloat, centeredAt point: NSPoint) {
        
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
        
        // adjust scroller to keep position of the glyph at the passed-in center point
        if self.scale != currentScale {
            let newCenterFromClipOrigin = centerFromClipOrigin.scaled(to: 1.0 / self.scale)
            let glyphRange = NSRange(location: centerGlyphIndex, length: 1)
            let newCenter = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            let scrollPoint = NSPoint(x: round(point.x - newCenterFromClipOrigin.x),
                                      y: round(newCenter.midY - newCenterFromClipOrigin.y))
            self.scroll(scrollPoint)
        }
    }
    
    
    /// zoom to the scale keeping current visible rect position in scroll view
    func setScaleKeepingVisibleArea(_ scale: CGFloat) {
        
        self.setScale(scale, centeredAt: self.visibleRect.mid)
    }
    
}



// MARK: - Wrapping

extension NSTextView {
    
    /// if soft wrap lines
    var wrapsLines: Bool {
        
        get {
            return self.textContainer?.widthTracksTextView ?? false
        }
        
        set {
            guard newValue != self.wrapsLines else { return }
            
            guard let textContainer = self.textContainer else { return assertionFailure() }
            
            let visibleRange = self.visibleRange
            let isVertical = (self.layoutOrientation == .vertical)
            
            if newValue {
                let width = self.visibleRect.width
                self.frame.size[keyPath: isVertical ? \NSSize.height : \NSSize.width] = width * self.scale
                textContainer.size.width = width
                textContainer.widthTracksTextView = true
            } else {
                textContainer.widthTracksTextView = false
                textContainer.size = self.infiniteSize
            }
            
            if isVertical {
                self.isVerticallyResizable = !newValue
                self.enclosingScrollView?.hasVerticalScroller = !newValue
            } else {
                self.isHorizontallyResizable = !newValue
                self.enclosingScrollView?.hasHorizontalScroller = !newValue
            }
            
            if let visibleRange = visibleRange, var visibleRect = self.boundingRect(for: visibleRange) {
                visibleRect.size.width = 0
                visibleRect = visibleRect.inset(by: -self.textContainerOrigin)
                self.scrollToVisible(visibleRect)
            }
        }
    }
    
    
    /// return infinite size for textContainer considering writing orientation state
    var infiniteSize: CGSize {
        
        // infinite size doesn't work with RTL (2018-01 macOS 10.13).
        return (self.baseWritingDirection == .rightToLeft) ? CGSize(width: 9_999_999, height: CGSize.infinite.height) : .infinite
    }
    
}
