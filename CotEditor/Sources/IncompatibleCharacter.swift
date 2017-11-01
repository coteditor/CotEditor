/*
 
 IncompatibleCharacter.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-28.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

import Foundation

final class IncompatibleCharacter: NSObject {  // -> inherit NSObject for NSArrayController
    
    let character: String
    let convertedCharacter: String
    let location: Int
    let lineNumber: Int
    
    
    required init(character: Character, convertedCharacter: Character, location: Int, lineNumber: Int) {
        
        self.character = String(character)
        self.convertedCharacter = String(convertedCharacter)
        self.location = location
        self.lineNumber = lineNumber
        
        super.init()
    }
    
    
    var range: NSRange {
        
        return NSRange(location: self.location, length: 1)
    }
    
    
    override var debugDescription: String {
        
        return "<\(self): \(self.character) -\(self.location)>"
    }
    
}



// MARK: -

extension String {
    
    /// list-up characters cannot be converted to the passed-in encoding
    func scanIncompatibleCharacters(for encoding: String.Encoding) -> [IncompatibleCharacter]? {
        
        guard
            let data = self.data(using: encoding, allowLossyConversion: true),
            let convertedString = String(data: data, encoding: encoding),
            convertedString.count == self.count else { return nil }
        
        // list-up characters to be converted/deleted
        var incompatibles = [IncompatibleCharacter]()
        let isInvalidYenEncoding = encoding.canConvertYenSign
        
        for (index, (character, convertedCharacter)) in zip(self, convertedString).enumerated() {
            
            guard character != convertedCharacter else { continue }
            
            let sanitizedConvertedCharacter: Character = {
                if isInvalidYenEncoding && character == "¥" {
                    return "\\"
                }
                return convertedCharacter
            }()
            
            let characterIndex = self.index(self.startIndex, offsetBy: index).samePosition(in: self.utf16)
            let location = characterIndex!.encodedOffset
            
            incompatibles.append(IncompatibleCharacter(character: character,
                                                       convertedCharacter: sanitizedConvertedCharacter,
                                                       location: location,
                                                       lineNumber: self.lineNumber(at: location)))
        }
        
        return incompatibles
    }
}
