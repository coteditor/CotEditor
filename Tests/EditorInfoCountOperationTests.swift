//
//  EditorInfoCountOperationTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-01-25.
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

final class EditorInfoCountOperationTests: XCTestCase {
    
    private let testString = """
        dog is 🐕.
        cow is 🐄.
        Both are 👍🏼.
        """
    
    func testNoRequiredInfo() {
        
        let selectedRange = Range(NSRange(0..<3), in: self.testString)!
        let operation = EditorInfoCountOperation(
            string: self.testString,
            lineEnding: .lf,
            selectedRange: selectedRange,
            requiredInfo: [],
            countsLineEnding: true,
            countsWholeText: true)
        
        operation.start()
        
        XCTAssertEqual(operation.result.count.length, 0)
        XCTAssertEqual(operation.result.count.characters, 0)
        XCTAssertEqual(operation.result.count.lines, 0)
        XCTAssertEqual(operation.result.count.words, 0)
        XCTAssertEqual(operation.result.selectedCount.length, 0)
        XCTAssertEqual(operation.result.selectedCount.characters, 0)
        XCTAssertEqual(operation.result.selectedCount.lines, 0)
        XCTAssertEqual(operation.result.selectedCount.words, 0)
    }
    
    
    func testAllRequiredInfo() {
        
        let selectedRange = Range(NSRange(11..<21), in: self.testString)!
        let operation = EditorInfoCountOperation(
            string: self.testString,
            lineEnding: .lf,
            selectedRange: selectedRange,
            requiredInfo: .all,
            countsLineEnding: true,
            countsWholeText: true)
        
        operation.start()
        
        XCTAssertEqual(operation.result.count.length, 36)
        XCTAssertEqual(operation.result.count.characters, 31)
        XCTAssertEqual(operation.result.count.lines, 3)
        XCTAssertEqual(operation.result.count.words, 6)
        
        XCTAssertEqual(operation.result.selectedCount.length, 10)
        XCTAssertEqual(operation.result.selectedCount.characters, 9)
        XCTAssertEqual(operation.result.selectedCount.lines, 1)
        XCTAssertEqual(operation.result.selectedCount.words, 2)
        
        XCTAssertEqual(operation.result.cursor.location, 11)
        XCTAssertEqual(operation.result.cursor.column, 1)
        XCTAssertEqual(operation.result.cursor.line, 2)
    }
    
    
    func testWholeTextSkip() {
        
        let selectedRange = Range(NSRange(11..<21), in: self.testString)!
        let operation = EditorInfoCountOperation(
            string: self.testString,
            lineEnding: .lf,
            selectedRange: selectedRange,
            requiredInfo: .all,
            countsLineEnding: true,
            countsWholeText: false)
        
        operation.start()
        
        XCTAssertEqual(operation.result.count.length, 0)
        XCTAssertEqual(operation.result.count.characters, 0)
        XCTAssertEqual(operation.result.count.lines, 0)
        XCTAssertEqual(operation.result.count.words, 0)
        
        XCTAssertEqual(operation.result.selectedCount.length, 10)
        XCTAssertEqual(operation.result.selectedCount.characters, 9)
        XCTAssertEqual(operation.result.selectedCount.lines, 1)
        XCTAssertEqual(operation.result.selectedCount.words, 2)
        
        XCTAssertEqual(operation.result.cursor.location, 11)
        XCTAssertEqual(operation.result.cursor.column, 1)
        XCTAssertEqual(operation.result.cursor.line, 2)
    }
    
    
    func testCRLF() {
        
        let string = "a\nb"
        let selectedRange = Range(NSRange(1..<3), in: string)!
        let operation = EditorInfoCountOperation(
            string: string,
            lineEnding: .crlf,
            selectedRange: selectedRange,
            requiredInfo: .all,
            countsLineEnding: true,
            countsWholeText: true)
        
        operation.start()
        
        XCTAssertEqual(operation.result.count.length, 4)
        XCTAssertEqual(operation.result.count.characters, 3)
        XCTAssertEqual(operation.result.count.lines, 2)
        XCTAssertEqual(operation.result.count.words, 2)
        
        XCTAssertEqual(operation.result.selectedCount.length, 3)
        XCTAssertEqual(operation.result.selectedCount.characters, 2)
        XCTAssertEqual(operation.result.selectedCount.lines, 2)
        XCTAssertEqual(operation.result.selectedCount.words, 1)
        
        XCTAssertEqual(operation.result.cursor.location, 2)
        XCTAssertEqual(operation.result.cursor.column, 2)
        XCTAssertEqual(operation.result.cursor.line, 1)
    }
    
    
    func testLineEndingsSkipping() {
        
        let string = "a\nb"
        let selectedRange = Range(NSRange(1..<3), in: string)!
        let operation = EditorInfoCountOperation(
            string: string,
            lineEnding: .crlf,
            selectedRange: selectedRange,
            requiredInfo: .all,
            countsLineEnding: false,
            countsWholeText: true)
        
        operation.start()
        
        XCTAssertEqual(operation.result.count.length, 4)
        XCTAssertEqual(operation.result.count.characters, 2)
        XCTAssertEqual(operation.result.count.lines, 2)
        XCTAssertEqual(operation.result.count.words, 2)
        
        XCTAssertEqual(operation.result.selectedCount.length, 3)
        XCTAssertEqual(operation.result.selectedCount.characters, 1)
        XCTAssertEqual(operation.result.selectedCount.lines, 2)
        XCTAssertEqual(operation.result.selectedCount.words, 1)
        
        XCTAssertEqual(operation.result.cursor.location, 2)
        XCTAssertEqual(operation.result.cursor.column, 2)
        XCTAssertEqual(operation.result.cursor.line, 1)
    }
    
}
