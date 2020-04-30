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
//  © 2015-2020 1024jp
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

import XCTest
@testable import CotEditor

final class CharacterInfoTests: XCTestCase {
    
    // MARK: UInt32 Extension Tests
    
    func testBlockNameTable() {
        
        // check comprehensiveness of block name table
        let keys = UInt32.blockNameTable.keys.sorted { $0.lowerBound < $1.lowerBound }
        XCTAssertEqual(zip(keys, keys.dropFirst()).count(where: { $0.0.upperBound + 1 != $0.1.lowerBound }), 20)
    }
    
    
    func testSingleSurrogate() {
        
        let character: UInt32 = 0xD83D
        
        XCTAssertEqual(character.unicodeName, "<lead surrogate-D83D>")
        XCTAssertEqual(character.blockName, "High Surrogates")
        
        XCTAssertNil(Unicode.Scalar(character))
    }
    
    
    func testUnicodeBlockNameLocalization() {
        
        let language = "ja"
        let bundleURL = Bundle.main.url(forResource: language, withExtension: "lproj")!
        let bundle = Bundle(url: bundleURL)!
        
        for blockName in UInt32.blockNameTable.values {
            let sanitizedBlockName = UInt32.appleUnicodeBlockName(for: blockName)
            let localizedBlockName = sanitizedBlockName.localized(tableName: "Unicode", bundle: bundle)
            
            XCTAssertNotEqual(localizedBlockName, blockName)
        }
    }
    
    
    // MARK: - UnicodeCharacter Tests
    
    func testSingleChar() {
        
        let unicode = Unicode.Scalar("あ")
        XCTAssertEqual(unicode.codePoint, "U+3042")
        XCTAssertFalse(unicode.isSurrogatePair)
        XCTAssertNil(unicode.surrogateCodePoints)
        XCTAssertEqual(unicode.name, "HIRAGANA LETTER A")
        XCTAssertEqual(unicode.blockName, "Hiragana")
        XCTAssertNotNil(unicode.localizedBlockName)
    }
    
    
    func testSurrogateEmoji() {
        
        let unicode = Unicode.Scalar("😀")
        
        XCTAssertEqual(unicode.codePoint, "U+1F600")
        XCTAssertTrue(unicode.isSurrogatePair)
        XCTAssertEqual(unicode.surrogateCodePoints!, ["U+D83D", "U+DE00"])
        XCTAssertEqual(unicode.name, "GRINNING FACE")
        XCTAssertEqual(unicode.blockName, "Emoticons")
        XCTAssertNotNil(unicode.localizedBlockName)
    }
    
    
    func testUnicodeBlockNameWithHyphen() {
        
        let character = Unicode.Scalar("﷽")
        
        XCTAssertEqual(character.codePoint, "U+FDFD")
        XCTAssertEqual(character.name, "ARABIC LIGATURE BISMILLAH AR-RAHMAN AR-RAHEEM")
        XCTAssertEqual(character.localizedBlockName, "Arabic Presentation Forms-A")
    }
    
    
    func testUnicodeControlPictures() {
        
        // test NULL
        let nullCharacter = Unicode.Scalar(0x0000)!
        let nullPictureCharacter = Unicode.Scalar(0x2400)!
        XCTAssertEqual(nullCharacter.name, "NULL")
        XCTAssertEqual(nullPictureCharacter.name, "SYMBOL FOR NULL")
        XCTAssertEqual(nullCharacter.pictureRepresentation, nullPictureCharacter)
        
        // test SPACE
        let spaceCharacter = Unicode.Scalar(0x0020)!
        let spacePictureCharacter = Unicode.Scalar(0x2420)!
        XCTAssertEqual(spaceCharacter.name, "SPACE")
        XCTAssertEqual(spacePictureCharacter.name, "SYMBOL FOR SPACE")
        XCTAssertEqual(spaceCharacter.pictureRepresentation, spacePictureCharacter)
        
        // test DELETE
        let deleteCharacter = Unicode.Scalar(NSDeleteCharacter)!
        let deletePictureCharacter = Unicode.Scalar("␡")
        XCTAssertEqual(deleteCharacter.name, "DELETE")
        XCTAssertEqual(deletePictureCharacter.name, "SYMBOL FOR DELETE")
        XCTAssertEqual(deleteCharacter.pictureRepresentation, deletePictureCharacter)
        
        // test one after the last C0 control character
        let exclamationCharacter = Unicode.Scalar(0x0021)!
        XCTAssertEqual(exclamationCharacter.name, "EXCLAMATION MARK")
        XCTAssertNil(exclamationCharacter.pictureRepresentation)
    }
    
    
    // MARK: - CharacterInfo Tests
    
    func testMultiCharString() {
        
        XCTAssertThrowsError(try CharacterInfo(string: "foo"))
    }
    
    
    func testSingleCharWithVSInfo() throws {
        
        let charInfo = try CharacterInfo(string: "☺︎")
        
        XCTAssertEqual(charInfo.string, "☺︎")
        XCTAssertFalse(charInfo.isComplex)
        XCTAssertEqual(charInfo.string.unicodeScalars.map(\.codePoint), ["U+263A", "U+FE0E"])
        XCTAssertEqual(charInfo.string.unicodeScalars.map(\.name!), ["WHITE SMILING FACE", "VARIATION SELECTOR-15"])
        XCTAssertEqual(charInfo.localizedDescription, "WHITE SMILING FACE (Text Style)")
    }
    
    
    func testCombiningCharacterInfo() throws {
        
        let charInfo = try CharacterInfo(string: "1️⃣")
        
        XCTAssertTrue(charInfo.isComplex)
        XCTAssertEqual(charInfo.string.unicodeScalars.map(\.codePoint), ["U+0031", "U+FE0F", "U+20E3"])
        XCTAssertEqual(charInfo.localizedDescription, "<a letter consisting of 3 characters>")
    }
    
    
    func testNationalIndicatorInfo() throws {
        
        let charInfo = try CharacterInfo(string: "🇯🇵")
        
        XCTAssertTrue(charInfo.isComplex)
        XCTAssertEqual(charInfo.string.unicodeScalars.map(\.codePoint), ["U+1F1EF", "U+1F1F5"])
    }
    
    
    func testControlCharacterInfo() throws {
        
        let charInfo = try CharacterInfo(string: " ")
        
        XCTAssertEqual(charInfo.string, " ")
        XCTAssertEqual(charInfo.pictureString, "␠")
        XCTAssertEqual(charInfo.string.unicodeScalars.map(\.name!), ["SPACE"])
    }
    
}
