//
//  PaddingTextFieldCell.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-23.
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

@IBDesignable
final class PaddingTextFieldCell: NSTextFieldCell {
    
    // MARK: Public Properties
    
    @IBInspectable var leftPadding: CGFloat = 0
    @IBInspectable var rightPadding: CGFloat = 0
    
    
    
    // MARK: -
    // MARK: Cell Methods
    
    /// add padding to area to draw text
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        
        assert(self.leftPadding >= 0)
        assert(self.rightPadding >= 0)
        
        var newRect = rect
        
        // add left padding
        newRect.size.width -= self.leftPadding
        newRect.origin.x += self.leftPadding
        
        // add right padding
        newRect.size.width -= self.rightPadding
        
        return super.drawingRect(forBounds: newRect)
    }
    
}
