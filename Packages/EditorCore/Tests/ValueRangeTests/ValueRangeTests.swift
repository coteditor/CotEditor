//
//  ValueRangeTests.swift
//  ValueRangeTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-27.
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
@testable import ValueRange

struct ValueRangeTests {
    
    @Test func bounds() {
        
        let valueRange = ValueRange(value: "a", range: NSRange(location: 2, length: 4))
        
        #expect(valueRange.lowerBound == 2)
        #expect(valueRange.upperBound == 6)
    }
    
    
    @Test func shifted() {
        
        let original = ValueRange(value: "a", range: NSRange(location: 2, length: 4))
        let shifted = original.shifted(by: 3)
        
        #expect(shifted == ValueRange(value: "a", range: NSRange(location: 5, length: 4)))
        #expect(original == ValueRange(value: "a", range: NSRange(location: 2, length: 4)))
    }
    
    
    @Test func shift() {
        
        var valueRange = ValueRange(value: "a", range: NSRange(location: 2, length: 4))
        valueRange.shift(by: -1)
        
        #expect(valueRange == ValueRange(value: "a", range: NSRange(location: 1, length: 4)))
    }
    
    
    @Test func hashable() {
        
        let a = ValueRange(value: "a", range: NSRange(location: 2, length: 4))
        let sameAsA = ValueRange(value: "a", range: NSRange(location: 2, length: 4))
        let b = ValueRange(value: "b", range: NSRange(location: 2, length: 4))
        
        #expect(Set([a, sameAsA, b]).count == 2)
    }
}
