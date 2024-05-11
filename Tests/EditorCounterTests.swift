//
//  EditorCounterTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-01-25.
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

import XCTest
@testable import CotEditor

final class EditorCounterTests: XCTestCase {
    
    @MainActor final class Provider: TextViewProvider {
        
        var textView: NSTextView? = NSTextView()
        
        
        init(string: String, selectedRange: NSRange) {
            
            self.textView?.string = string
            self.textView?.selectedRange = selectedRange
        }
    }
    
    
    private let testString = """
        dog is 🐕.
        cow is 🐄.
        Both are 👍🏼.
        """
    
    @MainActor func testNoRequiredInfo() throws {
        
        let provider = Provider(string: self.testString, selectedRange: NSRange(0..<3))
        
        let counter = EditorCounter()
        counter.document = provider
        counter.invalidateContent()
        counter.invalidateSelection()
        
        XCTAssertNil(counter.result.lines.entire)
        XCTAssertNil(counter.result.characters.entire)
        XCTAssertNil(counter.result.words.entire)
        XCTAssertNil(counter.result.location)
        XCTAssertNil(counter.result.line)
        XCTAssertNil(counter.result.column)
    }
    
    
    @MainActor func testAllRequiredInfo() throws {
        
        let provider = Provider(string: self.testString, selectedRange: NSRange(11..<21))
        
        let counter = EditorCounter()
        counter.document = provider
        counter.updatesAll = true
        counter.invalidateContent()
        counter.invalidateSelection()
        
//        XCTAssertEqual(counter.result.lines.entire, 3)
//        XCTAssertEqual(counter.result.characters.entire, 31)
//        XCTAssertEqual(counter.result.words.entire, 6)
        
//        XCTAssertEqual(counter.result.characters.selected, 9)
//        XCTAssertEqual(counter.result.lines.selected, 1)
//        XCTAssertEqual(counter.result.words.selected, 2)
        
//        XCTAssertEqual(counter.result.location, 10)
//        XCTAssertEqual(counter.result.column, 0)
//        XCTAssertEqual(counter.result.line, 2)
    }
    
    
    @MainActor func testWholeTextSkip() throws {
        
        let provider = Provider(string: self.testString, selectedRange: NSRange(11..<21))
        
        let counter = EditorCounter()
        counter.document = provider
        counter.updatesAll = true
        counter.invalidateSelection()
        
        XCTAssertNil(counter.result.lines.entire)
        XCTAssertNil(counter.result.characters.entire)
        XCTAssertNil(counter.result.words.entire)
        
//        XCTAssertEqual(counter.result.lines.selected, 1)
//        XCTAssertEqual(counter.result.characters.selected, 9)
//        XCTAssertEqual(counter.result.words.selected, 2)
        
//        XCTAssertEqual(counter.result.location, 10)
//        XCTAssertEqual(counter.result.column, 0)
//        XCTAssertEqual(counter.result.line, 2)
    }
    
    
    @MainActor func testCRLF() throws {
        
        let provider = Provider(string: "a\r\nb", selectedRange: NSRange(1..<4))
        
        let counter = EditorCounter()
        counter.document = provider
        counter.updatesAll = true
        counter.invalidateContent()
        counter.invalidateSelection()
        
//        XCTAssertEqual(counter.result.lines.entire, 2)
//        XCTAssertEqual(counter.result.characters.entire, 3)
//        XCTAssertEqual(counter.result.words.entire, 2)
        
//        XCTAssertEqual(counter.result.lines.selected, 2)
//        XCTAssertEqual(counter.result.characters.selected, 2)
//        XCTAssertEqual(counter.result.words.selected, 1)
        
//        XCTAssertEqual(counter.result.location, 1)
//        XCTAssertEqual(counter.result.column, 1)
//        XCTAssertEqual(counter.result.line, 1)
    }
    
    
    func testEditorCountFormatting() {
        
        var count = EditorCount()
        
        XCTAssertNil(count.formatted)
        
        count.entire = 1000
        XCTAssertEqual(count.formatted, "1,000")
        
        count.selected = 100
        XCTAssertEqual(count.formatted, "1,000 (100)")
        
        count.entire = nil
        XCTAssertNil(count.formatted)
    }
}
