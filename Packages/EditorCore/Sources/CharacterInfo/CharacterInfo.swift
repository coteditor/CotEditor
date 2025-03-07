//
//  CharacterInfo.swift
//  CharacterInfo
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2024 1024jp
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

public struct CharacterInfo: Sendable {
    
    // MARK: Public Properties
    
    public var character: Character
    
    
    // MARK: Public Methods
    
    public init(character: Character) {
        
        self.character = character
    }
    
    
    /// The representative character to display in the user interface.
    public var pictureCharacter: Character? {
        
        self.character.unicodeScalars.count == 1  // ignore CRLF
            ? self.character.unicodeScalars.first?.pictureRepresentation.map(Character.init)
            : nil
    }
    
    
    /// Whether the character consists with multiple Unicode scalars.
    public var isComplex: Bool {
        
        self.character.unicodeScalars.count > 1 && !self.isVariant
    }
    
    
    /// Whether the character is a single variant character.
    public var isVariant: Bool {
        
        (self.character.unicodeScalars.count == 2 &&
         self.character.unicodeScalars.last?.variantDescription != nil)
    }
}


extension CharacterInfo: CustomStringConvertible {
    
    public var description: String {
        
        String(self.character)
    }
}
