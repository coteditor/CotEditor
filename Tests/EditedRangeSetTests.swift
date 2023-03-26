//
//  EditedRangeSetTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-02-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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
import Combine
@testable import CotEditor

final class EditedRangeSetTests: XCTestCase {
    
    func testRangeSet() throws {
        
        // abcdefg
        var set = EditedRangeSet()
        
        // ab|0000|efg
        // .replaceCharacters(in: NSRange(2..<3), with: "0000")
        set.append(editedRange: NSRange(location: 2, length: 4), changeInLength: 2)
        XCTAssertEqual(set.ranges, [NSRange(location: 2, length: 4)])
        
        // ab0000e|g
        // .replaceCharacters(in: NSRange(7..<8), with: "")
        set.append(editedRange: NSRange(location: 7, length: 0), changeInLength: -1)
        XCTAssertEqual(set.ranges, [NSRange(location: 2, length: 4),
                                    NSRange(location: 7, length: 0)])
        
        // ab0|0eg
        // .replaceCharacters(in: NSRange(3..<5), with: "")
        set.append(editedRange: NSRange(location: 3, length: 0), changeInLength: -2)
        XCTAssertEqual(set.ranges, [NSRange(location: 2, length: 2),
                                    NSRange(location: 5, length: 0)])
        
        // a|1|b00eg
        // .replaceCharacters(in: NSRange(1..<1), with: "1")
        set.append(editedRange: NSRange(location: 1, length: 1), changeInLength: 1)
        XCTAssertEqual(set.ranges, [NSRange(location: 1, length: 1),
                                    NSRange(location: 3, length: 2),
                                    NSRange(location: 6, length: 0)])
        
        set.clear()
        XCTAssert(set.ranges.isEmpty)
    }
    
    
    func testUnion() throws {
        
        XCTAssertEqual(NSRange(2..<3).union(NSRange(3..<4)), NSRange(2..<4))
        
        let textStorage = NSTextStorage("abcdefghij")
        var set = EditedRangeSet()
        
        textStorage.replaceCharacters(in: NSRange(location: 2, length: 2), with: "00")
        set.append(editedRange: NSRange(location: 2, length: 2), changeInLength: 0)
        textStorage.replaceCharacters(in: NSRange(location: 6, length: 2), with: "00")
        set.append(editedRange: NSRange(location: 6, length: 2), changeInLength: 0)
        XCTAssertEqual(textStorage.string, "ab00ef00ij")
        XCTAssertEqual(set.ranges, [NSRange(location: 2, length: 2), NSRange(location: 6, length: 2)])
        
        textStorage.replaceCharacters(in: NSRange(location: 3, length: 4), with: "11")
        set.append(editedRange: NSRange(location: 3, length: 2), changeInLength: -2)
        XCTAssertEqual(textStorage.string, "ab0110ij")
        XCTAssertEqual(set.ranges, [NSRange(location: 2, length: 4)])
        
        textStorage.replaceCharacters(in: NSRange(location: 1, length: 3), with: "22")
        set.append(editedRange: NSRange(location: 1, length: 2), changeInLength: -1)
        XCTAssertEqual(textStorage.string, "a2210ij")
        XCTAssertEqual(set.ranges, [NSRange(location: 1, length: 4)])
    }
    
    
    func testJoin() throws {
        
        var set = EditedRangeSet()
        
        // 112200
        set.append(editedRange: NSRange(location: 4, length: 2), changeInLength: 0)
        set.append(editedRange: NSRange(location: 0, length: 2), changeInLength: 0)
        set.append(editedRange: NSRange(location: 2, length: 2), changeInLength: 0)
        
        XCTAssertEqual(set.ranges, [NSRange(location: 0, length: 6)])
    }
    
    
    func testStorageTest() async throws {
        
        let textStorage = NSTextStorage("abcdefg")
        var set = EditedRangeSet()
        
        let expectation = self.expectation(description: "UserDefaults observation for normal key")
        expectation.expectedFulfillmentCount = 4
        
        let observer = NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: textStorage)
            .map { $0.object as! NSTextStorage }
            .filter { $0.editedMask.contains(.editedCharacters) }
            .sink { storage in
                set.append(editedRange: storage.editedRange, changeInLength: storage.changeInLength)
                expectation.fulfill()
            }
        
        textStorage.replaceCharacters(in: NSRange(2..<4), with: "0000")
        textStorage.replaceCharacters(in: NSRange(7..<8), with: "")
        textStorage.replaceCharacters(in: NSRange(3..<5), with: "")
        textStorage.replaceCharacters(in: NSRange(1..<1), with: "1")
        
        await self.fulfillment(of: [expectation], timeout: 2)
        
        XCTAssertEqual(textStorage.string, "a1b00eg")
        XCTAssertEqual(set.ranges, [NSRange(location: 1, length: 1),
                                    NSRange(location: 3, length: 2),
                                    NSRange(location: 6, length: 0)])
        
        observer.cancel()
    }
}
