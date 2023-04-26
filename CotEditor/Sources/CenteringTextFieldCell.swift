//
//  CenteringTextFieldCell.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-09-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2021 1024jp
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

final class CenteringTextFieldCell: NSTextFieldCell {
    
    /// rect of content text
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        
        var titleRect = super.titleRect(forBounds: rect)
        let titleSize = self.attributedStringValue.size()
        
        titleRect.origin.y = (rect.minY + (rect.height - titleSize.height) / 2).rounded(.down)
        titleRect.size.height = rect.height - titleRect.origin.y
        
        return titleRect
    }
    
    
    /// draw inside of field
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        self.attributedStringValue.draw(in: self.titleRect(forBounds: cellFrame))
    }
}
