//
//  NSRangeClampedTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-16.
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
@testable import StringUtils

struct NSRangeClampedTests {
    
    @Test func shortLine() {
        
        // line shorter than maxLength -> returns self unchanged
        let line = NSRange(0..<500)
        let target = NSRange(200..<210)
        
        #expect(line.clamped(around: target, maxLength: 1024) == line)
    }
    
    
    @Test func longLine() {
        
        // line much longer than maxLength -> clamps around target
        let line = NSRange(0..<100_000)
        let target = NSRange(50_000..<50_010)
        let result = line.clamped(around: target, maxLength: 1024)
        
        #expect(result.length == 1024)
        #expect(result.location <= target.location)
        #expect(result.upperBound >= target.upperBound)
        // head padding should be 64 (default)
        #expect(target.location - result.location == 64)
    }
    
    
    @Test func nearLineStart() {
        
        // target near the start of line -> head padding is clamped to available space
        let line = NSRange(0..<100_000)
        let target = NSRange(20..<30)
        let result = line.clamped(around: target, maxLength: 1024)
        
        #expect(result.location == 0)
        #expect(result.length == 1024)
        #expect(result.upperBound >= target.upperBound)
    }
    
    
    @Test func nearLineEnd() {
        
        // target near the end of line -> end is clamped to line boundary
        let line = NSRange(0..<100_000)
        let target = NSRange(99_990..<100_000)
        let result = line.clamped(around: target, maxLength: 1024)
        
        #expect(result.upperBound == 100_000)
        #expect(result.location <= target.location)
        #expect(result.length <= 1024)
    }
    
    
    @Test func customHeadPadding() {
        
        let line = NSRange(0..<100_000)
        let target = NSRange(50_000..<50_010)
        let result = line.clamped(around: target, maxLength: 1024, headPadding: 16)
        
        #expect(result.length == 1024)
        #expect(target.location - result.location == 16)
    }
    
    
    @Test func nonZeroOrigin() {
        
        // line starting at non-zero location
        let line = NSRange(10_000..<110_000)
        let target = NSRange(60_000..<60_010)
        let result = line.clamped(around: target, maxLength: 1024)
        
        #expect(result.length == 1024)
        #expect(result.location >= line.location)
        #expect(result.upperBound <= line.upperBound)
        #expect(target.location - result.location == 64)
    }
}
