//
//  AntialiasingTextField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

final class AntialiasingTextField: NSTextField {
    
    // MARK: Public Properties
    
    @Invalidating(.display) var disablesAntialiasing = false
    
    
    
    // MARK: -
    // MARK: Text Field Methods
    
    /// control antialiasing of text
    override func draw(_ dirtyRect: NSRect) {
        
        if self.disablesAntialiasing {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current?.shouldAntialias = false
        }
        
        super.draw(dirtyRect)
        
        if self.disablesAntialiasing {
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}
