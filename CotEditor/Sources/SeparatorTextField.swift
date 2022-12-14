//
//  SeparatorTextField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2021 1024jp
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

final class SeparatorTextField: NSTextField {
    
    // MARK: Text Field Methods
    
    override var intrinsicContentSize: NSSize {
        
        var size = super.intrinsicContentSize
        
        if self.isSeparator {
            size.height = (size.height / 2).rounded(.up)
        }
        
        return size
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        guard self.isSeparator else {
            return super.draw(dirtyRect)
        }
        
        NSGraphicsContext.saveGraphicsState()
        
        let separatorRect = NSRect(x: dirtyRect.minX, y: self.frame.midY, width: dirtyRect.width, height: 1)
        NSColor.gridColor.setFill()
        self.centerScanRect(separatorRect).fill()
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    
    // MARK: Private Properties
    
    /// whether it is a separator item
    private var isSeparator: Bool {
        
        self.stringValue == .separator
    }
}
