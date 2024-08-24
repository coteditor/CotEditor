//
//  CollectionTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

struct CollectionTests {
    
    @Test func unique() {
        
        #expect([String]().uniqued.isEmpty)
        #expect(["dog"].uniqued == ["dog"])
        #expect(["dog", "dog", "cat", "cow", "cat", "dog"].uniqued == ["dog", "cat", "cow"])
    }
    
    
    @Test func compareCount() {
        
        #expect("".compareCount(with: 0) == .equal)
        #expect("".compareCount(with: 1) == .less)
        
        #expect("a".compareCount(with: 1) == .equal)
        #expect("🐕".compareCount(with: 1) == .equal)
        #expect("🐕‍🦺".compareCount(with: 1) == .equal)
        
        #expect("🐶🐱".compareCount(with: 3) == .less)
        #expect("🐶🐱".compareCount(with: 2) == .equal)
        #expect("🐶🐱".compareCount(with: 1) == .greater)
    }
}
