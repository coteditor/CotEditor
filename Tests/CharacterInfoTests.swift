//
//  CharacterInfoTests.swift
//  Tests
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

import AppKit
import Testing
@testable import CotEditor

struct CharacterInfoTests {
    
    // MARK: UTF32.CodeUnit Extension Tests
    
    @Test func singleSurrogate() {
        
        let character: UTF32.CodeUnit = 0xD83D
        
        #expect(character.unicodeName == "<lead surrogate-D83D>")
        #expect(character.blockName == "High Surrogates")
        
        #expect(Unicode.Scalar(character) == nil)
    }
    
    
    // MARK: - UnicodeCharacter Tests
    
    @Test func singleChar() {
        
        let unicode = Unicode.Scalar("あ")
        #expect(unicode.codePoint == "U+3042")
        #expect(!unicode.isSurrogatePair)
        #expect(unicode.surrogateCodePoints == nil)
        #expect(unicode.name == "HIRAGANA LETTER A")
        #expect(unicode.blockName == "Hiragana")
        #expect(unicode.localizedBlockName != nil)
    }
    
    
    @Test func surrogateEmoji() {
        
        let unicode = Unicode.Scalar("😀")
        
        #expect(unicode.codePoint == "U+1F600")
        #expect(unicode.isSurrogatePair)
        #expect(unicode.surrogateCodePoints?.lead == "U+D83D")
        #expect(unicode.surrogateCodePoints?.trail == "U+DE00")
        #expect(unicode.name == "GRINNING FACE")
        #expect(unicode.blockName == "Emoticons")
        #expect(unicode.localizedBlockName != nil)
    }
    
    
    @Test func unicodeBlockNameWithHyphen() {
        
        let character = Unicode.Scalar("﷽")
        
        #expect(character.codePoint == "U+FDFD")
        #expect(character.name == "ARABIC LIGATURE BISMILLAH AR-RAHMAN AR-RAHEEM")
        #expect(character.localizedBlockName == "Arabic Presentation Forms-A")
    }
    
    
    @Test func unicodeControlPictures() throws {
        
        // test NULL
        let nullCharacter = try #require(Unicode.Scalar(0x0000))
        let nullPictureCharacter = try #require(Unicode.Scalar(0x2400))
        #expect(nullCharacter.name == "NULL")
        #expect(nullPictureCharacter.name == "SYMBOL FOR NULL")
        #expect(nullCharacter.pictureRepresentation == nullPictureCharacter)
        
        // test SPACE
        let spaceCharacter = try #require(Unicode.Scalar(0x0020))
        let spacePictureCharacter = try #require(Unicode.Scalar(0x2420))
        #expect(spaceCharacter.name == "SPACE")
        #expect(spacePictureCharacter.name == "SYMBOL FOR SPACE")
        #expect(spaceCharacter.pictureRepresentation == spacePictureCharacter)
        
        // test DELETE
        let deleteCharacter = try #require(Unicode.Scalar(NSDeleteCharacter))
        let deletePictureCharacter = Unicode.Scalar("␡")
        #expect(deleteCharacter.name == "DELETE")
        #expect(deletePictureCharacter.name == "SYMBOL FOR DELETE")
        #expect(deleteCharacter.pictureRepresentation == deletePictureCharacter)
        
        // test one after the last C0 control character
        let exclamationCharacter = try #require(Unicode.Scalar(0x0021))
        #expect(exclamationCharacter.name == "EXCLAMATION MARK")
        #expect(exclamationCharacter.pictureRepresentation == nil)
    }
    
    
    // MARK: - CharacterInfo Tests
    
    @Test func singleCharacterWithVSInfo() {
        
        let charInfo = CharacterInfo(character: "☺︎")
        
        #expect(charInfo.character == "☺︎")
        #expect(!charInfo.isComplex)
        #expect(charInfo.character.unicodeScalars.map(\.codePoint) == ["U+263A", "U+FE0E"])
        #expect(charInfo.character.unicodeScalars.map(\.name) == ["WHITE SMILING FACE", "VARIATION SELECTOR-15"])
        #expect(charInfo.localizedDescription == "WHITE SMILING FACE (Text Style)")
    }
    
    
    @Test func combiningCharacterInfo() {
        
        let charInfo = CharacterInfo(character: "1️⃣")
        
        #expect(charInfo.isComplex)
        #expect(charInfo.character.unicodeScalars.map(\.codePoint) == ["U+0031", "U+FE0F", "U+20E3"])
        #expect(charInfo.localizedDescription == "<a letter consisting of 3 characters>")
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
