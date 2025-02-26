//
//  NormalizationTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-13.
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
@testable import StringUtils

struct NormalizationTests {
    
    @Test func normalize() {
        
        #expect("É \t 神 ㍑ ＡＢC".precomposedStringWithCompatibilityMappingWithCaseFold == "é \t 神 リットル abc")
        #expect("\u{1f71} \u{03b1}\u{0301}".precomposedStringWithHFSPlusMapping == "\u{1f71} \u{03ac}")
        #expect("\u{1f71}".precomposedStringWithHFSPlusMapping == "\u{1f71}")  // test single char
        #expect("\u{1f71}".decomposedStringWithHFSPlusMapping == "\u{03b1}\u{0301}")
    }
    
    
    @Test(arguments: UnicodeNormalizationForm.allCases) func normalize(form: UnicodeNormalizationForm) {
        
        #expect("".normalizing(in: form).isEmpty)
        #expect("abc".normalizing(in: form) == "abc")
        
        let normalized = "É \t 神 ㍑ ＡＢC".normalizing(in: form)
        switch form {
            case .nfd:
                #expect(normalized == "É \t 神 ㍑ ＡＢC")
            case .nfc:
                #expect(normalized == "É \t 神 ㍑ ＡＢC")
            case .nfkd:
                #expect(normalized == "É \t 神 リットル ABC")
            case .nfkc:
                #expect(normalized == "É \t 神 リットル ABC")
            case .nfkcCaseFold:
                #expect(normalized == "é \t 神 リットル abc")
            case .modifiedNFD:
                #expect(normalized == "É \t 神 ㍑ ＡＢC")
            case .modifiedNFC:
                #expect(normalized == "É \t 神 ㍑ ＡＢC")
        }
    }
}
