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
    
    func testMultiCharString() {
        XCTAssertNil(CECharacterInfo(string: "foo"))
    }
    
    
    func testSingleCharWithVS() {
        let charInfo = CECharacterInfo(string: "☺︎")
        
        XCTAssertEqual(charInfo!.unicodes, ["U+263A", "U+FE0E"])
        XCTAssertEqual(charInfo!.unicodeBlockName, "Miscellaneous Symbols")
    }
    
    
    func testUnicodeBlockNameWithHyphen() {
        let charInfo = CECharacterInfo(string: "﷽")
        
        XCTAssertEqual(charInfo!.unicodes, ["U+FDFD"])
        XCTAssertEqual(charInfo!.unicodeName, "ARABIC LIGATURE BISMILLAH AR-RAHMAN AR-RAHEEM")
        XCTAssertEqual(charInfo!.unicodeBlockName, "Arabic Presentation Forms-A")
    }
    
    
    func testSurrogateEmoji() {
        let charInfo = CECharacterInfo(string: "😀")
        
        XCTAssertEqual(charInfo!.unicodes, ["U+1F600 (U+D83D U+DE00)"])
        XCTAssertEqual(charInfo!.unicodeName, "GRINNING FACE")
        XCTAssertEqual(charInfo!.unicodeBlockName, "Emoticons")
    }
    
    
    func testCombiningCharacter() {
        let charInfo = CECharacterInfo(string: "1️⃣")
        
        XCTAssertEqual(charInfo!.unicodes, ["U+0031", "U+FE0F", "U+20E3"])
        XCTAssertEqual(charInfo!.unicodeName, "<a letter consisting of 3 characters>")
        XCTAssertNil(charInfo!.unicodeBlockName)
    }
    
    
    func testNationalIndicator() {
        let charInfo = CECharacterInfo(string: "🇯🇵")
        
        XCTAssertEqual(charInfo!.unicodes, ["U+1F1EF (U+D83C U+DDEF)", "U+1F1F5 (U+D83C U+DDF5)"])
    }

}
