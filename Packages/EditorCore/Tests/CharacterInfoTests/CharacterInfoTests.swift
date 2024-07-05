//
//  CharacterInfoTests.swift
//  CharacterInfoTests
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

import Testing
@testable import CharacterInfo

struct CharacterInfoTests {
    
    @Test func singleCharacterWithVSInfo() {
        
        let charInfo = CharacterInfo(character: "☺︎")
        
        #expect(charInfo.character == "☺︎")
        #expect(!charInfo.isComplex)
        #expect(charInfo.character.unicodeScalars.map(\.codePoint) == ["U+263A", "U+FE0E"])
        #expect(charInfo.character.unicodeScalars.map(\.name) == ["WHITE SMILING FACE", "VARIATION SELECTOR-15"])
    }
    
    
    @Test func combiningCharacterInfo() {
        
        let charInfo = CharacterInfo(character: "1️⃣")
        
        #expect(charInfo.isComplex)
        #expect(charInfo.character.unicodeScalars.map(\.codePoint) == ["U+0031", "U+FE0F", "U+20E3"])
    }
    
    
    @Test func nationalIndicatorInfo() {
        
        let charInfo = CharacterInfo(character: "🇯🇵")
        
        #expect(charInfo.isComplex)
        #expect(charInfo.character.unicodeScalars.map(\.codePoint) == ["U+1F1EF", "U+1F1F5"])
    }
    
    
    @Test func controlCharacterInfo() {
        
        let charInfo = CharacterInfo(character: " ")
        
        #expect(charInfo.character == " ")
        #expect(charInfo.pictureCharacter == "␠")
        #expect(charInfo.character.unicodeScalars.map(\.name) == ["SPACE"])
    }
}
