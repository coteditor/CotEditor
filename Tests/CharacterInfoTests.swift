/*
 
 CharacterInfoTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-11-19.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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

import XCTest
@testable import CotEditor

class CharacterInfoTests: XCTestCase {
    
    // MARK: UTF32Char Extension Tests
    
    func testSingleSurrogate() {
        
        let character = UTF32Char(0xD83D)
        
        XCTAssertEqual(character.unicodeName, "<lead surrogate-D83D>")
        XCTAssertEqual(character.categoryName, "Surrogate")
        XCTAssertEqual(character.blockName, "High Surrogates")
        
        XCTAssertNil(UnicodeScalar(codePoint: character))
    }
    
    
    
    // MARK: - UnicodeCharacter Tests
    
    func testSingleChar() {
        
        let character = UnicodeCharacter(character: UnicodeScalar("あ"))
        
        XCTAssertEqual(CChar32(character.character), CChar32("あ"))
        XCTAssertEqual(character.unicode, "U+3042")
        XCTAssertEqual(character.string, "あ")
        XCTAssertFalse(character.isSurrogatePair)
        XCTAssertNil(character.surrogateUnicodes)
        XCTAssertEqual(character.name, "HIRAGANA LETTER A")
        XCTAssertEqual(character.categoryName, "Other Letter")
        XCTAssertEqual(character.blockName, "Hiragana")
        XCTAssertNotNil(character.localizedBlockName)
    }
    
    
    func testSurrogateEmoji() {
        
        let character = UnicodeCharacter(character: UnicodeScalar("😀"))
        
        XCTAssertEqual(CChar32(character.character), CChar32("😀"))
        XCTAssertEqual(character.unicode, "U+1F600")
        XCTAssertEqual(character.string, "😀")
        XCTAssertTrue(character.isSurrogatePair)
        XCTAssertEqual(character.surrogateUnicodes!, ["U+D83D", "U+DE00"])
        XCTAssertEqual(character.name, "GRINNING FACE")
        XCTAssertEqual(character.categoryName, "Other Symbol")
        XCTAssertEqual(character.blockName, "Emoticons")
        XCTAssertNotNil(character.localizedBlockName)
    }
    
    
    func testUnicodeBlockNameWithHyphen() {
        
        let character = UnicodeCharacter(character: UnicodeScalar("﷽"))
        
        XCTAssertEqual(character.unicode, "U+FDFD")
        XCTAssertEqual(character.name, "ARABIC LIGATURE BISMILLAH AR-RAHMAN AR-RAHEEM")
        XCTAssertEqual(character.localizedBlockName, "Arabic Presentation Forms-A")
    }
    
    
    func testUnicodeControlPictures() {
        
        // test NULL
        let nullCharacter = UnicodeCharacter(character: UnicodeScalar(0x0000))
        let nullPictureCharacter = UnicodeCharacter(character: UnicodeScalar(0x2400))
        XCTAssertEqual(nullCharacter.name, "NULL")
        XCTAssertEqual(nullPictureCharacter.name, "SYMBOL FOR NULL")
        XCTAssertEqual(nullCharacter.pictureCharacter, nullPictureCharacter.character)
        
        // test SPACE
        let spaceCharacter = UnicodeCharacter(character: UnicodeScalar(0x0020))
        let spacePictureCharacter = UnicodeCharacter(character: UnicodeScalar(0x2420))
        XCTAssertEqual(spaceCharacter.name, "SPACE")
        XCTAssertEqual(spacePictureCharacter.name, "SYMBOL FOR SPACE")
        XCTAssertEqual(spaceCharacter.pictureCharacter, spacePictureCharacter.character)
        
        // test DELETE
        XCTAssertEqual(Int(ControlCharacter.deleteCharacter), NSDeleteCharacter)
        let deleteCharacter = UnicodeCharacter(character: UnicodeScalar(NSDeleteCharacter))
        let deletePictureCharacter = UnicodeCharacter(character: UnicodeScalar("␡"))
        XCTAssertEqual(deleteCharacter.name, "DELETE")
        XCTAssertEqual(deletePictureCharacter.name, "SYMBOL FOR DELETE")
        XCTAssertEqual(deleteCharacter.pictureCharacter, deletePictureCharacter.character)
        
        // test one after the last C0 control character
        let exclamationCharacter = UnicodeCharacter(character: UnicodeScalar(0x0021))
        XCTAssertEqual(exclamationCharacter.name, "EXCLAMATION MARK")
        XCTAssertNil(exclamationCharacter.pictureCharacter)
    }
    
    
    // MARK: - CharacterInfo Tests
    
    func testMultiCharString() {
        
        XCTAssertNil(CharacterInfo(string: "foo"))
    }
    
    
    func testSingleCharWithVSInfo() {
        
        guard let charInfo = CharacterInfo(string: "☺︎") else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(charInfo.string, "☺︎")
        XCTAssertFalse(charInfo.isComplex)
        XCTAssertEqual(charInfo.unicodes.map{ $0.unicode }, ["U+263A", "U+FE0E"])
        XCTAssertEqual(charInfo.unicodes.map{ $0.name }, ["WHITE SMILING FACE", "VARIATION SELECTOR-15"])
        XCTAssertEqual(charInfo.localizedDescription, "WHITE SMILING FACE (Text Style)")
    }
    
    
    func testCombiningCharacterInfo() {
        
        guard let charInfo = CharacterInfo(string: "1️⃣") else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(charInfo.isComplex)
        XCTAssertEqual(charInfo.unicodes.map{ $0.unicode }, ["U+0031", "U+FE0F", "U+20E3"])
        XCTAssertEqual(charInfo.localizedDescription, "<a letter consisting of 3 characters>")
    }
    
    
    func testNationalIndicatorInfo() {
        
        guard let charInfo = CharacterInfo(string: "🇯🇵") else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(charInfo.isComplex)
        XCTAssertEqual(charInfo.unicodes.map{ $0.unicode }, ["U+1F1EF", "U+1F1F5"])
    }
    
    
    func testControlCharacterInfo() {
        
        guard let charInfo = CharacterInfo(string: " ") else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(charInfo.string, " ")
        XCTAssertEqual(charInfo.pictureString, "␠")
        XCTAssertEqual(charInfo.unicodes.map{ $0.name }, ["SPACE"])
    }

}
