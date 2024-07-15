//
//  CollectionTests.swift
//  LineEndingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2024 1024jp
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
@testable import LineEnding

struct CollectionTests {
    
    @Test(arguments: 0..<10) func binarySearch(_: Int) {
        
        let array = (0..<20).map { _ in Int.random(in: 0..<100) }.sorted()
        
        for _ in 0..<10 {
            let index = Int.random(in: 0..<100)
            #expect(array.binarySearchedFirstIndex(where: { $0 > index }) ==
                    array.firstIndex(where: { $0 > index }))
        }
    }
    
    
    @Test func majorValue() {
        
        #expect("".lineEndingRanges().majorValue() == nil)
        #expect("a".lineEndingRanges().majorValue() == nil)
        #expect("\n".lineEndingRanges().majorValue() == .lf)
        #expect("\r".lineEndingRanges().majorValue() == .cr)
        #expect("\r\n".lineEndingRanges().majorValue() == .crlf)
        #expect("\u{85}".lineEndingRanges().majorValue() == .nel)
        #expect("abc\u{2029}def".lineEndingRanges().majorValue() == .paragraphSeparator)
        #expect("\rfoo\r\nbar\nbuz\u{2029}moin\r\n".lineEndingRanges().majorValue() == .crlf)
    }
}
