//
//  InspectorTabSegmentedControl.swift
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

final class InspectorTabSegmentedControl: NSSegmentedControl {
    
    // MARK: Private Properties
    
    private var images: [Int: (regular: NSImage, selected: NSImage)] = [:]
    
    
    
    // MARK: -
    // MARK: Segmented Control Methods
    
    override class var cellClass: AnyClass? {
        
        get { InspectorTabSegmentedCell.self }
        set { _ = newValue }
    }
    
    
    override var selectedSegment: Int {
        
        didSet {
            for segment in 0..<self.segmentCount {
                let image = self.image(forSegment: segment, selected: segment == selectedSegment)
                
                super.setImage(image, forSegment: segment)
            }
        }
    }
    
    
    @available(*, unavailable, message: "Use 'setImage(_:selectedImage:forSegment:)' instead.")
    override func setImage(_ image: NSImage?, forSegment segment: Int) { }
    
    
    
    // MARK: Public Methods
    
    /// Set images for both normal state and selected state for the specified segment.
    ///
    /// - Parameters:
    ///   - image: The image to apply to the segment or `nil` if you want to clear the existing image.
    ///   - selectedImage: The image to applay to the segment with selected state or `nil` if you want to clear the existing image.
    ///   - segment: The index of the segment whose images you want to set.
    func setImage(_ image: NSImage?, selectedImage: NSImage?, forSegment segment: Int) {
        
        assert(image?.isTemplate == true)
        assert(selectedImage?.isTemplate == true)
        
        super.setImage(image, forSegment: segment)
        
        guard let image = image, let selectedImage = selectedImage else {
            self.images[segment] = nil
            return
        }
        
        self.images[segment] = (image, selectedImage.tinted(with: .controlAccentColor))
    }
    
    
    
    // MARK: Private Methods
    
    /// Return the image associated with the specified segment by taking the selection state into concideration.
    ///
    /// - Parameters:
    ///   - segment: The index of the segment whose image you want to get.
    ///   - selected: The selection state of the segment.
    /// - Returns: A image for the  segment.
    private func image(forSegment segment: Int, selected: Bool) -> NSImage? {
        
        guard let cache = self.images[segment] else {
            return self.image(forSegment: segment)
        }
        
        return selected ? cache.selected : cache.regular
    }
    
}



final private class InspectorTabSegmentedCell: NSSegmentedCell {
    
    // MARK: Segmented Cell Methods
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        // draw only inside
        self.drawInterior(withFrame: cellFrame, in: controlView)
    }
    
}
