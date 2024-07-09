//
//  NSRangeTests.swift
//  EditedRangeSetTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-10.
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

import Foundation
import Testing
@testable import EditedRangeSet

struct NSRangeTests {
    
    @Test func union() throws {
        
        #expect([NSRange]().union == nil)
        #expect([NSRange(location: NSNotFound, length: 0)].union == nil)
        #expect([NSRange(0..<0)].union == NSRange(0..<0))
        #expect([NSRange(1..<1)].union == NSRange(1..<1))
        #expect([NSRange(1..<3)].union == NSRange(1..<3))
        
        #expect([NSRange(1..<3), NSRange(2..<4)].union == NSRange(1..<4))
        #expect([NSRange(1..<3), NSRange(5..<9)].union == NSRange(1..<9))
        #expect([NSRange(5..<9), NSRange(1..<3)].union == NSRange(1..<9))
        #expect([NSRange(5..<100), NSRange(1..<3), NSRange(2..<3)].union == NSRange(1..<100))
        #expect([NSRange(5..<9), NSRange(location: NSNotFound, length: 0), NSRange(1..<3)].union == NSRange(1..<9))
    }
}
