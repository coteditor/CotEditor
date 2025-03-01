//
//  UnicodeCharacterTests.swift
//  CharacterInfoTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2025 1024jp
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

struct UnicodeCharacterTests {
    
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
        
        // test DELETE (NSDeleteCharacter)
        let deleteCharacter = try #require(Unicode.Scalar(0x007f))
        let deletePictureCharacter = Unicode.Scalar("␡")
        #expect(deleteCharacter.name == "DELETE")
        #expect(deletePictureCharacter.name == "SYMBOL FOR DELETE")
        #expect(deleteCharacter.pictureRepresentation == deletePictureCharacter)
        
        // test one after the last C0 control character
        let exclamationCharacter = try #require(Unicode.Scalar(0x0021))
        #expect(exclamationCharacter.name == "EXCLAMATION MARK")
        #expect(exclamationCharacter.pictureRepresentation == nil)
    }
    
    
    @Test func blockNameLocalization() throws {
        
        let codeUnits: [Unicode.UTF32.CodeUnit] = [
            0x0000,
            0x0080,
            0x0100,
            0x0180,
            0x0250,
            0x02B0,
            0x0300,
            0x0370,
            0x0400,
            0x0500,
            0x0530,
            0x0590,
            0x0600,
            0x0700,
            0x0750,
            0x0780,
            0x07C0,
            0x0800,
            0x0840,
            0x0860,
            0x0870,
            0x08A0,
            0x0900,
            0x0980,
            0x0A00,
            0x0A80,
            0x0B00,
            0x0B80,
            0x0C00,
            0x0C80,
            0x0D00,
            0x0D80,
            0x0E00,
            0x0E80,
            0x0F00,
            0x1000,
            0x10A0,
            0x1100,
            0x1200,
            0x1380,
            0x13A0,
            0x1400,
            0x1680,
            0x16A0,
            0x1700,
            0x1720,
            0x1740,
            0x1760,
            0x1780,
            0x1800,
            0x18B0,
            0x1900,
            0x1950,
            0x1980,
            0x19E0,
            0x1A00,
            0x1A20,
            0x1AB0,
            0x1B00,
            0x1B80,
            0x1BC0,
            0x1C00,
            0x1C50,
            0x1C80,
            0x1C90,
            0x1CC0,
            0x1CD0,
            0x1D00,
            0x1D80,
            0x1DC0,
            0x1E00,
            0x1F00,
            0x2000,
            0x2070,
            0x20A0,
            0x20D0,
            0x2100,
            0x2150,
            0x2190,
            0x2200,
            0x2300,
            0x2400,
            0x2440,
            0x2460,
            0x2500,
            0x2580,
            0x25A0,
            0x2600,
            0x2700,
            0x27C0,
            0x27F0,
            0x2800,
            0x2900,
            0x2980,
            0x2A00,
            0x2B00,
            0x2C00,
            0x2C60,
            0x2C80,
            0x2D00,
            0x2D30,
            0x2D80,
            0x2DE0,
            0x2E00,
            0x2E80,
            0x2F00,
            0x2FF0,
            0x3000,
            0x3040,
            0x30A0,
            0x3100,
            0x3130,
            0x3190,
            0x31A0,
            0x31C0,
            0x31F0,
            0x3200,
            0x3300,
            0x3400,
            0x4DC0,
            0x4E00,
            0xA000,
            0xA490,
            0xA4D0,
            0xA500,
            0xA640,
            0xA6A0,
            0xA700,
            0xA720,
            0xA800,
            0xA830,
            0xA840,
            0xA880,
            0xA8E0,
            0xA900,
            0xA930,
            0xA960,
            0xA980,
            0xA9E0,
            0xAA00,
            0xAA60,
            0xAA80,
            0xAAE0,
            0xAB00,
            0xAB30,
            0xAB70,
            0xABC0,
            0xAC00,
            0xD7B0,
            0xD800,
            0xDB80,
            0xDC00,
            0xE000,
            0xF900,
            0xFB00,
            0xFB50,
            0xFE00,
            0xFE10,
            0xFE20,
            0xFE30,
            0xFE50,
            0xFE70,
            0xFF00,
            0xFFF0,
            0x10000,
            0x10080,
            0x10100,
            0x10140,
            0x10190,
            0x101D0,
            0x10280,
            0x102A0,
            0x102E0,
            0x10300,
            0x10330,
            0x10350,
            0x10380,
            0x103A0,
            0x10400,
            0x10450,
            0x10480,
            0x104B0,
            0x10500,
            0x10530,
            0x10570,
            0x105C0,
            0x10600,
            0x10780,
            0x10800,
            0x10840,
            0x10860,
            0x10880,
            0x108E0,
            0x10900,
            0x10920,
            0x10980,
            0x109A0,
            0x10A00,
            0x10A60,
            0x10A80,
            0x10AC0,
            0x10B00,
            0x10B40,
            0x10B60,
            0x10B80,
            0x10C00,
            0x10C80,
            0x10D00,
            0x10D40,
            0x10E60,
            0x10E80,
            0x10EC0,
            0x10F00,
            0x10F30,
            0x10F70,
            0x10FB0,
            0x10FE0,
            0x11000,
            0x11080,
            0x110D0,
            0x11100,
            0x11150,
            0x11180,
            0x111E0,
            0x11200,
            0x11280,
            0x112B0,
            0x11300,
            0x11380,
            0x11400,
            0x11480,
            0x11580,
            0x11600,
            0x11660,
            0x11680,
            0x116D0,
            0x11700,
            0x11800,
            0x118A0,
            0x11900,
            0x119A0,
            0x11A00,
            0x11A50,
            0x11AB0,
            0x11AC0,
            0x11B00,
            0x11BC0,
            0x11C00,
            0x11C70,
            0x11D00,
            0x11D60,
            0x11EE0,
            0x11F00,
            0x11FB0,
            0x11FC0,
            0x12000,
            0x12400,
            0x12480,
            0x12F90,
            0x13000,
            0x13430,
            0x13460,
            0x14400,
            0x16100,
            0x16800,
            0x16A40,
            0x16A70,
            0x16AD0,
            0x16B00,
            0x16D40,
            0x16E40,
            0x16F00,
            0x16FE0,
            0x17000,
            0x18800,
            0x18B00,
            0x18D00,
            0x1AFF0,
            0x1B000,
            0x1B100,
            0x1B130,
            0x1B170,
            0x1BC00,
            0x1BCA0,
            0x1CC00,
            0x1CF00,
            0x1D000,
            0x1D100,
            0x1D200,
            0x1D2C0,
            0x1D2E0,
            0x1D300,
            0x1D360,
            0x1D400,
            0x1D800,
            0x1DF00,
            0x1E000,
            0x1E030,
            0x1E100,
            0x1E290,
            0x1E2C0,
            0x1E4D0,
            0x1E5D0,
            0x1E7E0,
            0x1E800,
            0x1E900,
            0x1EC70,
            0x1ED00,
            0x1EE00,
            0x1F000,
            0x1F030,
            0x1F0A0,
            0x1F100,
            0x1F200,
            0x1F300,
            0x1F600,
            0x1F650,
            0x1F680,
            0x1F700,
            0x1F780,
            0x1F800,
            0x1F900,
            0x1FA00,
            0x1FA70,
            0x1FB00,
            0x20000,
            0x2A700,
            0x2B740,
            0x2B820,
            0x2CEB0,
            0x2EBF0,
            0x2F800,
            0x30000,
            0x31350,
            0xE0000,
            0xE0100,
            0xF0000,
            0x100000,
        ]
        
        for codeUnit in codeUnits {
            let blockName = try #require(codeUnit.blockName, "0x\(String(codeUnit, radix: 16, uppercase: true)) has no block name")
            let localized = try #require(localizeBlockName(blockName), "“\(blockName)” is not localized")
            #expect(!localized.isEmpty)
        }
    }
}
