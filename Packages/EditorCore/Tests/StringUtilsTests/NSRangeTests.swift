//
//  NSRangeTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-02-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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

struct NSRangeTests {
    
    @Test func touchBoundary() {
        
        #expect(NSRange(location: 2, length: 2).touches(NSRange(location: 4, length: 2)))
        #expect(NSRange(location: 2, length: 2).touches(NSRange(location: 0, length: 2)))
        
        #expect(NSRange(location: 2, length: 0).touches(NSRange(location: 2, length: 2)))
        #expect(NSRange(location: 2, length: 0).touches(NSRange(location: 0, length: 2)))
        #expect(NSRange(location: 2, length: 2).touches(NSRange(location: 2, length: 0)))
        #expect(NSRange(location: 2, length: 2).touches(NSRange(location: 4, length: 0)))
        
        #expect(NSRange(location: 2, length: 2).touches(2))
        #expect(NSRange(location: 2, length: 2).touches(4))
    }
    
    
    @Test func notFound() {
        
        #expect(NSRange.notFound.isNotFound)
        #expect(NSRange.notFound.isEmpty)
        #expect(NSRange(location: NSNotFound, length: 1).isNotFound)
        #expect(!NSRange(location: 1, length: 1).isNotFound)
    }
    
    
    @Test func insertRange() {
        
        #expect(NSRange(0..<0).inserted(items: []) == NSRange(0..<0))
        #expect(NSRange(0..<0).inserted(items: [.init(string: "", location: 0, forward: true)]) == NSRange(0..<0))
        
        #expect(NSRange(0..<0).inserted(items: [.init(string: "abc", location: 0, forward: true)]) == NSRange(3..<3))
        #expect(NSRange(0..<0).inserted(items: [.init(string: "abc", location: 0, forward: false)]) == NSRange(0..<0))
        #expect(NSRange(1..<1).inserted(items: [.init(string: "abc", location: 0, forward: false)]) == NSRange(4..<4))
        #expect(NSRange(0..<5).inserted(items: [.init(string: "abc", location: 2, forward: true)]) == NSRange(0..<8))
        #expect(NSRange(0..<5).inserted(items: [.init(string: "abc", location: 6, forward: true)]) == NSRange(0..<5))
        
        #expect(NSRange(2..<2).inserted(items: [.init(string: "abc", location: 2, forward: true),
                                                .init(string: "abc", location: 2, forward: false)]) == NSRange(5..<5))
        #expect(NSRange(2..<3).inserted(items: [.init(string: "abc", location: 2, forward: true),
                                                .init(string: "abc", location: 2, forward: false)]) == NSRange(2..<6))
        #expect(NSRange(2..<3).inserted(items: [.init(string: "abc", location: 3, forward: true),
                                                .init(string: "abc", location: 3, forward: false)]) == NSRange(2..<6))
    }
    
    
    @Test func removeRange() {
        
        #expect(NSRange(0..<0).removed(ranges: []) == NSRange(0..<0))
        #expect(NSRange(0..<0).removed(ranges: [NSRange(0..<0)]) == NSRange(0..<0))
        
        #expect(NSRange(0..<10).removed(ranges: [NSRange(2..<4)]) == NSRange(0..<8))
        #expect(NSRange(1..<10).removed(ranges: [NSRange(0..<2)]) == NSRange(0..<8))
        #expect(NSRange(1..<10).removed(ranges: [NSRange(11..<20)]) == NSRange(1..<10))
        
        #expect(NSRange(1..<10).removed(ranges: [NSRange(2..<4), NSRange(3..<5)]) == NSRange(1..<7))
        #expect(NSRange(1..<10).removed(ranges: [NSRange(0..<2), NSRange(3..<5), NSRange(9..<20)]) == NSRange(0..<5))
    }
}
