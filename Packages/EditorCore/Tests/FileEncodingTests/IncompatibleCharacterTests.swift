//
//  IncompatibleCharacterTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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

import Foundation
import Testing
import ValueRange
@testable import FileEncoding

struct IncompatibleCharacterTests {
    
    @Test func scanEmptyString() throws {
        
        let string = ""
        let incompatibles = try string.charactersIncompatible(with: .plainShiftJIS)
        
        #expect(incompatibles.isEmpty)
    }
    
    
    @Test func scanOnlyCompatibleCharacters() throws {
        
        let string = "Just ASCII text 12345."
        let incompatibles = try string.charactersIncompatible(with: .ascii)
        
        #expect(incompatibles.isEmpty)
    }
    
    
    @Test func scanIncompatibleCharacters() throws {
        
        let string = "abc\\ \n ¥ \n ~"
        let incompatibles = try string.charactersIncompatible(with: .plainShiftJIS)
        
        #expect(incompatibles.count == 2)
        
        let backslash = try #require(incompatibles.first)
        
        #expect(backslash.value.character == "\\")
        #expect(backslash.value.converted == "＼")
        #expect(backslash.lowerBound == 3)
        
        let tilde = incompatibles[1]
        
        #expect(tilde.value.character == "~")
        #expect(tilde.value.converted == "?")
        #expect(tilde.lowerBound == 11)
    }
    
    
    @Test func scanOnlyIncompatibleCharacters() throws {
        
        let string = "👾🐱‍👓"
        let incompatibles = try string.charactersIncompatible(with: .plainShiftJIS)
        
        #expect(incompatibles.count == string.count)
        for (offset, incompatible) in incompatibles.enumerated() {
            let index = string.index(string.startIndex, offsetBy: offset)
            #expect(incompatible.value.character == string[index])
            #expect(incompatible.value.converted != nil)
        }
    }
    
    
    @Test func scanSequentialIncompatibleCharacters() throws {
        
        let string = "~~"
        let incompatibles = try string.charactersIncompatible(with: .plainShiftJIS)
        
        #expect(incompatibles.count == 2)
        
        let tilde = incompatibles[1]
        
        #expect(tilde.value.character == "~")
        #expect(tilde.value.converted == "?")
        #expect(tilde.lowerBound == 1)
    }
    
    
    @Test func scanIncompatibleCharacterWithLengthShift() throws {
        
        let string = "family 👨‍👨‍👦 with 🐕"
        let incompatibles = try string.charactersIncompatible(with: .japaneseEUC)
        
        #expect(incompatibles.count == 2)
        
        #expect(incompatibles[0].value.character == "👨‍👨‍👦")
        #expect(incompatibles[0].value.converted == "????????")
        #expect(incompatibles[0].lowerBound == 7)
        
        #expect(incompatibles[1].value.character == "🐕")
        #expect(incompatibles[1].value.converted == "??")
        #expect(incompatibles[1].lowerBound == 21)
    }
    
    
    @Test func scanIncompatibleCharactersAtBounds() throws {
        
        let string = "🐶dog~"
        
        // "~" and "🐶" are incompatible in Shift_JIS
        let incompatibles = try string.charactersIncompatible(with: .plainShiftJIS)
        #expect(incompatibles.count == 2)
        #expect(incompatibles[0].lowerBound == 0)
        #expect(incompatibles[0].value.character == "🐶")
        #expect(incompatibles[1].lowerBound == 5)
        #expect(incompatibles[1].value.character == "~")
    }
    
    
    @Test func scanCombiningMarks() throws {
        
        let string = "e" + "\u{0301}"  // decomposed é
        let incompatibles = try string.charactersIncompatible(with: .ascii)
        
        // "e\u{0301}" as a character is not ASCII
        #expect(incompatibles.count == 1)
        #expect(incompatibles[0].value.character == string.first)
    }
    
    
    @Test func scanWithNilConverted() throws {
        
        let string = "\u{E000}" // Unicode Private Use Area (unrepresentable in ISO Latin 1)
        let incompatibles = try string.charactersIncompatible(with: .isoLatin1)
        
        #expect(incompatibles.count == 1)
        #expect(incompatibles[0].value.converted == "?")
    }
}


private extension String.Encoding {
    
    static let plainShiftJIS = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.shiftJIS.rawValue)))
}
