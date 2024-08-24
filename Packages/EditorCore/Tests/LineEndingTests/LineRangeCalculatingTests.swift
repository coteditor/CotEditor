//
//  LineRangeCalculatingTests.swift
//  LineEndingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-13.
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
import StringUtils
import ValueRange
@testable import LineEnding

struct LineRangeCalculatingTests {
    
    @Suite struct LineNumberTests {
        
        @Test func empty() {
            
            let calculator = Calculator(string: "")
            
            #expect(calculator.lineNumber(at: 0) == 1)
        }
        
        
        @Test func singleLineEnding() {
            
            let calculator = Calculator(string: "\r\n")
            
            #expect(calculator.lineNumber(at: 0) == 1)
            #expect(calculator.lineNumber(at: 1) == 1)
            #expect(calculator.lineNumber(at: 2) == 2)
        }
        
        
        @Test func multiLines() {
            
            let calculator = Calculator(string: "dog \n\n cat \n cow \n")
            
            #expect(calculator.lineNumber(at: 0) == 1)
            #expect(calculator.lineNumber(at: 1) == 1)
            #expect(calculator.lineNumber(at: 4) == 1)
            #expect(calculator.lineNumber(at: 5) == 2)
            #expect(calculator.lineNumber(at: 6) == 3)
            #expect(calculator.lineNumber(at: 11) == 3)
            #expect(calculator.lineNumber(at: 12) == 4)
            #expect(calculator.lineNumber(at: 17) == 4)
            #expect(calculator.lineNumber(at: 18) == 5)
        }
        
        
        @Test func random() {
            
            for _ in 0..<10 {
                let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
                let calculator = Calculator(string: string)
                
                for index in (0..<string.utf16.count).shuffled() {
                    #expect(calculator.lineNumber(at: index) == string.lineNumber(at: index))
                }
            }
        }
    }
    
    
    @Suite struct LineRangeTests {
        
        @Test func empty() {
            
            let calculator = Calculator(string: "")
            
            #expect(calculator.lineStartIndex(at: 0) == 0)
            #expect(calculator.lineRange(at: 0) == NSRange(0..<0))
        }
        
        
        @Test func singleLineEnding() {
            
            let calculator = Calculator(string: "\r\n")
            
            #expect(calculator.lineRange(at: 0) == NSRange(0..<2))
            #expect(calculator.lineRange(at: 1) == NSRange(0..<2))
            #expect(calculator.lineRange(at: 2) == NSRange(2..<2))
        }
        
        
        @Test func multiLines() {
            
            let calculator = Calculator(string: "dog \n\n cat \n cow \n")
            
            #expect(calculator.lineRange(at: 0) == NSRange(0..<5))
            #expect(calculator.lineRange(at: 1) == NSRange(0..<5))
            #expect(calculator.lineRange(at: 4) == NSRange(0..<5))
            #expect(calculator.lineRange(at: 5) == NSRange(5..<6))
            #expect(calculator.lineRange(at: 6) == NSRange(6..<12))
            #expect(calculator.lineRange(at: 11) == NSRange(6..<12))
            #expect(calculator.lineRange(at: 12) == NSRange(12..<18))
            #expect(calculator.lineRange(at: 17) == NSRange(12..<18))
            #expect(calculator.lineRange(at: 18) == NSRange(18..<18))
        }
        
        
        @Test func multiLinesWithoutTrailingLineEnding() {
            
            let calculator2 = Calculator(string: "dog \n\n cat \n cow ")
            
            #expect(calculator2.lineRange(at: 17) == NSRange(12..<17))
        }
        
        
        @Test func random() {
            
            for _ in 0..<10 {
                let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
                let calculator = Calculator(string: string)
                
                for index in (0...string.length).shuffled() {
                    let result = (string as NSString).lineRange(at: index)
                    
                    #expect(calculator.lineStartIndex(at: index) == result.lowerBound)
                    #expect(calculator.lineRange(at: index) == result)
                }
            }
        }
    }
    
    
    @Suite struct LineContentsRangeTests {
        
        @Test func empty() {
            
            let calculator = Calculator(string: "")
            
            #expect(calculator.lineContentsRange(for: NSRange(0..<0)) == NSRange(0..<0))
        }
        
        
        @Test func singleLineEnding() {
            
            let calculator = Calculator(string: "\r\n")
            
            #expect(calculator.lineContentsRange(for: NSRange(0..<0)) == NSRange(0..<0))
            #expect(calculator.lineContentsRange(for: NSRange(0..<1)) == NSRange(0..<0))
            #expect(calculator.lineContentsRange(for: NSRange(0..<2)) == NSRange(0..<0))
            #expect(calculator.lineContentsRange(for: NSRange(1..<1)) == NSRange(0..<0))
            #expect(calculator.lineContentsRange(for: NSRange(1..<2)) == NSRange(0..<0))
            #expect(calculator.lineContentsRange(for: NSRange(2..<2)) == NSRange(2..<2))
        }
        
        
        @Test func multiLines() {
            
            let calculator = Calculator(string: "dog \n\n cat \n cow")
            
            #expect(calculator.lineContentsRange(for: NSRange(0..<0)) == NSRange(0..<4))
            #expect(calculator.lineContentsRange(for: NSRange(0..<3)) == NSRange(0..<4))
            #expect(calculator.lineContentsRange(for: NSRange(4..<6)) == NSRange(0..<5))
            #expect(calculator.lineContentsRange(for: NSRange(5..<6)) == NSRange(5..<5))
            #expect(calculator.lineContentsRange(for: NSRange(5..<7)) == NSRange(5..<11))
            #expect(calculator.lineContentsRange(for: NSRange(6..<6)) == NSRange(6..<11))
            #expect(calculator.lineContentsRange(for: NSRange(7..<13)) == NSRange(6..<16))
            #expect(calculator.lineContentsRange(for: NSRange(16..<16)) == NSRange(12..<16))
        }
        
        
        @Test func random() {
            
            for _ in 0..<10 {
                let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
                let calculator = Calculator(string: string)
                
                for lowerBound in (0...string.length).shuffled() {
                    for upperBound in lowerBound..<string.length {
                        let range = NSRange(lowerBound..<upperBound)
                        let result = string.lineContentsRange(for: range)
                        
                        #expect(calculator.lineContentsRange(for: range) == result)
                    }
                }
            }
        }
    }
}


private struct Calculator: LineRangeCalculating {
    
    let length: Int
    let lineEndings: [ValueRange<LineEnding>]
    
    
    init(string: String) {
        
        self.length = (string as NSString).length
        self.lineEndings = string.lineEndingRanges()
    }
}
