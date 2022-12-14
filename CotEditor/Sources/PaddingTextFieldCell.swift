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
//  © 2015-2022 1024jp
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

@IBDesignable
final class PaddingTextFieldCell: NSTextFieldCell {
    
    // MARK: Public Properties
    
    @IBInspectable var leadingPadding: CGFloat = 0
    @IBInspectable var trailingPadding: CGFloat = 0
    
    
    
    // MARK: -
    // MARK: Cell Methods
    
    /// add padding to area to draw text
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        
        assert(self.leadingPadding >= 0)
        assert(self.trailingPadding >= 0)
        
        let isLTR = self.userInterfaceLayoutDirection == .leftToRight
        let newRect = NSRect(x: rect.origin.x + (isLTR ? self.leadingPadding : self.trailingPadding),
                             y: rect.origin.y,
                             width: rect.width - self.leadingPadding - self.trailingPadding,
                             height: rect.height)
        
        return super.drawingRect(forBounds: newRect)
    }
}
