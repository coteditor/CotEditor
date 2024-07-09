//
//  IncompatibleCharacter.swift
//  FileEncoding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2024 1024jp
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

import Foundation.NSRange
import ValueRange

public struct IncompatibleCharacter: Equatable, Hashable, Sendable {
    
    public var character: Character
    public var converted: String?
    
    
    public init(character: Character, converted: String? = nil) {
        
        self.character = character
        self.converted = converted
    }
}


public extension String {
    
    /// Lists characters cannot be converted to the passed-in encoding.
    ///
    /// - Parameter encoding: The string encoding to test compatibility.
    /// - Returns: An array of IncompatibleCharacter.
    /// - Throws: `CancellationError`
    func charactersIncompatible(with encoding: String.Encoding) throws -> [ValueRange<IncompatibleCharacter>] {
        
        guard !self.canBeConverted(to: encoding) else { return [] }
        
        return try zip(self.indices, self).lazy
            .compactMap { (index, character) in
                try Task.checkCancellation()
                
                let string = String(character)
                let converted = string
                    .data(using: encoding, allowLossyConversion: true)
                    .flatMap { String(data: $0, encoding: encoding) }
                
                guard converted != string else { return nil }
                
                return ValueRange(value: IncompatibleCharacter(character: character, converted: converted),
                                  range: NSRange(location: index.utf16Offset(in: self), length: character.utf16.count))
            }
    }
}
