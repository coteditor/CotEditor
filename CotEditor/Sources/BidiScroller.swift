//
//  BidiScroller.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-03-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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

final class BidiScroller: NSScroller {
    
    // MARK: Scroller methods
    
    override class var isCompatibleWithOverlayScrollers: Bool  { true }
    
    
    override var frame: NSRect {
        
        get { super.frame }
        
        set {
            var newValue = newValue
            if self.scrollView?.isInconsistentScrollerDirection == true {
                newValue.origin.x = self.originX
            }
            super.frame = newValue
        }
    }
    
    
    override func drawKnob() {
        
        self.flipHorizontalCoordinateIfNeeded(for: .knob)
        super.drawKnob()
    }
    
    
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        
        self.flipHorizontalCoordinateIfNeeded(for: .knobSlot)
        super.drawKnobSlot(in: slotRect, highlight: flag)
    }
    
    
    override func rect(for part: NSScroller.Part) -> NSRect {
        
        var partRect = super.rect(for: part)
        
        // workaround that the vertical scroller is cropped when .knobSlot is not shown (macOS 12)
        if self.isVertical,
           self.scrollView?.isInconsistentScrollerDirection == true,
           self.scrollerStyle == .overlay,
           part == .knob,
           partRect.width != 0,
           partRect.width != self.bounds.width
        {
            partRect.origin.x = 0
            partRect.size.width = self.bounds.width
        }
        
        return partRect
    }
    
    
    
    // MARK: Private Methods
    
    /// The scroller view where the receiver participates.
    private var scrollView: BidiScrollView? {
        
        self.superview as? BidiScrollView
    }
    
    
    /// Whether the receiver is a vertical scroller.
    private var isVertical: Bool {
        
        self.scrollView?.verticalScroller == self
    }
    
    
    /// X-origin of the scroller considering the border and the visibility of another scrollers.
    private var originX: CGFloat {
        
        guard let scrollView = self.scrollView else { return 0 }
        
        assert(scrollView.isInconsistentScrollerDirection)
        
        let inset = scrollView.contentInsets.left + scrollView.scrollerInsets.left
        
        switch (scrollView.scrollerDirection, self.isVertical) {
            case (.leftToRight, true):
                // move vertical scroller to the right side
                return scrollView.frame.width - self.thickness
                
            case (.leftToRight, false):
                return inset
                
            case (.rightToLeft, true):
                return inset
                
            case (.rightToLeft, false):
                // give a space for the vertical scroller
                if self.scrollerStyle == .legacy,
                   scrollView.hasVerticalScroller,
                   let scroller = scrollView.verticalScroller,
                   !scroller.isHidden
                {
                    return inset + scroller.thickness
                } else {
                    return inset
                }
                
            @unknown default:
                assertionFailure()
                return inset
        }
    }
    
    
    /// Horizontally flips the drawing coordinate when the scroller direction is not equal to the UI layout direction.
    ///
    /// - Parameter part: The scroller part drawing in.
    private func flipHorizontalCoordinateIfNeeded(for part: NSScroller.Part) {
        
        guard
            self.isVertical,
            self.scrollView?.isInconsistentScrollerDirection == true
        else { return }
        
        let flip = NSAffineTransform()
        flip.translateX(by: self.rect(for: part).width, yBy: 0)
        if part == .knob, self.userInterfaceLayoutDirection == .rightToLeft {
            // add 1 px to adjust aesthetically
            flip.translateX(by: 1, yBy: 0)
        }
        flip.scaleX(by: -1, yBy: 1)
        flip.concat()
    }
}
