//
//  SwitcherSegmentedCell.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-09-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2018 1024jp
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

import Cocoa

final class SwitcherSegmentedCell: NSSegmentedCell {
    
    // MARK: Segmented Cell Methods
    
    /// customize drawing items
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        // draw only inside
        self.drawInterior(withFrame: cellFrame, in: controlView)
    }
    
    
    /// draw each segment
    override func drawSegment(_ segment: Int, inFrame frame: NSRect, with controlView: NSView) {
        
        // use another image for selected segments
        // -> From the universal design point of view, it's better to use an image that has a different silhouette from the normal (unselected) one,
        //    because some users may hard to distinguish the selected state just by the color.
        if self.isSelected(forSegment: segment) {
            // load "selected" icon template
            guard
                let iconName = self.image(forSegment: segment)?.name(),
                let image = NSImage(named: "Selected" + iconName)
                else { fatalError("No selected icon template for inspector tab view was found.") }
            
            // calculate area to draw
            let imageRect = NSRect(origin: frame.mid.offset(by: -image.size.scaled(to: 0.5)),
                                   size: image.size)
            let alignedImageRect = controlView.centerScanRect(imageRect)
            
            // draw icon template
            image.draw(in: alignedImageRect)
            
            // tint
            NSColor.controlAccentColor.set()
            alignedImageRect.fill(using: .sourceIn)
            
        } else {
            super.drawSegment(segment, inFrame: frame, with: controlView)
        }
    }
    
}
