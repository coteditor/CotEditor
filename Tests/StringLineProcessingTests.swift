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

struct StringLineProcessingTests {
    
    @Test func moveLineUp() throws {
        
        let string = """
            aa
            bbbb
            ccc
            d
            eee
            """
        var info: String.EditingInfo
        
        info = try #require(string.moveLineUp(in: [NSRange(4, 1)]))
        #expect(info.strings == ["bbbb\naa\n"])
        #expect(info.ranges == [NSRange(0, 8)])
        #expect(info.selectedRanges == [NSRange(1, 1)])
        
        info = try #require(string.moveLineUp(in: [NSRange(4, 1), NSRange(6, 0)]))
        #expect(info.strings == ["bbbb\naa\n"])
        #expect(info.ranges == [NSRange(0, 8)])
        #expect(info.selectedRanges == [NSRange(1, 1), NSRange(3, 0)])
        
        info = try #require(string.moveLineUp(in: [NSRange(4, 1), NSRange(9, 0), NSRange(15, 1)]))
        #expect(info.strings == ["bbbb\nccc\naa\neee\nd"])
        #expect(info.ranges == [NSRange(0, 17)])
        #expect(info.selectedRanges == [NSRange(1, 1), NSRange(6, 0), NSRange(13, 1)])
        
        #expect(string.moveLineUp(in: [NSRange(2, 1)]) == nil)
    }
    
    
    @Test func moveLineDown() throws {
        
        let string = """
            aa
            bbbb
            ccc
            d
            eee
            """
        var info: String.EditingInfo
        
        info = try #require(string.moveLineDown(in: [NSRange(4, 1)]))
        #expect(info.strings == ["aa\nccc\nbbbb\n"])
        #expect(info.ranges == [NSRange(0, 12)])
        #expect(info.selectedRanges == [NSRange(8, 1)])
        
        info = try #require(string.moveLineDown(in: [NSRange(4, 1), NSRange(6, 0)]))
        #expect(info.strings == ["aa\nccc\nbbbb\n"])
        #expect(info.ranges == [NSRange(0, 12)])
        #expect(info.selectedRanges == [NSRange(8, 1), NSRange(10, 0)])
        
        info = try #require(string.moveLineDown(in: [NSRange(4, 1), NSRange(9, 0), NSRange(13, 1)]))
        #expect(info.strings == ["aa\neee\nbbbb\nccc\nd"])
        #expect(info.ranges == [NSRange(0, 17)])
        #expect(info.selectedRanges == [NSRange(8, 1), NSRange(13, 0), NSRange(17, 1)])
        
        #expect(string.moveLineDown(in: [NSRange(14, 1)]) == nil)
    }
    
    
    @Test func sortLinesAscending() throws {
        
        let string = """
            ccc
            aa
            bbbb
            """
        var info: String.EditingInfo
        
        #expect(string.sortLinesAscending(in: NSRange(4, 1)) == nil)
        
        info = try #require(string.sortLinesAscending(in: string.nsRange))
        #expect(info.strings == ["aa\nbbbb\nccc"])
        #expect(info.ranges == [NSRange(0, 11)])
        #expect(info.selectedRanges == [NSRange(0, 11)])
        
        info = try #require(string.sortLinesAscending(in: NSRange(2, 4)))
        #expect(info.strings == ["aa\nccc"])
        #expect(info.ranges == [NSRange(0, 6)])
        #expect(info.selectedRanges == [NSRange(0, 6)])
    }
    
    
    @Test func reverseLines() throws {
        
        let string = """
            aa
            bbbb
            ccc
            """
        var info: String.EditingInfo
        
        #expect(string.reverseLines(in: NSRange(4, 1)) == nil)
        
        info = try #require(string.reverseLines(in: string.nsRange))
        #expect(info.strings == ["ccc\nbbbb\naa"])
        #expect(info.ranges == [NSRange(0, 11)])
        #expect(info.selectedRanges == [NSRange(0, 11)])
        
        info = try #require(string.reverseLines(in: NSRange(2, 4)))
        #expect(info.strings == ["bbbb\naa"])
        #expect(info.ranges == [NSRange(0, 7)])
        #expect(info.selectedRanges == [NSRange(0, 7)])
    }
    
    
    @Test func deleteDuplicateLine() throws {
        
        let string = """
            aa
            bbbb
            ccc
            ccc
            bbbb
            """
        var info: String.EditingInfo
        
        #expect(string.deleteDuplicateLine(in: [NSRange(4, 1)]) == nil)
        
        info = try #require(string.deleteDuplicateLine(in: [string.nsRange]))
        #expect(info.strings == ["", ""])
        #expect(info.ranges == [NSRange(12, 4), NSRange(16, 4)])
        #expect(info.selectedRanges == nil)
        
        info = try #require(string.deleteDuplicateLine(in: [NSRange(10, 4)]))
        #expect(info.strings == [""])
        #expect(info.ranges == [NSRange(12, 4)])
        #expect(info.selectedRanges == nil)
        
        info = try #require(string.deleteDuplicateLine(in: [NSRange(9, 1), NSRange(11, 0), NSRange(13, 2)]))
        #expect(info.strings == [""])
        #expect(info.ranges == [NSRange(12, 4)])
        #expect(info.selectedRanges == nil)
    }
    
    
    @Test func duplicateLine() throws {
        
        let string = """
            aa
            bbbb
            ccc
            """
        var info: String.EditingInfo
        
        info = try #require(string.duplicateLine(in: [NSRange(4, 1)], lineEnding: "\n"))
        #expect(info.strings == ["bbbb\n"])
        #expect(info.ranges == [NSRange(3, 0)])
        #expect(info.selectedRanges == [NSRange(9, 1)])
        
        info = try #require(string.duplicateLine(in: [NSRange(4, 1), NSRange(6, 4)], lineEnding: "\n"))
        #expect(info.strings == ["bbbb\nccc\n"])
        #expect(info.ranges == [NSRange(3, 0)])
        #expect(info.selectedRanges == [NSRange(13, 1), NSRange(15, 4)])
        
        info = try #require(string.duplicateLine(in: [NSRange(4, 1), NSRange(6, 1), NSRange(10, 0)], lineEnding: "\n"))
        #expect(info.strings == ["bbbb\n", "ccc\n"])
        #expect(info.ranges == [NSRange(3, 0), NSRange(8, 0)])
        #expect(info.selectedRanges == [NSRange(9, 1), NSRange(11, 1), NSRange(19, 0)])
    }
    
    
    @Test func deleteLine() throws {
        
        let string = """
            aa
            bbbb
            ccc
            """
        var info: String.EditingInfo
        
        info = try #require(string.deleteLine(in: [NSRange(4, 1)]))
        #expect(info.strings == [""])
        #expect(info.ranges == [NSRange(3, 5)])
        #expect(info.selectedRanges == [NSRange(3, 0)])
        
        info = try #require(string.deleteLine(in: [NSRange(4, 1), NSRange(6, 1), NSRange(10, 0)]))
        #expect(info.strings == ["", ""])
        #expect(info.ranges == [NSRange(3, 5), NSRange(8, 3)])
        #expect(info.selectedRanges == [NSRange(3, 0)])
    }
    
    
    @Test func joinLinesIn() {
        
        let string = """
            aa
              bbbb
            ccc
            d
            """
        let info = string.joinLines(in: [NSRange(1, 6), NSRange(10, 1)])
        
        #expect(info.strings == ["a bb", "c"])
        #expect(info.ranges == [NSRange(1, 6), NSRange(10, 1)])
        #expect(info.selectedRanges == [NSRange(1, 4), NSRange(8, 1)])
    }
    
    
    @Test func joinLinesAfter() {
        
        let string = """
            aa
              bbbb
            ccc
            d
            """
        let info = string.joinLines(after: [NSRange(1, 0), NSRange(10, 0), NSRange(14, 0)])
        
        #expect(info.strings == [" ", " "])
        #expect(info.ranges == [NSRange(2, 3), NSRange(13, 1)])
        #expect(info.selectedRanges == nil)
    }
}



// MARK: -

private extension NSRange {
    
    init(_ location: Int, _ length: Int) {
        
        self.init(location: location, length: length)
    }
}
