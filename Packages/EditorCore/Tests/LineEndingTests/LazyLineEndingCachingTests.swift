//
//  LazyLineEndingCachingTests.swift
//  LineEndingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2026 1024jp
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
import StringUtils
@testable import LineEnding

struct LazyLineEndingCachingTests {
    
    private let repeatCount = 20
    
    
    @Test func calculateLineNumber() {
        
        for _ in 0..<self.repeatCount {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let counter = LineCounter(string: string)
            
            for index in (0...string.length).shuffled() {
                let result = (string as NSString).lineNumber(at: index)
                #expect(counter.lineNumber(at: index) == result,
                        "At \(index) with string \"\(string)\"")
            }
        }
    }
    
    
    @Test func calculateIndexToLineRange() {
        
        for _ in 0..<self.repeatCount {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let counter = LineCounter(string: string)
            
            for index in (0...string.length).shuffled() {
                let result = (string as NSString).lineRange(at: index)
                #expect(counter.lineRange(at: index) == result,
                        "At \(index) with string \"\(string)\"")
                #expect(counter.lineStartIndex(at: index) == result.lowerBound,
                        "At \(index) with string \"\(string)\"")
            }
        }
    }
    
    
    @Test func lineContentsRange() throws {
        
        for _ in 0..<self.repeatCount {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let counter = LineCounter(string: string)
            
            for index in (0...string.length).shuffled() {
                let endIndex = try #require((index...string.length).randomElement())
                let range = NSRange(index..<endIndex)
                let result = (string as NSString).lineContentsRange(for: range)
                
                #expect(counter.lineContentsRange(for: range) == result,
                        "At \(index) with string \"\(string)\"")
            }
        }
    }
    
    
    @Test func mixedLineEndings() {
        
        let string = "a\r\nb\nc\rd\u{2028}e\u{2029}f\u{0085}g"
        let counter = LineCounter(string: string)
        let nsString = string as NSString
        
        for index in 0...string.length {
            // skip the CRLF gap (LF side) where we don't request line numbers in practice
            guard index == 0
                    || nsString.character(at: index - 1) != 0x0D
                    || nsString.character(at: index) != 0x0A
            else { continue }
            
            #expect(counter.lineNumber(at: index) == nsString.lineNumber(at: index),
                    "At \(index) with string \"\(string)\"")
            #expect(counter.lineRange(at: index) == nsString.lineRange(at: index),
                    "At \(index) with string \"\(string)\"")
            #expect(counter.lineStartIndex(at: index) == nsString.lineStartIndex(at: index),
                    "At \(index) with string \"\(string)\"")
        }
    }
}
