//
//  ImageAttributes.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-11-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

struct ImageAttributes {
    
    var pixelSize: PixelSize
    var dotsPerInch: Double
    var colorSpace: NSColorSpace?
}


struct PixelSize {
    
    var width: Int
    var height: Int
}


extension NSImageRep {
    
    final var attributes: ImageAttributes {
        
        ImageAttributes(pixelSize: self.pixelSize,
                        dotsPerInch: self.dotsPerInch,
                        colorSpace: (self as? NSBitmapImageRep)?.colorSpace)
    }
    
    
    /// The size of image.
    final var pixelSize: PixelSize {
        
        PixelSize(width: self.pixelsWide, height: self.pixelsHigh)
    }
    
    
    /// The image DPI only considering X axis.
    final var dotsPerInch: Double {
        
        72 * Double(self.pixelsWide) / self.size.width
    }
}
