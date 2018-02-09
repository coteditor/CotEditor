/*
 
 IncompatibleCharacter.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-28.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2018 1024jp
 
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
    
    @objc let character: String
    @objc let convertedCharacter: String
    @objc let location: Int
    @objc let lineNumber: Int
    
    
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
        
        return zip(self.indices, zip(self, convertedString))
            .filter { $1.0 != $1.1 }
            .map { (index, characters) -> IncompatibleCharacter in
                let (original, converted) = characters
                let location = index.samePosition(in: self.utf16)!.encodedOffset
                
                return IncompatibleCharacter(character: original,
                                             convertedCharacter: (original == "¥" && encoding.canConvertYenSign) ? "\\" : converted,
                                             location: location,
                                             lineNumber: self.lineNumber(at: location))
            }
    }
    
}
