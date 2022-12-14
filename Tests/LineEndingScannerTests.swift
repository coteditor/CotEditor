//
//  LineEndingScannerTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

final class LineEndingScannerTests: XCTestCase {
    
    func testScanner() {
        
        let storage = NSTextStorage(string: "dog\ncat\r\ncow")
        let scanner = LineEndingScanner(textStorage: storage, lineEnding: .lf)
        
        storage.replaceCharacters(in: NSRange(0..<3), with: "dog\u{85}cow")
        
        // test async line ending scan
        let expectation = self.expectation(description: "didScanLineEndings")
        let observer = scanner.$inconsistentLineEndings
            .sink { (lineEndings) in
                XCTAssertEqual(lineEndings, [ItemRange(item: .nel, range: NSRange(location: 3, length: 1)),
                                             ItemRange(item: .crlf, range: NSRange(location: 11, length: 2))])
                expectation.fulfill()
            }
        self.wait(for: [expectation], timeout: .zero)
        
        observer.cancel()
    }
    
    
    func testEmpty() {
        
        let storage = NSTextStorage(string: "\r")
        let scanner = LineEndingScanner(textStorage: storage, lineEnding: .lf)
        
        XCTAssertEqual(scanner.inconsistentLineEndings, [ItemRange(item: .cr, range: NSRange(location: 0, length: 1))])
        
        // test scanRange does not expand to the out of range
        storage.replaceCharacters(in: NSRange(0..<1), with: "")
        
        // test async line ending scan
        let expectation = self.expectation(description: "didScanLineEndings")
        let observer = scanner.$inconsistentLineEndings
            .sink { (lineEndings) in
                XCTAssert(lineEndings.isEmpty)
                expectation.fulfill()
            }
        self.wait(for: [expectation], timeout: .zero)
        
        observer.cancel()
    }
    
    
    func testCRLFEditing() {
        
        let storage = NSTextStorage(string: "dog\ncat\r\ncow")
        let scanner = LineEndingScanner(textStorage: storage, lineEnding: .lf)
        
        // add \r before \n  (LF -> CRLF)
        storage.replaceCharacters(in: NSRange(3..<3), with: "\r")
        // remove \n after \r (CRLF -> CR)
        storage.replaceCharacters(in: NSRange(9..<10), with: "")
        
        // test async line ending scan
        let expectation = self.expectation(description: "didScanLineEndings")
        let observer = scanner.$inconsistentLineEndings
            .sink { (lineEndings) in
                XCTAssertEqual(lineEndings, [ItemRange(item: .crlf, range: NSRange(location: 3, length: 2)),
                                             ItemRange(item: .cr, range: NSRange(location: 8, length: 1))])
                expectation.fulfill()
            }
        self.wait(for: [expectation], timeout: .zero)
        
        observer.cancel()
    }
    
    
    func testDetection() {
        
        let storage = NSTextStorage()
        let scanner = LineEndingScanner(textStorage: storage, lineEnding: .lf)
        
        XCTAssertNil(scanner.majorLineEnding)
        
        storage.string = "a"
        XCTAssertNil(scanner.majorLineEnding)
        
        storage.string = "\n"
        XCTAssertEqual(scanner.majorLineEnding, .lf)
        
        storage.string = "\r"
        XCTAssertEqual(scanner.majorLineEnding, .cr)
        
        storage.string = "\r\n"
        XCTAssertEqual(scanner.majorLineEnding, .crlf)
        
        storage.string = "\u{85}"
        XCTAssertEqual(scanner.majorLineEnding, .nel)
        
        storage.string = "abc\u{2029}def"
        XCTAssertEqual(scanner.majorLineEnding, .paragraphSeparator)
        
        storage.string = "\rfoo\r\nbar\nbuz\u{2029}moin\r\n"
        XCTAssertEqual(scanner.majorLineEnding, .crlf)  // most used new line must be detected
    }
    
    
    func testLineNumberCalculation() {
        
        let storage = NSTextStorage(string: "dog \n\n cat \n cow \n")
        let scanner = LineEndingScanner(textStorage: storage, lineEnding: .lf)
        
        XCTAssertEqual(scanner.lineNumber(at: 0), 1)
        XCTAssertEqual(scanner.lineNumber(at: 1), 1)
        XCTAssertEqual(scanner.lineNumber(at: 4), 1)
        XCTAssertEqual(scanner.lineNumber(at: 5), 2)
        XCTAssertEqual(scanner.lineNumber(at: 6), 3)
        XCTAssertEqual(scanner.lineNumber(at: 11), 3)
        XCTAssertEqual(scanner.lineNumber(at: 12), 4)
        XCTAssertEqual(scanner.lineNumber(at: 17), 4)
        XCTAssertEqual(scanner.lineNumber(at: 18), 5)
        
        for _ in 0..<20 {
            storage.string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            
            for index in (0..<storage.length).shuffled() {
                XCTAssertEqual(scanner.lineNumber(at: index),
                               storage.string.lineNumber(at: index),
                               "At \(index) with string \"\(storage.string)\"")
            }
        }
    }
}


extension NSTextStorage {
    
    open override var string: String {
        
        get { super.string }
        set { self.replaceCharacters(in: self.range, with: newValue) }
    }
}
