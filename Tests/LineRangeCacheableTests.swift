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
//  © 2020 1024jp
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
        
        for _ in (0..<10) {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let lineString = LineString(string)
            
            for index in (0..<string.length).shuffled() {
                let result = (string as NSString).lineNumber(at: index)
                XCTAssertEqual(lineString.lineNumber(at: index), result, "At \(index) with string \"\(string)\"")
            }
        }
    }
    

    func testLineRangeCalculation() {
        
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
        
        for _ in (0..<10) {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let lineString = LineString(string)
            
            for index in (0..<string.length).shuffled() {
                let result = (string as NSString).lineRange(at: index)
                XCTAssertEqual(lineString.lineRange(at: index), result, "At \(index) with string \"\(string)\"")
            }
        }
    }

    
    func testStringInvalidation() {
        
        let lineString = LineString("\n🐶")
        let lineNumber = lineString.lineNumber(at: 1)
        let lineRange = lineString.lineRange(at: 1)
        lineString.invalidateLineRanges(from: 1)
        XCTAssertEqual(lineString.lineNumber(at: 1), lineNumber)  // 2
        XCTAssertEqual(lineString.lineRange(at: 1), lineRange)    // NSRange(1..<3)
        XCTAssertEqual(lineString.lineStartIndexes.count, 1)
        
        for _ in (0..<10) {
            let lineString = LineString(String(" 🐶 \n 🐱 \n 🐮 \n".shuffled()))
            
            for index in (0..<lineString.string.length).shuffled() {
                let lineNumber = lineString.lineNumber(at: index)
                let lineRange = lineString.lineRange(at: index)
                
                lineString.invalidateLineRanges(from: Int.random(in: 0..<lineString.string.length))
                
                XCTAssertEqual(lineString.lineNumber(at: index), lineNumber, "At \(index) with string \"\(lineString.string)\"")
                XCTAssertEqual(lineString.lineRange(at: index), lineRange, "At \(index) with string \"\(lineString.string)\"")
            }
        }
    }

    
    func testStringModification() {
        
        let string = "\n🐶"
        let lineString = LineString(string)
        _ = lineString.lineNumber(at: 1)
        lineString.string.replaceSubrange(Range(NSRange(1..<3), in: string)!, with: "a\nb")
        lineString.invalidateLineRanges(from: 1)
        XCTAssertEqual(lineString.lineNumber(at: 1), 2)
        XCTAssertEqual(lineString.lineRange(at: 1), NSRange(1..<3))  // "a\n"
        XCTAssertEqual(lineString.lineStartIndexes.count, 2)
        
        for _ in (0..<10) {
            let string = String(" dog \n cat \n cow \n".shuffled())
            let lineString = LineString(string)
            
            XCTAssertEqual(lineString.lineNumber(at: string.length), 4, "with string \"\(lineString.string)\"")
            
            let location = Int.random(in: 0..<(string.length - 1))
            let length = Int.random(in: 0..<(string.length - location))
            let range = NSRange(location: location, length: length)
            let replacement = String("ab\nc".shuffled())
            
            lineString.string.replaceSubrange(Range(range, in: string)!, with: replacement)
            lineString.invalidateLineRanges(from: range.location)

            for index in (0..<lineString.string.length).shuffled() {
                XCTAssertEqual(lineString.lineNumber(at: index), (lineString.string as NSString).lineNumber(at: index))
                XCTAssertEqual(lineString.lineRange(at: index), (lineString.string as NSString).lineRange(at: index))
            }
        }
    }

}


private class LineString: LineRangeCacheable {
    
    var string: String
    var lineStartIndexes = IndexSet()
    var firstLineUncoundedIndex = 0
    
    
    init(_ string: String) {
        
        self.string = string
    }
    
}
