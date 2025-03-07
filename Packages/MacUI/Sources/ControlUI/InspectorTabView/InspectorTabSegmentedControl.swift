//
//  InspectorTabSegmentedControl.swift
//  InspectorTabView
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-09-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2024 1024jp
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

final class InspectorTabSegmentedControl: NSSegmentedControl {
    
    // MARK: Private Properties
    
    private var images: [Int: NSImage] = [:]
    private var selectedImages: [Int: NSImage] = [:]
    
    
    // MARK: Segmented Control Methods
    
    override func viewWillDraw() {
        
        super.viewWillDraw()
        
        self.alphaValue = (self.window?.isMainWindow ?? false) ? 1 : 0.5
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
    
    /// Sets images for both normal and selected states for the specified segment.
    ///
    /// - Parameters:
    ///   - image: The image to apply to the segment or `nil` if you want to clear the existing image.
    ///   - selectedImage: The image to apply to the segment with selected state or `nil` if you want to clear the existing image.
    ///   - segment: The index of the segment whose images you want to set.
    func setImage(_ image: NSImage?, selectedImage: NSImage?, forSegment segment: Int) {
        
        assert(image?.isTemplate != false)
        assert(selectedImage?.isTemplate != false)
        
        let selectedImage = selectedImage?.tinted(with: .controlAccentColor)
        
        super.setImage((segment == self.selectedSegment) ? selectedImage : image, forSegment: segment)
        
        self.images[segment] = image
        self.selectedImages[segment] = selectedImage
    }
    
    
    // MARK: Private Methods
    
    /// Returns the image associated with the specified segment by taking the selection state into consideration.
    ///
    /// - Parameters:
    ///   - segment: The index of the segment whose image you want to get.
    ///   - selected: The selection state of the segment.
    /// - Returns: An image for the segment.
    private func image(forSegment segment: Int, selected: Bool) -> NSImage? {
        
        (selected ? self.selectedImages : self.images)[segment] ?? self.image(forSegment: segment)
    }
}
