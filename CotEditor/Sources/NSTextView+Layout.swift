/*
 
 NSTextView+Layout.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-31.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

import AppKit

// MARK: Range
extension NSTextView {
    
    /// calculate visible range
    var visibleRange: NSRange? {
        
        guard let scrollView = self.enclosingScrollView,
              let layoutManager = self.layoutManager,
              let textContainer = self.textContainer else { return nil }
        
        let containerOrigin = self.textContainerOrigin
        let visibleRect = scrollView.documentVisibleRect.offsetBy(dx: -containerOrigin.x, dy: -containerOrigin.y)
        let glyphRange = layoutManager.glyphRange(forBoundingRectWithoutAdditionalLayout: visibleRect, in: textContainer)
        
        return layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
    }
    
}



// MARK:
// MARK: Scaling

// cf. https://developer.apple.com/library/mac/qa/qa1346/_index.html

extension NSTextView {
    
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
            let relativeScale = scale / self.scale
            self.scaleUnitSquare(to: NSSize(width: relativeScale, height: relativeScale))
            
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
        }
    }
    
    
    /// zoom to the scale keeping passed-in point position in scroll view
    func setScale(_ scale: CGFloat, centeredAt point: NSPoint) {
        
        guard let scrollView = self.enclosingScrollView,
              let layoutManager = self.layoutManager,
              let textContainer = self.textContainer, scale != self.scale else { return }
        
        // store current coordinate
        let centerGlyphIndex = layoutManager.glyphIndex(for: point, in: textContainer)
        let currentScale = self.scale
        let isVertical = (self.layoutOrientation == .vertical)
        let visibleRect = scrollView.documentVisibleRect
        let visibleOrigin = NSPoint(x: visibleRect.minX, y: isVertical ? visibleRect.maxY : visibleRect.minY)
        let centerFromClipOrigin = point.offsetBy(dx: -visibleOrigin.x, dy: -visibleOrigin.y).scaled(to: currentScale)  // from top-left
        
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



// MARK:
// MARK: Wrapping

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
                textContainer.containerSize = NSSize(width: contentSize.width.divided(by: self.scale).rounded(),
                                                     height: CGFloat.greatestFiniteMagnitude)
                self.setConstrainedFrameSize(contentSize)
            } else {
                textContainer.containerSize = NSSize.infinite
            }
            self.autoresizingMask = wrapsLines ? (isVertical ? .viewHeightSizable : .viewWidthSizable) : .viewNotSizable
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
