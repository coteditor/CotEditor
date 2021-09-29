//
//  CharacterField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2021 1024jp
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

final class CharacterField: NSTextField {
    
    fileprivate private(set) var drawsGuide = false
    
    
    // MARK: Text Field Methods
    
    override var intrinsicContentSize: NSSize {
        
        let bounds = self.attributedStringValue.bounds
        let pathBounds = self.attributedStringValue.pathBounds
        
        return NSSize(width: pathBounds.width,
                      height: max(pathBounds.height, bounds.height))
    }
    
    
    #if DEBUG
    override func mouseDown(with event: NSEvent) {
        
        super.mouseDown(with: event)
        
        self.drawsGuide.toggle()
        self.needsDisplay = true
    }
    #endif
    
}



final class CharacterFieldCell: NSTextFieldCell {
    
    // MARK: Text Field Cell Methods
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        let bounds = self.attributedStringValue.bounds
        let pathBounds = self.attributedStringValue.pathBounds
        let centeringRect = NSRect(origin: cellFrame.mid, size: .zero).inset(by: -pathBounds.size.scaled(to: 0.5))
        let drawingPoint = centeringRect.origin.offsetBy(dx: -pathBounds.minX, dy: pathBounds.maxY - bounds.maxY)
        
        self.attributedStringValue.draw(at: drawingPoint)
        
        if (self.controlView as? CharacterField)?.drawsGuide == true {
            cellFrame.frame(withWidth: 0.2)
            centeringRect.frame(withWidth: 0.2)
        }
    }
    
}



private extension NSAttributedString {
    
    var bounds: NSRect { self.boundingRect(with: .infinite, context: nil) }
    var pathBounds: NSRect { self.boundingRect(with: .infinite, options: .usesDeviceMetrics, context: nil) }
}
