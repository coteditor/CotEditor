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
//  © 2020-2024 1024jp
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
@testable import LineEnding

struct LazyLineEndingCachingTests {
    
    private let repeatCount = 20
    
    
    @Test func calculateLineNumber() {
        
        let counter = LineCounter(string: "dog \n\n cat \n cow \n")
        #expect(counter.lineNumber(at: 0) == 1)
        #expect(counter.lineNumber(at: 1) == 1)
        #expect(counter.lineNumber(at: 4) == 1)
        #expect(counter.lineNumber(at: 5) == 2)
        #expect(counter.lineNumber(at: 6) == 3)
        #expect(counter.lineNumber(at: 11) == 3)
        #expect(counter.lineNumber(at: 12) == 4)
        #expect(counter.lineNumber(at: 17) == 4)
        #expect(counter.lineNumber(at: 18) == 5)
        
        let counter2 = LineCounter(string: "dog \n\n cat \n cow ")
        #expect(counter2.lineNumber(at: 17) == 4)
        
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
        
        let counter = LineCounter(string: "dog \n\n cat \n cow \n")
        #expect(counter.lineRange(at: 0) == NSRange(0..<5))
        #expect(counter.lineRange(at: 1) == NSRange(0..<5))
        #expect(counter.lineRange(at: 4) == NSRange(0..<5))
        #expect(counter.lineRange(at: 5) == NSRange(5..<6))
        #expect(counter.lineRange(at: 6) == NSRange(6..<12))
        #expect(counter.lineRange(at: 11) == NSRange(6..<12))
        #expect(counter.lineRange(at: 12) == NSRange(12..<18))
        #expect(counter.lineRange(at: 17) == NSRange(12..<18))
        #expect(counter.lineRange(at: 18) == NSRange(18..<18))
        
        let counter2 = LineCounter(string: "dog \n\n cat \n cow ")
        #expect(counter2.lineRange(at: 17) == NSRange(12..<17))
        
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
        
        let counter = LineCounter(string: "dog \n\n cat \n cow")
        #expect(counter.lineContentsRange(for: NSRange(0..<3)) == NSRange(0..<4))
        #expect(counter.lineContentsRange(for: NSRange(4..<6)) == NSRange(0..<5))
        #expect(counter.lineContentsRange(for: NSRange(5..<6)) == NSRange(5..<5))
        #expect(counter.lineContentsRange(for: NSRange(7..<13)) == NSRange(6..<16))

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
}
