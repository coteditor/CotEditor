//
//  IncompatibleCharacter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2019 1024jp
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

import Foundation
import Differ

final class IncompatibleCharacter: NSObject {  // -> inherit NSObject for NSArrayController
    
    @objc let character: String
    @objc let convertedCharacter: String?
    @objc let location: Int
    @objc let lineNumber: Int
    
    
    required init(character: Character, convertedCharacter: String?, location: Int, lineNumber: Int) {
        
        self.character = String(character)
        self.convertedCharacter = convertedCharacter
        self.location = location
        self.lineNumber = lineNumber
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
    func scanIncompatibleCharacters(for encoding: String.Encoding) -> [IncompatibleCharacter] {
        
        guard !self.canBeConverted(to: encoding) else { return [] }
        
        guard
            let data = self.data(using: encoding, allowLossyConversion: true),  // lossy conversion must always success
            let convertedString = String(data: data, encoding: encoding)
            else { assertionFailure(); return [] }
        
        guard convertedString.count == self.count else {
            // detect incompatible chars using Differ
            return self.diff(convertedString)
                .compactMap { (element) -> Int? in
                    switch element {
                    case .delete(at: let offset): return offset
                    case .insert: return nil
                    }
                }
                .map { (offset) in
                    let index = self.index(self.startIndex, offsetBy: offset)
                    let location = NSRange(index..<index, in: self).location
                    let character = self[index]
                    let converted: String? = {
                        guard let data = String(character).data(using: encoding, allowLossyConversion: true) else { return nil }
                        
                        return String(data: data, encoding: encoding)
                    }()
                    
                    return IncompatibleCharacter(character: character,
                                                 convertedCharacter: converted,
                                                 location: location,
                                                 lineNumber: self.lineNumber(at: location))
                }
        }
        
        return zip(self.indices, zip(self, convertedString))
            .filter { $1.0 != $1.1 }
            .map { (index, characters) -> IncompatibleCharacter in
                let (original, converted) = characters
                let location = NSRange(index..<index, in: self).location
                
                return IncompatibleCharacter(character: original,
                                             convertedCharacter: (original == "¥" && encoding.canConvertYenSign) ? "\\" : String(converted),
                                             location: location,
                                             lineNumber: self.lineNumber(at: location))
            }
    }
    
}
