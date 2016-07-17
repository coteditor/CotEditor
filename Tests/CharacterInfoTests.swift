/*
 
 CharacterInfoTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-11-19.
 
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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
    
    // MARK: - CEUnicodeCharacter Tests
    
    func testSingleChar() {
        let character = CEUnicodeCharacter(character: UTF32Char("あ"))
        
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
    
    
    func testSingleSurrogate() {
        let character = CEUnicodeCharacter(character: UTF32Char(0xD83D))
        
        XCTAssertEqual(character.unicode, "U+D83D")
        XCTAssertEqual(character.name, "<lead surrogate-D83D>")
        XCTAssertEqual(character.categoryName, "Surrogate")
        XCTAssertEqual(character.blockName, "High Surrogates")
    }
    
    
    func testSurrogateEmoji() {
        let character = CEUnicodeCharacter(character: UTF32Char("😀"))
        
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
        let character = CEUnicodeCharacter(character: UTF32Char("﷽"))
        
        XCTAssertEqual(character.unicode, "U+FDFD")
        XCTAssertEqual(character.name, "ARABIC LIGATURE BISMILLAH AR-RAHMAN AR-RAHEEM")
        XCTAssertEqual(character.localizedBlockName, "Arabic Presentation Forms-A")
    }
    
    
    func testUnicodeControlPictures() {
        // test NULL
        let nullCharacter = CEUnicodeCharacter(character: UTF32Char(0x0000))
        let nullPictureCharacter = CEUnicodeCharacter(character: UTF32Char(0x2400))
        XCTAssertEqual(nullCharacter.name, "NULL")
        XCTAssertEqual(nullPictureCharacter.name, "SYMBOL FOR NULL")
        XCTAssertEqual(nullCharacter.pictureCharacter, unichar(nullPictureCharacter.character))
        
        // test SPACE
        let spaceCharacter = CEUnicodeCharacter(character: UTF32Char(0x0020))
        let spacePictureCharacter = CEUnicodeCharacter(character: UTF32Char(0x2420))
        XCTAssertEqual(spaceCharacter.name, "SPACE")
        XCTAssertEqual(spacePictureCharacter.name, "SYMBOL FOR SPACE")
        XCTAssertEqual(spaceCharacter.pictureCharacter, unichar(spacePictureCharacter.character))
        
        // test DELETE
        XCTAssertEqual(Int(CEDeleteCharacter), NSDeleteCharacter)
        let deleteCharacter = CEUnicodeCharacter(character: UTF32Char(NSDeleteCharacter))
        let deletePictureCharacter = CEUnicodeCharacter(character: UTF32Char("␡"))
        XCTAssertEqual(deleteCharacter.name, "DELETE")
        XCTAssertEqual(deletePictureCharacter.name, "SYMBOL FOR DELETE")
        XCTAssertEqual(deleteCharacter.pictureCharacter, unichar(deletePictureCharacter.character))
        
        // test one after the last C0 control character
        let exclamationCharacter = CEUnicodeCharacter(character: UTF32Char(0x0021))
        XCTAssertEqual(exclamationCharacter.name, "EXCLAMATION MARK")
        XCTAssertEqual(exclamationCharacter.pictureCharacter, 0)
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
        XCTAssertEqual(charInfo.unicodes.map{$0.unicode}, ["U+263A", "U+FE0E"])
        XCTAssertEqual(charInfo.unicodes.map{$0.name}, ["WHITE SMILING FACE", "VARIATION SELECTOR-15"])
        XCTAssertEqual(charInfo.localizedDescription, "WHITE SMILING FACE (Text Style)")
    }
    
    
    func testCombiningCharacterInfo() {
        guard let charInfo = CharacterInfo(string: "1️⃣") else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(charInfo.isComplex)
        XCTAssertEqual(charInfo.unicodes.map{$0.unicode}, ["U+0031", "U+FE0F", "U+20E3"])
        XCTAssertEqual(charInfo.localizedDescription, "<a letter consisting of 3 characters>")
    }
    
    
    func testNationalIndicatorInfo() {
        guard let charInfo = CharacterInfo(string: "🇯🇵") else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(charInfo.isComplex)
        XCTAssertEqual(charInfo.unicodes.map{$0.unicode}, ["U+1F1EF", "U+1F1F5"])
    }
    
    
    func testControlCharacterInfo() {
        guard let charInfo = CharacterInfo(string: " ") else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(charInfo.string, " ")
        XCTAssertEqual(charInfo.pictureString, "␠")
        XCTAssertEqual(charInfo.unicodes.map{$0.name}, ["SPACE"])
    }

}
