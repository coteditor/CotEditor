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
//  © 2020-2023 1024jp
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

import XCTest
@testable import CotEditor

final class LineRangeCacheableTests: XCTestCase {
    
    private let repeatCount = 20
    
    
    func testLineNumberCalculation() {
        
        let lineString = LineString("dog \n\n cat \n cow \n")
        XCTAssertEqual(lineString.lineNumber(at: 0), 1)
        XCTAssertEqual(lineString.lineNumber(at: 1), 1)
        XCTAssertEqual(lineString.lineNumber(at: 4), 1)
        XCTAssertEqual(lineString.lineNumber(at: 5), 2)
        XCTAssertEqual(lineString.lineNumber(at: 6), 3)
        XCTAssertEqual(lineString.lineNumber(at: 11), 3)
        XCTAssertEqual(lineString.lineNumber(at: 12), 4)
        XCTAssertEqual(lineString.lineNumber(at: 17), 4)
        XCTAssertEqual(lineString.lineNumber(at: 18), 5)
        
        let lineString2 = LineString("dog \n\n cat \n cow ")
        XCTAssertEqual(lineString2.lineNumber(at: 17), 4)
        
        for _ in 0..<self.repeatCount {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let lineString = LineString(string)
            
            for index in (0...string.length).shuffled() {
                let result = (string as NSString).lineNumber(at: index)
                XCTAssertEqual(lineString.lineNumber(at: index), result, "At \(index) with string \"\(string)\"")
            }
        }
    }
    
    
    func testIndexToLineRangeCalculation() {
        
        let lineString = LineString("dog \n\n cat \n cow \n")
        XCTAssertEqual(lineString.lineRange(at: 0), NSRange(0..<5))
        XCTAssertEqual(lineString.lineRange(at: 1), NSRange(0..<5))
        XCTAssertEqual(lineString.lineRange(at: 4), NSRange(0..<5))
        XCTAssertEqual(lineString.lineRange(at: 5), NSRange(5..<6))
        XCTAssertEqual(lineString.lineRange(at: 6), NSRange(6..<12))
        XCTAssertEqual(lineString.lineRange(at: 11), NSRange(6..<12))
        XCTAssertEqual(lineString.lineRange(at: 12), NSRange(12..<18))
        XCTAssertEqual(lineString.lineRange(at: 17), NSRange(12..<18))
        XCTAssertEqual(lineString.lineRange(at: 18), NSRange(18..<18))
        
        let lineString2 = LineString("dog \n\n cat \n cow ")
        XCTAssertEqual(lineString2.lineRange(at: 17), NSRange(12..<17))
        
        for _ in 0..<self.repeatCount {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let lineString = LineString(string)
            
            for index in (0...string.length).shuffled() {
                let result = (string as NSString).lineRange(at: index)
                XCTAssertEqual(lineString.lineRange(at: index), result, "At \(index) with string \"\(string)\"")
                XCTAssertEqual(lineString.lineStartIndex(at: index), result.lowerBound, "At \(index) with string \"\(string)\"")
            }
        }
    }
    
    
    func testRangeToLineRangeCalculation() {
        
        let lineString = LineString("dog \n\n cat \n cow \n")
        XCTAssertEqual(lineString.lineRange(for: NSRange(0..<3)), NSRange(0..<5))
        XCTAssertEqual(lineString.lineRange(for: NSRange(0..<5)), NSRange(0..<5))
        XCTAssertEqual(lineString.lineRange(for: NSRange(0..<6)), NSRange(0..<6))
        XCTAssertEqual(lineString.lineRange(for: NSRange(5..<5)), NSRange(5..<6))
        XCTAssertEqual(lineString.lineRange(for: NSRange(5..<6)), NSRange(5..<6))
        XCTAssertEqual(lineString.lineRange(for: NSRange(5..<7)), NSRange(5..<12))
        XCTAssertEqual(lineString.lineRange(for: NSRange(6..<6)), NSRange(6..<12))
        XCTAssertEqual(lineString.lineRange(for: NSRange(6..<7)), NSRange(6..<12))
        XCTAssertEqual(lineString.lineRange(for: NSRange(6..<17)), NSRange(6..<18))
        XCTAssertEqual(lineString.lineRange(for: NSRange(17..<17)), NSRange(12..<18))
        XCTAssertEqual(lineString.lineRange(for: NSRange(17..<18)), NSRange(12..<18))
        XCTAssertEqual(lineString.lineRange(for: NSRange(18..<18)), NSRange(18..<18))
        
        let lineString2 = LineString("dog \n\n cat \n cow ")
        XCTAssertEqual(lineString2.lineRange(for: NSRange(15..<17)), NSRange(12..<17))
        XCTAssertEqual(lineString2.lineRange(for: NSRange(17..<17)), NSRange(12..<17))
        
        for _ in 0..<self.repeatCount {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let lineString = LineString(string)
            
            for index in (0...string.length).shuffled() {
                let range = NSRange(index..<(index...string.length).randomElement()!)
                let result = (string as NSString).lineRange(for: range)
                
                XCTAssertEqual(lineString.lineRange(for: range), result, "At \(index) with string \"\(string)\"")
            }
        }
    }
    
    
    func testStringInvalidation() {
        
        let lineString = LineString("\n🐶")
        let lineNumber = lineString.lineNumber(at: 1)
        let lineRange = lineString.lineRange(at: 1)
        lineString.invalidateLineRanges(in: NSRange(1..<2), changeInLength: 0)
        XCTAssertEqual(lineString.lineNumber(at: 1), lineNumber)  // 2
        XCTAssertEqual(lineString.lineRange(at: 1), lineRange)    // NSRange(1..<3)
        
        for _ in 0..<self.repeatCount {
            let lineString = LineString(String(" 🐶 \n 🐱 \n 🐮 \n".shuffled()))
            
            for index in (0...lineString.string.length).shuffled() {
                let lineNumber = lineString.lineNumber(at: index)
                let lineRange = lineString.lineRange(at: index)
                let range = NSRange(Int.random(in: 0..<lineString.string.length)..<lineString.string.length)
                
                lineString.invalidateLineRanges(in: range, changeInLength: 0)
                
                XCTAssertEqual(lineString.lineNumber(at: index), lineNumber, "At \(index) with string \"\(lineString.string)\"")
                XCTAssertEqual(lineString.lineRange(at: index), lineRange, "At \(index) with string \"\(lineString.string)\"")
                XCTAssertEqual(lineString.lineStartIndex(at: index), lineRange.lowerBound, "At \(index) with string \"\(lineString.string)\"")
            }
        }
    }
    
    
    func testStringRemoval() {
        
        let lineString = LineString("dog \n\n\n cat \n ")
        _ = lineString.lineNumber(at: lineString.string.length)
        
        lineString.replaceCharacters(in: NSRange(1..<3), with: "")  // "og"
        XCTAssertEqual(lineString.string, "d \n\n\n cat \n ")
        XCTAssertEqual(lineString.lineNumber(at: 1), 1)
        XCTAssertEqual(lineString.lineRange(at: 1), NSRange(0..<3))  // "d \n"
        XCTAssertEqual(lineString.lineNumber(at: 3), 2)
        XCTAssertEqual(lineString.lineRange(at: 3), NSRange(3..<4))  // "\n"
        XCTAssertEqual(lineString.lineRange(at: 4), NSRange(4..<5))  // "\n"
        XCTAssertEqual(lineString.lineRange(at: 5), NSRange(5..<11))  // " cat \n"
        
        lineString.replaceCharacters(in: NSRange(1..<2), with: "")  // 1st " "
        XCTAssertEqual(lineString.string, "d\n\n\n cat \n ")
        XCTAssertEqual(lineString.lineNumber(at: 1), 1)
        XCTAssertEqual(lineString.lineRange(at: 1), NSRange(0..<2))  // "d\n"
        XCTAssertEqual(lineString.lineRange(at: 2), NSRange(2..<3))  // "\n"
        XCTAssertEqual(lineString.lineRange(at: 3), NSRange(3..<4))  // "\n"
        XCTAssertEqual(lineString.lineRange(at: 4), NSRange(4..<10))  // " cat \n"
        
        lineString.replaceCharacters(in: NSRange(2..<4), with: "")  // "\n\n"
        XCTAssertEqual(lineString.string, "d\n cat \n ")
        XCTAssertEqual(lineString.lineNumber(at: 1), 1)
        XCTAssertEqual(lineString.lineRange(at: 1), NSRange(0..<2))  // "d\n"
        XCTAssertEqual(lineString.lineRange(at: 2), NSRange(2..<8))  // " cat \n"
    }
    
    
    func testStringModification() {
        
        let lineString = LineString("\n🐶")
        _ = lineString.lineNumber(at: 1)
        lineString.replaceCharacters(in: NSRange(1..<3), with: "a\nb")
        lineString.invalidateLineRanges(in: NSRange(1..<3), changeInLength: 1)
        XCTAssertEqual(lineString.lineNumber(at: 1), 2)
        XCTAssertEqual(lineString.lineRange(at: 1), NSRange(1..<3))  // "a\n"
        
        for _ in 0..<self.repeatCount {
            let string = String(" dog \n cat \n cow \n".shuffled())
            let lineString = LineString(string)
            
            XCTAssertEqual(lineString.lineNumber(at: string.length), 4)
            
            let location = Int.random(in: 0..<(string.length - 1))
            let length = Int.random(in: 0..<(string.length - location))
            let range = NSRange(location: location, length: length)
            let replacement = String("ab\nc".prefix(Int.random(in: 0...4)).shuffled())
            
            lineString.replaceCharacters(in: range, with: replacement)
            
            for index in (0...lineString.string.length).shuffled() {
                XCTAssertEqual(lineString.lineNumber(at: index), lineString.string.lineNumber(at: index),
                               "at \(index) with string \"\(lineString.string)\"")
                XCTAssertEqual(lineString.lineRange(at: index), lineString.string.lineRange(at: index),
                               "at \(index) with string \"\(lineString.string)\"")
                XCTAssertEqual(lineString.lineStartIndex(at: index), lineString.string.lineStartIndex(at: index),
                               "at \(index) with string \"\(lineString.string)\"")
            }
        }
    }
    
    
    func testEdgeModification() {
        
        let lineString = LineString("\n  \n")
        
        XCTAssertEqual(lineString.lineNumber(at: 4), 3)
        
        lineString.replaceCharacters(in: NSRange(0..<0), with: "  ")
        
        let index = 4
        XCTAssertEqual(lineString.string, "  \n  \n")
        XCTAssertEqual(lineString.lineNumber(at: index), 2)
        XCTAssertEqual(lineString.lineRange(at: index), NSRange(location: 3, length: 3))
        XCTAssertEqual(lineString.lineStartIndex(at: index), 3)
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
