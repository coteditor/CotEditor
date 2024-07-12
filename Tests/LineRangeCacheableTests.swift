//
//  LineRangeCacheableTests.swift
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
@testable import CotEditor

struct LineRangeCacheableTests {
    
    private let repeatCount = 20
    
    
    @Test func calculateLineNumber() {
        
        let lineString = LineString("dog \n\n cat \n cow \n")
        #expect(lineString.lineNumber(at: 0) == 1)
        #expect(lineString.lineNumber(at: 1) == 1)
        #expect(lineString.lineNumber(at: 4) == 1)
        #expect(lineString.lineNumber(at: 5) == 2)
        #expect(lineString.lineNumber(at: 6) == 3)
        #expect(lineString.lineNumber(at: 11) == 3)
        #expect(lineString.lineNumber(at: 12) == 4)
        #expect(lineString.lineNumber(at: 17) == 4)
        #expect(lineString.lineNumber(at: 18) == 5)
        
        let lineString2 = LineString("dog \n\n cat \n cow ")
        #expect(lineString2.lineNumber(at: 17) == 4)
        
        for _ in 0..<self.repeatCount {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let lineString = LineString(string)
            
            for index in (0...string.length).shuffled() {
                let result = (string as NSString).lineNumber(at: index)
                #expect(lineString.lineNumber(at: index) == result,
                        "At \(index) with string \"\(string)\"")
            }
        }
    }
    
    
    @Test func calculateIndexToLineRange() {
        
        let lineString = LineString("dog \n\n cat \n cow \n")
        #expect(lineString.lineRange(at: 0) == NSRange(0..<5))
        #expect(lineString.lineRange(at: 1) == NSRange(0..<5))
        #expect(lineString.lineRange(at: 4) == NSRange(0..<5))
        #expect(lineString.lineRange(at: 5) == NSRange(5..<6))
        #expect(lineString.lineRange(at: 6) == NSRange(6..<12))
        #expect(lineString.lineRange(at: 11) == NSRange(6..<12))
        #expect(lineString.lineRange(at: 12) == NSRange(12..<18))
        #expect(lineString.lineRange(at: 17) == NSRange(12..<18))
        #expect(lineString.lineRange(at: 18) == NSRange(18..<18))
        
        let lineString2 = LineString("dog \n\n cat \n cow ")
        #expect(lineString2.lineRange(at: 17) == NSRange(12..<17))
        
        for _ in 0..<self.repeatCount {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let lineString = LineString(string)
            
            for index in (0...string.length).shuffled() {
                let result = (string as NSString).lineRange(at: index)
                #expect(lineString.lineRange(at: index) == result,
                        "At \(index) with string \"\(string)\"")
                #expect(lineString.lineStartIndex(at: index) == result.lowerBound,
                        "At \(index) with string \"\(string)\"")
            }
        }
    }
    
    
    @Test func lineContentsRange() {
        
        let lineString = LineString("dog \n\n cat \n cow")
        #expect(lineString.lineContentsRange(for: NSRange(0..<3)) == NSRange(0..<4))
        #expect(lineString.lineContentsRange(for: NSRange(4..<6)) == NSRange(0..<6))
        #expect(lineString.lineContentsRange(for: NSRange(5..<6)) == NSRange(5..<6))
        #expect(lineString.lineContentsRange(for: NSRange(7..<13)) == NSRange(6..<16))
    }
    
    
    @Test func calculateRangeToLineRange() throws {
        
        let lineString = LineString("dog \n\n cat \n cow \n")
        #expect(lineString.lineRange(for: NSRange(0..<3)) == NSRange(0..<5))
        #expect(lineString.lineRange(for: NSRange(0..<5)) == NSRange(0..<5))
        #expect(lineString.lineRange(for: NSRange(0..<6)) == NSRange(0..<6))
        #expect(lineString.lineRange(for: NSRange(5..<5)) == NSRange(5..<6))
        #expect(lineString.lineRange(for: NSRange(5..<6)) == NSRange(5..<6))
        #expect(lineString.lineRange(for: NSRange(5..<7)) == NSRange(5..<12))
        #expect(lineString.lineRange(for: NSRange(6..<6)) == NSRange(6..<12))
        #expect(lineString.lineRange(for: NSRange(6..<7)) == NSRange(6..<12))
        #expect(lineString.lineRange(for: NSRange(6..<17)) == NSRange(6..<18))
        #expect(lineString.lineRange(for: NSRange(17..<17)) == NSRange(12..<18))
        #expect(lineString.lineRange(for: NSRange(17..<18)) == NSRange(12..<18))
        #expect(lineString.lineRange(for: NSRange(18..<18)) == NSRange(18..<18))
        
        let lineString2 = LineString("dog \n\n cat \n cow ")
        #expect(lineString2.lineRange(for: NSRange(15..<17)) == NSRange(12..<17))
        #expect(lineString2.lineRange(for: NSRange(17..<17)) == NSRange(12..<17))
        
        for _ in 0..<self.repeatCount {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let lineString = LineString(string)
            
            for index in (0...string.length).shuffled() {
                let endIndex = try #require((index...string.length).randomElement())
                let range = NSRange(index..<endIndex)
                let result = (string as NSString).lineRange(for: range)
                
                #expect(lineString.lineRange(for: range) == result,
                        "At \(index) with string \"\(string)\"")
            }
        }
    }
    
    
    @Test func invalidateString() {
        
        let lineString = LineString("\n🐶")
        let lineNumber = lineString.lineNumber(at: 1)
        let lineRange = lineString.lineRange(at: 1)
        lineString.invalidateLineRanges(in: NSRange(1..<2), changeInLength: 0)
        #expect(lineString.lineNumber(at: 1) == lineNumber)  // 2
        #expect(lineString.lineRange(at: 1) == lineRange)    // NSRange(1..<3)
        
        for _ in 0..<self.repeatCount {
            let lineString = LineString(String(" 🐶 \n 🐱 \n 🐮 \n".shuffled()))
            
            for index in (0...lineString.string.length).shuffled() {
                let lineNumber = lineString.lineNumber(at: index)
                let lineRange = lineString.lineRange(at: index)
                let range = NSRange(Int.random(in: 0..<lineString.string.length)..<lineString.string.length)
                
                lineString.invalidateLineRanges(in: range, changeInLength: 0)
                
                #expect(lineString.lineNumber(at: index) == lineNumber,
                        "At \(index) with string \"\(lineString.string)\"")
                #expect(lineString.lineRange(at: index) == lineRange,
                        "At \(index) with string \"\(lineString.string)\"")
                #expect(lineString.lineStartIndex(at: index) == lineRange.lowerBound,
                        "At \(index) with string \"\(lineString.string)\"")
            }
        }
    }
    
    
    @Test func removeString() {
        
        let lineString = LineString("dog \n\n\n cat \n ")
        _ = lineString.lineNumber(at: lineString.string.length)
        
        lineString.replaceCharacters(in: NSRange(1..<3), with: "")  // "og"
        #expect(lineString.string == "d \n\n\n cat \n ")
        #expect(lineString.lineNumber(at: 1) == 1)
        #expect(lineString.lineRange(at: 1) == NSRange(0..<3))  // "d \n"
        #expect(lineString.lineNumber(at: 3) == 2)
        #expect(lineString.lineRange(at: 3) == NSRange(3..<4))  // "\n"
        #expect(lineString.lineRange(at: 4) == NSRange(4..<5))  // "\n"
        #expect(lineString.lineRange(at: 5) == NSRange(5..<11))  // " cat \n"
        
        lineString.replaceCharacters(in: NSRange(1..<2), with: "")  // 1st " "
        #expect(lineString.string == "d\n\n\n cat \n ")
        #expect(lineString.lineNumber(at: 1) == 1)
        #expect(lineString.lineRange(at: 1) == NSRange(0..<2))  // "d\n"
        #expect(lineString.lineRange(at: 2) == NSRange(2..<3))  // "\n"
        #expect(lineString.lineRange(at: 3) == NSRange(3..<4))  // "\n"
        #expect(lineString.lineRange(at: 4) == NSRange(4..<10))  // " cat \n"
        
        lineString.replaceCharacters(in: NSRange(2..<4), with: "")  // "\n\n"
        #expect(lineString.string == "d\n cat \n ")
        #expect(lineString.lineNumber(at: 1) == 1)
        #expect(lineString.lineRange(at: 1) == NSRange(0..<2))  // "d\n"
        #expect(lineString.lineRange(at: 2) == NSRange(2..<8))  // " cat \n"
    }
    
    
    @Test func modifyString() {
        
        let lineString = LineString("\n🐶")
        _ = lineString.lineNumber(at: 1)
        lineString.replaceCharacters(in: NSRange(1..<3), with: "a\nb")
        lineString.invalidateLineRanges(in: NSRange(1..<3), changeInLength: 1)
        #expect(lineString.lineNumber(at: 1) == 2)
        #expect(lineString.lineRange(at: 1) == NSRange(1..<3))  // "a\n"
        
        for _ in 0..<self.repeatCount {
            let string = String(" dog \n cat \n cow \n".shuffled())
            let lineString = LineString(string)
            
            #expect(lineString.lineNumber(at: string.length) == 4)
            
            let location = Int.random(in: 0..<(string.length - 1))
            let length = Int.random(in: 0..<(string.length - location))
            let range = NSRange(location: location, length: length)
            let replacement = String("ab\nc".prefix(Int.random(in: 0...4)).shuffled())
            
            lineString.replaceCharacters(in: range, with: replacement)
            
            for index in (0...lineString.string.length).shuffled() {
                #expect(lineString.lineNumber(at: index) == lineString.string.lineNumber(at: index),
                        "at \(index) with string \"\(lineString.string)\"")
                #expect(lineString.lineRange(at: index) == lineString.string.lineRange(at: index),
                        "at \(index) with string \"\(lineString.string)\"")
                #expect(lineString.lineStartIndex(at: index) == lineString.string.lineStartIndex(at: index),
                        "at \(index) with string \"\(lineString.string)\"")
            }
        }
    }
    
    
    @Test func modifyEdge() {
        
        let lineString = LineString("\n  \n")
        
        #expect(lineString.lineNumber(at: 4) == 3)
        
        lineString.replaceCharacters(in: NSRange(0..<0), with: "  ")
        
        #expect(lineString.string == "  \n  \n")
        #expect(lineString.lineNumber(at: 4) == 2)
        #expect(lineString.lineRange(at: 4) == NSRange(location: 3, length: 3))
        #expect(lineString.lineStartIndex(at: 4) == 3)
    }
}


private final class LineString: LineRangeCacheable {
    
    var lineRangeCache = LineRangeCache()
    var string: NSString { self.mutableString as NSString }
    
    private let mutableString: NSMutableString
    
    
    init(_ string: String) {
        
        self.mutableString = NSMutableString(string: string)
    }
    
    
    func replaceCharacters(in range: NSRange, with replacement: String) {
        
        self.mutableString.replaceCharacters(in: range, with: replacement)
        self.invalidateLineRanges(in: NSRange(location: range.location, length: replacement.length),
                                  changeInLength: replacement.length - range.length)
    }
}
