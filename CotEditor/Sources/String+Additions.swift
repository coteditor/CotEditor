/*
 
 String+Additions.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-27.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

import Foundation

extension String {
    
    /// range of the line containing a given index
    func lineRange(at index: Index) -> Range<Index> {
        
        return self.lineRange(for: index..<index)
    }
    
    
    /// line range adding ability to exclude last line ending character if exists
    func lineRange(for range: Range<Index>, excludingLastLineEnding: Bool) -> Range<Index> {
        
        let lineRange = self.lineRange(for: range)
        
        guard excludingLastLineEnding,
            let index = self.index(lineRange.upperBound, offsetBy: -1, limitedBy: lineRange.lowerBound),
            self.characters[index] == "\n" else { return lineRange }
        
        return lineRange.lowerBound..<self.index(before: lineRange.upperBound)
    }
    
    
    /**
     Find the range in the String of the character sequence of a given character set contains a given index found in a given range.
     
     - parameter aSet:   A character set to find.
     - parameter index:  The index of character to be contained to the result range. `index` must be within `aRange`.
     - parameter aRange: The range in which to search. `aRange` must not exceed the bounds of the receiver.
     
     - returns: The range in the receiver of the first character found from aSet within aRange. Or `nil` if none of the characters in `aSet` are found.
     */
    func rangeOfCharacters(from aSet: CharacterSet, at index: Index, range aRange: Range<Index>? = nil) -> Range<Index>? {
        
        let range = aRange ?? self.startIndex..<self.endIndex
        
        guard range.contains(index) else { return nil }
        
        let characterSet = aSet.inverted
        
        let lowerBound = self.rangeOfCharacter(from: characterSet, options: .backwards, range: range.lowerBound..<index)?.upperBound ?? range.lowerBound
        let upperBound = self.rangeOfCharacter(from: characterSet, range: index..<range.upperBound)?.lowerBound ?? range.upperBound
        
        return lowerBound..<upperBound
    }
    
    
    /// check if character at the location in UTF16 is escaped with backslash
    func isCharacterEscaped(at location: Int) -> Bool {
        
        guard let locationIndex = String.UTF16Index(location).samePosition(in: self) else { return false }
        
        return self.isCharacterEscaped(at: locationIndex)
    }
    
    
    /// check if character at the index is escaped with backslash
    func isCharacterEscaped(at index: Index) -> Bool {
        
        let MaxEscapesCheckLength = 8
        let startIndex = self.index(index, offsetBy: -MaxEscapesCheckLength, limitedBy: self.startIndex) ?? self.startIndex
        let seekCharacters = self.characters[startIndex..<index]
        
        var numberOfEscapes = 0
        for character in seekCharacters.reversed() {
            guard character == "\\" else { break }
            
            numberOfEscapes += 1
        }
        
        return (numberOfEscapes % 2 == 1)
    }
    
}
