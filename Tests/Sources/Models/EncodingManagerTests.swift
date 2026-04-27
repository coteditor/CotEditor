//
//  EncodingManagerTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-27.
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
@testable import CotEditor

struct EncodingManagerTests {
    
    @Test func scriptableEncodingLookupIncludesUnlistedEncodings() throws {
        
        let localizedName = String.localizedName(of: .shiftJIS)
        
        #expect(EncodingManager.encoding(name: localizedName) == .shiftJIS)
        #expect(EncodingManager.encoding(ianaCharSetName: "iso-8859-2") == .isoLatin2)
    }
}
