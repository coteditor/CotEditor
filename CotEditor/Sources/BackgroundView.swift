//
//  BackgroundView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-03-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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
final class BackgroundView: NSView {
    
    @IBInspectable private var backgroundColor: NSColor = .windowBackgroundColor
    
    
    
    // MARK: View Methods
    
    override var wantsUpdateLayer: Bool {
        
        return true
    }
    
    
    override var isOpaque: Bool {
        
        return self.backgroundColor.alphaComponent == 1.0
    }
    
    
    override func updateLayer() {
        
        self.layer?.backgroundColor = self.backgroundColor.cgColor
    }
    
}
