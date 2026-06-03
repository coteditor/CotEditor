//
//  Character.swift
//  CharacterInfo
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2026 1024jp
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

public extension Character {
    
    /// The representative character to display in the user interface.
    var pictureCharacter: Character? {
        
        self.unicodeScalars.count == 1  // ignore CRLF
            ? self.unicodeScalars.first?.pictureRepresentation.map(Character.init)
            : nil
    }
    
    
    /// Whether the character consists with multiple Unicode scalars.
    var isComplex: Bool {
        
        self.unicodeScalars.count > 1 && !self.isVariant
    }
    
    
    /// Whether the character is a single variant character.
    var isVariant: Bool {
        
        (self.unicodeScalars.count == 2 &&
         self.unicodeScalars.last?.variantDescription != nil)
    }
}
