/*
 
 NSImage+Template.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-11-16.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension NSImage {
    
    /// return copy of image tinted with the color or standard template image if `color` is `nil`
    func tinted(color: NSColor?) -> NSImage {
        
        let tinted = self.copy() as! NSImage
        
        guard let color = color else {
            tinted.isTemplate = true
            return tinted
        }
        
        let imageRect = NSRect(origin: .zero, size: self.size)
        
        tinted.lockFocus()
        
        color.set()
        NSRectFillUsingOperation(imageRect, .sourceAtop)
        
        tinted.unlockFocus()
        tinted.isTemplate = false
        
        return tinted
    }
    
}
