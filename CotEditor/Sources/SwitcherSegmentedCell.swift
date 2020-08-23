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
//  © 2015-2020 1024jp
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
    
    // MARK: Private Properties
    
    private var imageCache: [Int: (regular: NSImage, selected: NSImage)] = [:]
    
    
    
    // MARK: -
    // MARK: Segmented Cell Methods
    
    override var selectedSegment: Int {
        
        didSet {
            for segment in 0..<self.segmentCount {
                let image = self.image(forSegment: segment, selected: segment == selectedSegment)
                assert(image != nil)
                
                super.setImage(image, forSegment: segment)
            }
        }
    }
    
    
    override func setImage(_ image: NSImage?, forSegment segment: Int) {
        
        self.imageCache[segment] = nil
        
        super.setImage(image, forSegment: segment)
    }
    
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        // draw only inside
        self.drawInterior(withFrame: cellFrame, in: controlView)
    }
    
    
    
    // MARK: Private Methods
    
    /// Return the image associated with the specified segment by taking the selection state into concideration.
    ///
    /// - Parameters:
    ///   - segment: The index of the segment whose image you want to get.
    ///   - selected: The selection state of the segment.
    /// - Returns: A image for the  segment.
    private func image(forSegment segment: Int, selected: Bool) -> NSImage? {
        
        if let cache = self.imageCache[segment] {
            return selected ? cache.selected : cache.regular
        }
        
        guard let regularImage = self.image(forSegment: segment) else { return nil }
        
        if !selected { return regularImage }
        
        guard
            let name = regularImage.name(),
            let selectedImage = NSImage(named: "Selected" + name)
            else { return nil }
        
        let tintedImage = selectedImage.tinted(with: .controlAccentColor)
        
        self.imageCache[segment] = (regularImage, tintedImage)
        
        return tintedImage
    }
    
}
