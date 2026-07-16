//
//  StringNumberingTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-07-16.
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

struct StringNumberingTests {
    
    @Test func numberingComponents() {
        
        #expect(" ".numberingComponents == (" ", 1))
        #expect("1".numberingComponents == ("1", 1))
        #expect(" 1".numberingComponents == (" 1", 1))
        #expect("test".numberingComponents == ("test", 1))
        #expect("test 5".numberingComponents == ("test", 5))
        #expect("test copy".numberingComponents == ("test copy", 1))
        #expect("test copy 5".numberingComponents == ("test copy", 5))
    }
    
    
    @Test func appendingUniqueNumber() {
        
        let names = ["foo", "foo 3", "foo copy 3", "foo 4", "foo 7"]
        
        #expect("foo".appendingUniqueNumber(in: names) == "foo 2")
        #expect("foo 2".appendingUniqueNumber(in: names) == "foo 2")
        #expect("foo 3".appendingUniqueNumber(in: names) == "foo 5")
        #expect("foo".appendingUniqueNumber(in: names + ["foo 2", "foo 2"]) == "foo 5")
        
        #expect("foo".appendingUniqueNumber(in: []) == "foo")
    }
}
