//
//  FoundationTests.swift
//  FileEncodingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2026 1024jp
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

struct FoundationTests {
    
    /// Tests if the U+FEFF omitting bug on Swift 5 still exists.
    @Test(.bug("https://bugs.swift.org/browse/SR-10896"))
    func feff() {
        
        let bom = "\u{feff}"
        #expect(bom.count == 1)
        #expect(("\(bom)abc").count == 4)
        
        #expect(NSString(string: "a\(bom)bc").length == 4)
        withKnownIssue {
            #expect(NSString(string: bom) as String == bom)
            #expect(NSString(string: bom).length == 1)
            #expect(NSString(string: "\(bom)\(bom)").length == 2)
            #expect(NSString(string: "\(bom)abc").length == 4)
        }
        
        // -> These test cases must fail if the bug fixed.
        #expect(NSString(string: bom).length == 0)
        #expect(NSString(string: "\(bom)\(bom)").length == 1)
        #expect(NSString(string: "\(bom)abc").length == 3)
        
        let string = "\(bom)abc"
        
        // Implicit NSString cast is fixed.
        // -> However, still crashes when `string.immutable.enumerateSubstrings(in:)`
        let middleIndex = string.index(string.startIndex, offsetBy: 2)
        string.enumerateSubstrings(in: middleIndex..<string.endIndex, options: .byLines) { _, _, _, _ in }
    }
}
