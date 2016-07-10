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
    var visibleRange: NSRange {  // TODO: make optional
        
        guard let scrollView = self.enclosingScrollView,
              let layoutManager = self.layoutManager,
              let textContainer = self.textContainer else { return NotFoundRange }
        
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
        
        set (scale) {
            guard let scrollView = self.enclosingScrollView,
                let layoutManager = self.layoutManager,
                let textContainer = self.textContainer else { return }
            
            // sanitize scale
            let scale = within(scrollView.minMagnification, scale, scrollView.maxMagnification)
            
            // scale
            self.scaleUnitSquare(to: self.convert(NSSize.unit, from: nil))  // reset
            self.scaleUnitSquare(to: NSSize(width: scale, height: scale))
            
            // ensure bounds origin is {0, 0} for vertical text orientation
            self.needsDisplay = true
            self.translateOrigin(to: self.bounds.origin)
            
            // reset minimum size for unwrap mode
            self.minSize = scrollView.contentSize.scaled(to: 1.0 / scale)
            
            // ensure text layout
            layoutManager.ensureLayout(forCharacterRange: self.string?.nsRange ?? NotFoundRange)
            layoutManager.ensureLayout(for: textContainer)
            self.sizeToFit()
            
            // dummy reselection to force redrawing current line highlight
            let selectedRanges = self.selectedRanges
            self.selectedRanges = selectedRanges
        }
    }
    
    
    /// zoom to the scale keeping passed-in point position in scroll view
    func setScale(_ scale: CGFloat, centeredAt point: NSPoint) {
        
        guard let scrollView = self.enclosingScrollView,
              let layoutManager = self.layoutManager,
              let textContainer = self.textContainer where scale != self.scale else { return }
        
        // store current coordinate
        let centerGlyphIndex = layoutManager.glyphIndex(for: point, in: textContainer)
        let currentScale = self.scale
        let isVertical = (self.layoutOrientation == .vertical)
        let visibleRect = scrollView.documentVisibleRect
        let visibleOrigin = NSPoint(x: visibleRect.minX, y: isVertical ? visibleRect.maxY : visibleRect.minY)
        let centerFromClipOrigin = point.offsetBy(dx: -visibleOrigin.x, dy: visibleOrigin.y).scaled(to: currentScale)  // from top-left
        
        
        self.scale = scale
        
        // adjust scroller to keep position of the glyph at the passed-in center point
        if self.scale != currentScale {
            let newCenterFromClipOrigin = centerFromClipOrigin.scaled(to: 1.0 / scale)
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
            
            // adjust coordinates in horitonzal text layout mode
            // -> `setLayoutOrientation` swaps horizontal and vertical coordinates automatically and intelligently.
            if isVertical {
                self.setLayoutOrientation(.horizontal)
            }
            
            scrollView.hasHorizontalScroller = !wrapsLines
            textContainer.widthTracksTextView = wrapsLines
            if wrapsLines {
                let contentSize = scrollView.contentSize
                textContainer.containerSize = NSSize(width: round(contentSize.width / self.scale), height: CGFloat.greatestFiniteMagnitude)
                self.setConstrainedFrameSize(contentSize)
            } else {
                textContainer.containerSize = NSSize.infinite
            }
            self.autoresizingMask = wrapsLines ? .viewWidthSizable : .viewNotSizable
            self.isHorizontallyResizable = !wrapsLines
            
            // restore vertical layout
            if isVertical {
                self.setLayoutOrientation(.vertical)
            }
            
            self.scrollRangeToVisible(visibleRange)
        }
    }
    
}
