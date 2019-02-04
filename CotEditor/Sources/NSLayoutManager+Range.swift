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
//  © 2018-2019 1024jp
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
        
        var range = self.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
        
        // strip last line ending character
        let lineEndingRange = (self.attributedString().string as NSString).rangeOfCharacter(from: .newlines, options: .backwards, range: range)
        range.length -= lineEndingRange.length
        
        return range
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



// MARK: - Bidi-Text Helpers

extension NSLayoutManager {
    
    /// Check the writing direction of the character.
    ///
    /// - Parameter index: The character index to check.
    /// - Returns: `true` when is right-to-left, otherwise `false`.
    func isRTL(at index: Int) -> Bool {
        
        let glyphIndex = self.glyphIndexForCharacter(at: index)
        
        guard glyphIndex < self.numberOfGlyphs else { return false }
        
        var bidiLevels: [UInt8] = [0]
        self.getGlyphs(in: NSRange(glyphIndex..<(glyphIndex + 1)), glyphs: nil, properties: nil, characterIndexes: nil, bidiLevels: &bidiLevels)
        
        return !bidiLevels[0].isMultiple(of: 2)
    }
    
    
    /// Return the character index of the left side of the given character index in display order.
    ///
    /// - Parameters:
    ///   - characterIndex: The character index of the origin character.
    ///   - baseWritingDirection: The base writing direction of the entire string to move index among lines.
    /// - Returns: Left character index.
    func leftCharacterIndex(of characterIndex: Int, baseWritingDirection: NSWritingDirection) -> Int {
        
        let characterIndexes = self.lineFragmentInsertionPointIndexes(forCharacterAt: characterIndex)
        
        guard let index = characterIndexes.firstIndex(of: characterIndex) else { assertionFailure(); return characterIndex }
        
        // -> The target is in the same fragment.
        if index > 0 { return characterIndexes[index - 1] }
        
        let string = self.attributedString().string as NSString
        
        switch baseWritingDirection {
        case .rightToLeft:
            return string.index(after: characterIndexes.max() ?? 0)
        default:
            return string.index(before: characterIndexes.min() ?? 0)
        }
    }
    
    
    /// Return the character index of the right side of the given character index in display order.
    ///
    /// - Parameters:
    ///   - characterIndex: The character index of the origin character.
    ///   - baseWritingDirection: The base writing direction of the entire string to move index among lines.
    /// - Returns: Right character index.
    func rightCharacterIndex(of characterIndex: Int, baseWritingDirection: NSWritingDirection) -> Int {
        
        let characterIndexes = self.lineFragmentInsertionPointIndexes(forCharacterAt: characterIndex)
        
        guard let index = characterIndexes.firstIndex(of: characterIndex) else { assertionFailure(); return characterIndex }
        
        // -> The target is in the same fragment.
        if index < characterIndexes.count - 1 { return characterIndexes[index + 1] }
        
        let string = self.attributedString().string as NSString
        
        switch baseWritingDirection {
        case .rightToLeft:
            return string.index(before: characterIndexes.min() ?? 0)
        default:
            return string.index(after: characterIndexes.max() ?? 0)
        }
    }
    
    
    /// Return the character indexes for the insertion points in the same line fragment of the given character index in display order.
    ///
    /// - Parameter characterIndex: The character index of one character within the line fragment.
    /// - Returns: An array contains character indexes in display order.
    private func lineFragmentInsertionPointIndexes(forCharacterAt characterIndex: Int) -> [Int] {
        
        let count = self.getLineFragmentInsertionPoints(forCharacterAt: characterIndex, alternatePositions: false, inDisplayOrder: true, positions: nil, characterIndexes: nil)
        var characterIndexes = [Int](repeating: 0, count: count)
        self.getLineFragmentInsertionPoints(forCharacterAt: characterIndex, alternatePositions: false, inDisplayOrder: true, positions: nil, characterIndexes: &characterIndexes)
        
        return characterIndexes
    }
    
}
