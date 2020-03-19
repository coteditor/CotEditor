//
//  StringLineProcessingTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-03-16.
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

final class StringLineProcessingTests: XCTestCase {
    
    func testMoveLineUp() {
        
        let string = """
            aa
            bbbb
            ccc
            d
            eee
            """
        var info: String.EditingInfo?
        
        info = string.moveLineUp(in: [NSRange(4, 1)])
        XCTAssertEqual(info!.strings, ["bbbb\naa\n"])
        XCTAssertEqual(info!.ranges, [NSRange(0, 8)])
        XCTAssertEqual(info!.selectedRanges, [NSRange(1, 1)])
        
        info = string.moveLineUp(in: [NSRange(4, 1), NSRange(6, 0)])
        XCTAssertEqual(info!.strings, ["bbbb\naa\n"])
        XCTAssertEqual(info!.ranges, [NSRange(0, 8)])
        XCTAssertEqual(info!.selectedRanges, [NSRange(1, 1), NSRange(3, 0)])
        
        info = string.moveLineUp(in: [NSRange(2, 1)])
        XCTAssertNil(info)
    }
    
    
    func testMoveLineDown() {
        
        let string = """
            aa
            bbbb
            ccc
            d
            eee
            """
        var info: String.EditingInfo?
        
        info = string.moveLineDown(in: [NSRange(4, 1)])
        XCTAssertEqual(info!.strings, ["aa\nccc\nbbbb\n"])
        XCTAssertEqual(info!.ranges, [NSRange(0, 12)])
        XCTAssertEqual(info!.selectedRanges, [NSRange(8, 1)])
        
        info = string.moveLineDown(in: [NSRange(4, 1), NSRange(6, 0), NSRange(13, 1)])
        XCTAssertEqual(info!.strings, ["aa\nccc\nbbbb\neee\nd"])
        XCTAssertEqual(info!.ranges, [NSRange(0, 17)])
        XCTAssertEqual(info!.selectedRanges, [NSRange(8, 1), NSRange(10, 0), NSRange(17, 1)])
        
        info = string.moveLineDown(in: [NSRange(14, 1)])
        XCTAssertNil(info)
    }
    
    
    func testSortLinesAscending() {
        
        let string = """
            ccc
            aa
            bbbb
            """
        var info: String.EditingInfo?
        
        info = string.sortLinesAscending(in: NSRange(4, 1))
        XCTAssertNil(info)
        
        info = string.sortLinesAscending(in: string.nsRange)
        XCTAssertEqual(info!.strings, ["aa\nbbbb\nccc"])
        XCTAssertEqual(info!.ranges, [NSRange(0, 11)])
        XCTAssertEqual(info!.selectedRanges, [NSRange(0, 11)])
    }
    
    
    func testReverseLines() {
        
        let string = """
            aa
            bbbb
            ccc
            """
        var info: String.EditingInfo?
        
        info = string.reverseLines(in: NSRange(4, 1))
        XCTAssertNil(info)
        
        info = string.reverseLines(in: string.nsRange)
        XCTAssertEqual(info!.strings, ["ccc\nbbbb\naa"])
        XCTAssertEqual(info!.ranges, [NSRange(0, 11)])
        XCTAssertEqual(info!.selectedRanges, [NSRange(0, 11)])
    }
    
    
    func testDeleteDuplicateLine() {
        
        let string = """
            aa
            bbbb
            ccc
            ccc
            bbbb
            """
        var info: String.EditingInfo?
        
        info = string.deleteDuplicateLine(in: [NSRange(4, 1)])
        XCTAssertEqual(info!.strings, [])
        XCTAssertEqual(info!.ranges, [])
        XCTAssertNil(info!.selectedRanges)
        
        info = string.deleteDuplicateLine(in: [string.nsRange])!
        XCTAssertEqual(info!.strings, ["aa\nbbbb\nccc"])
        XCTAssertEqual(info!.ranges, [NSRange(0, 20)])
        XCTAssertNil(info!.selectedRanges)
        
        info = string.deleteDuplicateLine(in: [NSRange(10, 4)])!
        XCTAssertEqual(info!.strings, ["ccc"])
        XCTAssertEqual(info!.ranges, [NSRange(8, 7)])
        XCTAssertNil(info!.selectedRanges)
    }
    
    
    func testDuplicateLine() {
        
        let string = """
            aa
            bbbb
            ccc
            """
        var info: String.EditingInfo?
        
        info = string.duplicateLine(in: [NSRange(4, 1)])!
        XCTAssertEqual(info!.strings, ["bbbb\n"])
        XCTAssertEqual(info!.ranges, [NSRange(3, 0)])
        XCTAssertEqual(info!.selectedRanges, [NSRange(9, 1)])
    }
    
    
    func testDeleteLine() {
        
        let string = """
            aa
            bbbb
            ccc
            """
        var info: String.EditingInfo?
        
        info = string.deleteLine(in: [NSRange(4, 1)])
        XCTAssertEqual(info!.strings, [""])
        XCTAssertEqual(info!.ranges, [NSRange(3, 5)])
        XCTAssertEqual(info!.selectedRanges, [NSRange(3, 0)])
    }

}



// MARK: -

private extension NSRange {
    
    init(_ location: Int, _ length: Int) {
        
        self.init(location: location, length: length)
    }
    
}
