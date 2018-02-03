/*
 
 NSFont+Size.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-22.
 
 ------------------------------------------------------------------------------
 
 © 2016-2018 1024jp
 
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
import CoreText

extension NSFont {
    
    /// width of SPACE character
    var spaceWidth: CGFloat {
        
        return self.advancement(character: " ").width
    }
    
    
    /**
     Calculate advancement of a character using CoreText.
     
     - parameters:
        - character: Character to calculate advancement.
     
     - returns: Advancement of passed-in character.
     */
    private func advancement(character: Character) -> NSSize {
        
        let attributedString = NSAttributedString(string: String(character), attributes: [.font: self])
        let line = CTLineCreateWithAttributedString(attributedString)
        
        guard
            let runs = CTLineGetGlyphRuns(line) as? [CTRun],
            let run = runs.first,
            CTRunGetGlyphCount(run) > 0
            else {
                assertionFailure("No glyph was created.")
                return .zero
            }
        
        var size = CGSize()
        CTRunGetAdvances(run, CFRange(location: 0, length: 1), &size)
        
        return size
    }
    
}
