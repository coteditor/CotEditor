//
//  LineEndingTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2024 1024jp
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
import ValueRange
@testable import CotEditor

struct LineEndingTests {
    
    @Test func lineEnding() {
        
        #expect(LineEnding.lf.rawValue == "\n")
        #expect(LineEnding.crlf.rawValue == "\r\n")
        #expect(LineEnding.paragraphSeparator.rawValue == "\u{2029}")
    }
    
    
    @Test func name() {
        
        #expect(LineEnding.lf.label == "LF")
        #expect(LineEnding.crlf.label == "CRLF")
        #expect(LineEnding.paragraphSeparator.label == "PS")
    }
    
    
    @Test func lineEndingRanges() {
        
        let string = "\rfoo\r\nbar \n \nb \n\r uz\u{2029}moin\r\n"
        let expected: [ValueRange<LineEnding>] = [
            .init(value: .cr, location: 0),
            .init(value: .crlf, location: 4),
            .init(value: .lf, location: 10),
            .init(value: .lf, location: 12),
            .init(value: .lf, location: 15),
            .init(value: .cr, location: 16),
            .init(value: .paragraphSeparator, location: 20),
            .init(value: .crlf, location: 25),
        ]
        
        #expect("".lineEndingRanges().isEmpty)
        #expect("abc".lineEndingRanges().isEmpty)
        #expect(string.lineEndingRanges() == expected)
    }
    
    
    @Test func replace() {
        
        #expect("foo\r\nbar\n".replacingLineEndings(with: .cr) == "foo\rbar\r")
        #expect("foo\u{c}bar\n".replacingLineEndings(with: .cr) == "foo\u{c}bar\r")
    }
}



private extension ValueRange where Value == LineEnding {
    
    init(value: LineEnding, location: Int) {
        
        self.init(value: value, range: NSRange(location: location, length: value.length))
    }
}
