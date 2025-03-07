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
//  © 2016-2024 1024jp
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
@testable import FileEncoding

struct IncompatibleCharacterTests {
    
    @Test func scanIncompatibleCharacter() throws {
        
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
}


private extension String.Encoding {
    
    static let plainShiftJIS = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.shiftJIS.rawValue)))
}
