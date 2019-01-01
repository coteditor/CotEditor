//
//  NSLayoutManager+Range.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-21.
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

import AppKit

extension NSLayoutManager {
    
    /// calculate visual (wrapped) line range
    func lineFragmentRange(at charIndex: Int) -> NSRange {
        
        let glyphIndex = self.glyphIndexForCharacter(at: charIndex)
        var lineGlyphRange: NSRange = .notFound
        
        self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineGlyphRange, withoutAdditionalLayout: true)
        
        return self.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
    }
    
    
    /// return range of given attribute if the location is in it, otherwise nil.
    func effectiveRange(of attrName: NSAttributedString.Key, at location: Int, in range: NSRange? = nil) -> NSRange? {
        
        let range = range ?? NSRange(location: 0, length: self.attributedString().length)
        var effectiveRange = NSRange.notFound
        
        guard self.temporaryAttribute(attrName, atCharacterIndex: location, longestEffectiveRange: &effectiveRange, in: range) != nil else { return nil }
        
        return effectiveRange
    }
    
    
    /// enumerate range and value of given temporary attribute
    func enumerateTemporaryAttribute(_ attrName: NSAttributedString.Key, in range: NSRange, using block: (_ value: Any, _ range: NSRange, _ stop: inout Bool) -> Void) {
        
        var characterIndex = range.location
        while characterIndex < range.upperBound {
            var effectiveRange: NSRange = .notFound
            let value = self.temporaryAttribute(attrName, atCharacterIndex: characterIndex, longestEffectiveRange: &effectiveRange, in: range)
            
            if let value = value {
                var stop = false
                block(value, effectiveRange, &stop)
                
                guard !stop else { return }
            }
            
            characterIndex = effectiveRange.upperBound
        }
    }
    
    
    /// check if at least one temporary attribute for given attribute key exists
    func hasTemporaryAttribute(for attrName: NSAttributedString.Key) -> Bool {
        
        guard let storage = self.textStorage else { return false }
        
        var found = false
        self.enumerateTemporaryAttribute(attrName, in: NSRange(..<storage.length)) { (_, _, stop) in
            stop = true
            found = true
        }
        return found
    }
    
}
