/*
 
 NSTextView+Layout.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-31.
 
 ------------------------------------------------------------------------------
 
 © 2016-2017 1024jp
 
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

import AppKit

// MARK: Range

private extension NSGlyph {
    
    static let verticalTab = NSGlyph(16777215)
}


extension NSTextView {
    
    /// calculate visible range
    var visibleRange: NSRange? {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer else { return nil }
        
        let visibleRect = self.visibleRect.offset(by: -self.textContainerOrigin)
        let glyphRange = layoutManager.glyphRange(forBoundingRectWithoutAdditionalLayout: visibleRect, in: textContainer)
        
        return layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
    }
    
    
    /// return bounding rectangle (in text view coordinates) enclosing all the given character range
    func boundingRect(for range: NSRange) -> NSRect? {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer else { return nil }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // adjust size if the substring of the given range is single vertical tab character.
        if glyphRange.length == 1, layoutManager.glyph(at: glyphRange.location) == .verticalTab {
            let lineHeight = layoutManager.lineFragmentRect(forGlyphAt: range.location, effectiveRange: nil).height
            
            boundingRect.size = CGSize(width: lineHeight / 2, height: lineHeight)
        }
        
        return boundingRect.offset(by: self.textContainerOrigin)
    }
    
}



// MARK: - Scaling

// cf. https://developer.apple.com/library/mac/qa/qa1346/_index.html

extension NSTextView {
    
    // MARK: Notification Names
    
    static let didChangeScaleNotification = Notification.Name("TextViewDidChangeScale")
    
    
    
    // MARK: Public Methods
    
    /// current zooming scale
    var scale: CGFloat {
        
        get {
            return self.convert(NSSize.unit, to: nil).width
        }
        
        set {
            guard
                let layoutManager = self.layoutManager,
                let textContainer = self.textContainer else { return }
            
            // sanitize scale
            let scale: CGFloat = {
                guard let scrollView = self.enclosingScrollView else { return newValue }
                
                return newValue.within(min: scrollView.minMagnification, max: scrollView.maxMagnification)
            }()
            
            // scale
            self.scaleUnitSquare(to: self.convert(.unit, from: nil))  // reset scale
            self.scaleUnitSquare(to: NSSize(width: scale, height: scale))
            
            // ensure bounds origin is {0, 0} for vertical text orientation
            self.translateOrigin(to: self.bounds.origin)
            
            // reset minimum size for unwrap mode
            self.minSize = self.visibleRect.size
            
            // ensure text layout
            layoutManager.ensureLayout(for: textContainer)
            self.sizeToFit()
            
            // dummy reselection to force redrawing current line highlight
            let selectedRanges = self.selectedRanges
            self.selectedRanges = selectedRanges
            
            self.setNeedsDisplay(self.visibleRect, avoidAdditionalLayout: true)
            
            NotificationCenter.default.post(name: NSTextView.didChangeScaleNotification, object: self)
        }
    }
    
    
    /// zoom to the scale keeping passed-in point position in scroll view
    func setScale(_ scale: CGFloat, centeredAt point: NSPoint) {
        
        let currentScale = self.scale
        
        guard
            scale != currentScale,
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer else { return }
        
        // store current coordinate
        let centerGlyphIndex = layoutManager.glyphIndex(for: point, in: textContainer)
        let isVertical = (self.layoutOrientation == .vertical)
        let visibleRect = self.visibleRect
        let visibleOrigin = NSPoint(x: visibleRect.minX, y: isVertical ? visibleRect.maxY : visibleRect.minY)
        let centerFromClipOrigin = point.offset(by: -visibleOrigin).scaled(to: currentScale)  // from top-left
        
        self.scale = scale
        
        // adjust scroller to keep position of the glyph at the passed-in center point
        if self.scale != currentScale {
            let newCenterFromClipOrigin = centerFromClipOrigin.scaled(to: 1.0 / self.scale)
            let newCenter = layoutManager.boundingRect(forGlyphRange: NSRange(location: centerGlyphIndex, length: 1), in: textContainer)
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
            guard let container = self.textContainer else { return false }
            
            return (container.containerSize.width != CGFloat.greatestFiniteMagnitude)
        }
        
        set (wrapsLines) {
            guard let scrollView = self.enclosingScrollView,
                  let textContainer = self.textContainer else { return }
            
            let visibleRange = self.visibleRange
            let isVertical = (self.layoutOrientation == .vertical)
            
            textContainer.widthTracksTextView = wrapsLines
            if wrapsLines {
                let contentSize = scrollView.contentSize
                textContainer.containerSize = NSSize(width: (contentSize.width / self.scale).rounded(),
                                                     height: CGFloat.greatestFiniteMagnitude)
                self.setConstrainedFrameSize(contentSize)
            } else {
                textContainer.containerSize = .infinite
            }
            self.autoresizingMask = wrapsLines ? (isVertical ? .height : .width) : .none
            if isVertical {
                scrollView.hasVerticalScroller = !wrapsLines
                self.isVerticallyResizable = !wrapsLines
            } else {
                scrollView.hasHorizontalScroller = !wrapsLines
                self.isHorizontallyResizable = !wrapsLines
            }
            self.sizeToFit()
            
            if let visibleRange = visibleRange {
                self.scrollRangeToVisible(visibleRange)
            }
        }
    }
    
}
