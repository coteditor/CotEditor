//
//  ModeTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-07-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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
@testable import CotEditor

struct ModeTests {
    
    @Test func defaultSerialization() {
        
        let mode = ModeOptions()
        
        #expect(mode.dictionary.isEmpty)
        #expect(ModeOptions(dictionary: mode.dictionary) == mode)
    }
    
    
    @Test func serialization() {
        
        let mode = ModeOptions(
            fontType: .monospaced,
            automaticDashSubstitution: false,  // <- default value
            automaticTextReplacement: false,
            completionWordTypes: [.document, .syntax]
        )
        
        #expect(mode.dictionary == [
            "fontType": "monospaced",
            "automaticTextReplacement": false,
            "completionWordTypes": mode.completionWordTypes.rawValue,
        ])
        #expect(ModeOptions(dictionary: mode.dictionary) == mode)
    }
}
