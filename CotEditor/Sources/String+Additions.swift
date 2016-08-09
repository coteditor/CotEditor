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
