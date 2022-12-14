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
//  © 2014-2022 1024jp
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

struct IncompatibleCharacter: Equatable {
    
    let character: Character
    let convertedCharacter: String?
    let location: Int
    
    var range: NSRange  { NSRange(location: self.location, length: self.character.utf16.count) }
}



// MARK: -

extension String {
    
    /// list-up characters cannot be converted to the passed-in encoding
    ///
    /// - Throws: `CancellationError`
    func scanIncompatibleCharacters(with encoding: String.Encoding) throws -> [IncompatibleCharacter] {
        
        guard !self.canBeConverted(to: encoding) else { return [] }
        
        guard
            let data = self.data(using: encoding, allowLossyConversion: true),  // lossy conversion must always success
            let convertedString = String(data: data, encoding: encoding)
        else { assertionFailure(); return [] }
        
        try Task.checkCancellation()
        
        if self.length == convertedString.length, self.length > 10_000 {
            return try self.quickIncompatibleFind(with: convertedString)
        }
        
        return try convertedString.difference(from: self).removals.lazy
            .map { (change) in
                guard case let .remove(offset, character, _) = change else { preconditionFailure() }
                
                try Task.checkCancellation()
                
                let converted: String? = String(character)
                    .data(using: encoding, allowLossyConversion: true)
                    .flatMap { String(data: $0, encoding: encoding) }
                let location = self.index(self.startIndex, offsetBy: offset).utf16Offset(in: self)
                
                return IncompatibleCharacter(character: character,
                                             convertedCharacter: converted,
                                             location: location)
            }
    }
    
    
    
    // MARK: Private Methods
    
    private func quickIncompatibleFind(with convertedString: String) throws -> [IncompatibleCharacter] {
        
        try zip(self, convertedString).enumerated().lazy
            .filter { $1.0 != $1.1 }
            .map { (offset, characters) in
                let location = self.index(self.startIndex, offsetBy: offset).utf16Offset(in: self)
                
                try Task.checkCancellation()
                
                return IncompatibleCharacter(character: characters.0,
                                             convertedCharacter: String(characters.1),
                                             location: location)
            }
    }
}
