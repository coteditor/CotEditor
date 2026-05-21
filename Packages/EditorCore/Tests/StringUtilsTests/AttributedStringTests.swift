//
//  AttributedStringTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
@testable import StringUtils

struct AttributedStringTests {
    
    @Test func truncatedHead() {
        
        let original = AttributedString("0123456")
        let index = original.characters.index(original.startIndex, offsetBy: 5)
        let truncated = original.truncatedHead(until: index, offset: 2)
        
        #expect(String(truncated.characters) == "…3456")
        #expect(String(original.characters) == "0123456")
    }
    
    
    @Test func truncateHead() {
        
        var string1 = AttributedString("0123456")
        let index1 = string1.characters.index(string1.startIndex, offsetBy: 5)
        string1.truncateHead(until: index1, offset: 2)
        #expect(String(string1.characters) == "…3456")
        
        var string2 = AttributedString("0123456")
        let index2 = string2.characters.index(string2.startIndex, offsetBy: 2)
        string2.truncateHead(until: index2, offset: 3)
        #expect(String(string2.characters) == "0123456")
        
        var string3 = AttributedString("🐈‍⬛🐕🐄")
        let index3 = string3.characters.index(string3.startIndex, offsetBy: 2)
        string3.truncateHead(until: index3, offset: 1)
        #expect(String(string3.characters) == "…🐕🐄")
    }
}
