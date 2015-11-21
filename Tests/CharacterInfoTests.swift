/*

CharacterInfoTests.swift
Tests

CotEditor
http://coteditor.com

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

class CharacterInfoTests: XCTestCase {
    
    // MARK: - CEUnicodeCharacter Tests
    
    func testSingleChar() {
        let character = CEUnicodeCharacter(character: UTF32Char("あ"))
        
        XCTAssertEqual(CChar32(character.character), CChar32("あ"))
        XCTAssertEqual(character.unicode, "U+3042")
        XCTAssertEqual(character.string, "あ")
        XCTAssertFalse(character.surrogatePair)
        XCTAssertNil(character.surrogateUnicodes)
        XCTAssertEqual(character.name, "HIRAGANA LETTER A")
        XCTAssertEqual(character.categoryName, "Other Letter")
        XCTAssertEqual(character.blockName, "Hiragana")
        XCTAssertNotNil(character.localizedBlockName)
    }
    
    
    func testSurrogateEmoji() {
        let character = CEUnicodeCharacter(character: UTF32Char("😀"))
        
        XCTAssertEqual(CChar32(character.character), CChar32("😀"))
        XCTAssertEqual(character.unicode, "U+1F600")
        XCTAssertEqual(character.string, "😀")
        XCTAssertTrue(character.surrogatePair)
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
    
    
    // MARK: - CECharacterInfo Tests
    
    func testMultiCharString() {
        XCTAssertNil(CECharacterInfo(string: "foo"))
    }
    
    
    func testSingleCharWithVSInfo() {
        let charInfo = CECharacterInfo(string: "☺︎")
        
        XCTAssertEqual(charInfo!.string, "☺︎")
        XCTAssertFalse(charInfo!.complexChar)
        XCTAssertEqual(charInfo!.unicodes.map{$0.unicode}, ["U+263A", "U+FE0E"])
        XCTAssertEqual(charInfo!.unicodes.map{$0.name}, ["WHITE SMILING FACE", "VARIATION SELECTOR-15"])
        XCTAssertEqual(charInfo!.prettyDescription, "WHITE SMILING FACE (Text Style)")
    }
    
    
    func testCombiningCharacterInfo() {
        let charInfo = CECharacterInfo(string: "1️⃣")
        
        XCTAssertTrue(charInfo!.complexChar)
        XCTAssertEqual(charInfo!.unicodes.map{$0.unicode}, ["U+0031", "U+FE0F", "U+20E3"])
        XCTAssertEqual(charInfo!.prettyDescription, "<a letter consisting of 3 characters>")
    }

    
    func testNationalIndicatorInfo() {
        let charInfo = CECharacterInfo(string: "🇯🇵")
        
        XCTAssertTrue(charInfo!.complexChar)
        XCTAssertEqual(charInfo!.unicodes.map{$0.unicode}, ["U+1F1EF", "U+1F1F5"])
    }

}
