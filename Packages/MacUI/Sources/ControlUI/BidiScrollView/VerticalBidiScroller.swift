//
//  VerticalBidiScroller.swift
//  BidiScrollView
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-03-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2025 1024jp
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

@available(macOS, deprecated: 26)
final class VerticalBidiScroller: NSScroller {
    
    // MARK: Scroller methods
    
    // -> A subclass is not compatible by default while NSScroller itself returns `true` (2025-09, macOS 26)
    override static var isCompatibleWithOverlayScrollers: Bool  { true }
    
    
    override func drawKnob() {
        
        self.flipHorizontalCoordinateIfNeeded(for: .knob)
        super.drawKnob()
    }
    
    
    override func rect(for part: NSScroller.Part) -> NSRect {
        
        var partRect = super.rect(for: part)
        
        // workaround that the vertical scroller is cropped when .knobSlot is not shown (macOS 12-15)
        if self.isInconsistentContentDirection,
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
    
    /// Whether the parent scroll view's content direction is inconsistent with user interface layout direction.
    private var isInconsistentContentDirection: Bool {
        
        (unsafe self.superview as? BidiScrollView)?.isInconsistentContentDirection == true
    }
    
    
    /// Horizontally flips the drawing coordinate when the scroller direction is not equal to the UI layout direction.
    ///
    /// - Parameter part: The scroller part drawing in.
    private func flipHorizontalCoordinateIfNeeded(for part: NSScroller.Part) {
        
        guard self.isInconsistentContentDirection else { return }
        
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
