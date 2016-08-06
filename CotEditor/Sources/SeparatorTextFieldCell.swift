/*
 
 SeparatorTextFieldCell.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-13.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class SeparatorTextFieldCell: NSTextFieldCell {
    
    // MARK: Private Properties
    
    /// whether it is a separator item
    var isSeparator: Bool {
        
        return self.stringValue == String.separator
    }
    
    
    
    // MARK: Menu Item Cell Methods
    
    /// draw cell
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        guard self.isSeparator else {
            return super.drawInterior(withFrame: cellFrame, in: controlView)
        }
        
        NSGraphicsContext.saveGraphicsState()
        
        NSColor.gridColor.setStroke()
        NSBezierPath.strokeLine(from: NSPoint(x: cellFrame.minX, y: floor(cellFrame.midY) + 0.5),
                                  to: NSPoint(x: cellFrame.maxX, y: floor(cellFrame.midY) + 0.5))
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
}
