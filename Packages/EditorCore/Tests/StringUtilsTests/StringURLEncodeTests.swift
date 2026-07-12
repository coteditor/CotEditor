//
//  StringURLEncodeTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-07-12.
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

import Testing
@testable import StringUtils

struct StringURLEncodeTests {
    
    @Test func encode() {
        
        #expect("a%20b%".urlPercentEncoded == "a%20b%25")
        #expect("100%".urlPercentEncoded == "100%25")
        #expect("a%20%2G".urlPercentEncoded == "a%20%252G")
        #expect("%41".urlPercentEncoded == "A")
        #expect("あ%20%".urlPercentEncoded == "%E3%81%82%20%25")
        #expect("AZaz09-._~ /".urlPercentEncoded == "AZaz09-._~%20%2F")
        #expect("".urlPercentEncoded.isEmpty)
        
        // encode a lone percent sign even beside a valid percent-encoded sequence
        #expect("%41 %".urlPercentEncoded == "A%20%25")
        // keep a valid multibyte sequence without double-encoding
        #expect("%E3%81%82".urlPercentEncoded == "%E3%81%82")
        // keep an undecodable but hex-formed sequence while still encoding the surroundings
        #expect("%FF test".urlPercentEncoded == "%FF%20test")
        #expect("50% off %FF x".urlPercentEncoded == "50%25%20off%20%FF%20x")
    }
}
