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
//  © 2022-2023 1024jp
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
    
    override class var isCompatibleWithOverlayScrollers: Bool { true }
    
    
    override var frame: NSRect {
        
        get { super.frame }
        
        set {
            var newValue = newValue
            if self.scrollView?.scrollerDirection == .rightToLeft {
                newValue.origin.x = self.originX
            }
            super.frame = newValue
        }
    }
    
    
    override func drawKnob() {
        
        self.flipHorizontalCoordinatesInRightToLeftLayout(for: .knob)
        super.drawKnob()
    }
    
    
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        
        self.flipHorizontalCoordinatesInRightToLeftLayout(for: .knobSlot)
        super.drawKnobSlot(in: slotRect, highlight: flag)
    }
    
    
    override func rect(for part: NSScroller.Part) -> NSRect {
        
        var partRect = super.rect(for: part)
        
        // workaround that the vertical scroller is cropped when .knobSlot is not shown (macOS 12)
        if self.isVertical,
           self.scrollView?.scrollerDirection == .rightToLeft,
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
        
        assert(self.scrollView?.scrollerDirection == .rightToLeft)
        
        guard let scrollView = self.scrollView else { return 0 }
        
        let inset = scrollView.contentInsets.left + scrollView.scrollerInsets.left
        
        if !self.isVertical, self.scrollerStyle == .legacy {
            // give a space for the vertical scroller
            if scrollView.hasVerticalScroller, let scroller = scrollView.verticalScroller, !scroller.isHidden {
                return inset + scroller.thickness
            }
        } else {
            return inset + scrollView.borderType.width
        }
        
        return inset
    }
    
    
    /// Horizontally flip the drawing coordinate when the scroller direction is right-to-left.
    ///
    /// - Parameter part: The scroller part drawing in.
    private func flipHorizontalCoordinatesInRightToLeftLayout(for part: NSScroller.Part) {
        
        guard self.isVertical, self.scrollView?.scrollerDirection == .rightToLeft else { return }
        
        let flip = NSAffineTransform()
        flip.translateX(by: self.rect(for: part).width, yBy: 0)
        flip.scaleX(by: -1, yBy: 1)
        flip.concat()
    }
}



private extension NSBorderType {
    
    /// Border width.
    var width: CGFloat {
        
        switch self {
            case .noBorder:     return 0
            case .lineBorder:   return 1
            case .bezelBorder:  return 1
            case .grooveBorder: return 2
            @unknown default: return 0
        }
    }
}
