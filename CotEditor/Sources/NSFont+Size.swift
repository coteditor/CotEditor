/*
 
 NSFont+Size.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-22.
 
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

import AppKit

extension NSFont {
    
    /**
     Calculate advancement of a character using NSLayoutManager.
     
     - parameters:
        - character: Character to calculate advancement.
     
     - returns: Advancement of passed-in character.
     
     - note: This method is not light-weigt since it creates new NSTextStorage and NSLayoutManager every time it's called. You should store the value somewhere to use this repeatedly.
     */
    func advancement(character: Character) -> NSSize {
        
        let textStorage = NSTextStorage(string: String(character))
        textStorage.font = self
        let layoutManager = NSLayoutManager()
        layoutManager.textStorage = textStorage
        let glyph = layoutManager.glyph(at: 0)
        
        return self.advancement(forGlyph: glyph)
    }
    
}
