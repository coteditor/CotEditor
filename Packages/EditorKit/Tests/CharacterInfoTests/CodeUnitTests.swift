//
//  CodeUnitTests.swift
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

struct CodeUnitTests {
    
    @Test func singleSurrogate() {
        
        let character: UTF32.CodeUnit = 0xD83D
        
        #expect(character.unicodeName == "<lead surrogate-D83D>")
        #expect(character.blockName == "High Surrogates")
        
        #expect(Unicode.Scalar(character) == nil)
    }
}
