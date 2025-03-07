//
//  StringLineProcessingTests.swift
//  TextEditingTests
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
@testable import TextEditing

struct StringLineProcessingTests {
    
    @Test func moveLineUp() throws {
        
        let string = """
            aa
            bbbb
            ccc
            d
            eee
            """
        var context: EditingContext
        
        context = try #require(string.moveLineUp(in: [NSRange(4, 1)]))
        #expect(context.strings == ["bbbb\naa\n"])
        #expect(context.ranges == [NSRange(0, 8)])
        #expect(context.selectedRanges == [NSRange(1, 1)])
        
        context = try #require(string.moveLineUp(in: [NSRange(4, 1), NSRange(6, 0)]))
        #expect(context.strings == ["bbbb\naa\n"])
        #expect(context.ranges == [NSRange(0, 8)])
        #expect(context.selectedRanges == [NSRange(1, 1), NSRange(3, 0)])
        
        context = try #require(string.moveLineUp(in: [NSRange(4, 1), NSRange(9, 0), NSRange(15, 1)]))
        #expect(context.strings == ["bbbb\nccc\naa\neee\nd"])
        #expect(context.ranges == [NSRange(0, 17)])
        #expect(context.selectedRanges == [NSRange(1, 1), NSRange(6, 0), NSRange(13, 1)])
        
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
        var context: EditingContext
        
        context = try #require(string.moveLineDown(in: [NSRange(4, 1)]))
        #expect(context.strings == ["aa\nccc\nbbbb\n"])
        #expect(context.ranges == [NSRange(0, 12)])
        #expect(context.selectedRanges == [NSRange(8, 1)])
        
        context = try #require(string.moveLineDown(in: [NSRange(4, 1), NSRange(6, 0)]))
        #expect(context.strings == ["aa\nccc\nbbbb\n"])
        #expect(context.ranges == [NSRange(0, 12)])
        #expect(context.selectedRanges == [NSRange(8, 1), NSRange(10, 0)])
        
        context = try #require(string.moveLineDown(in: [NSRange(4, 1), NSRange(9, 0), NSRange(13, 1)]))
        #expect(context.strings == ["aa\neee\nbbbb\nccc\nd"])
        #expect(context.ranges == [NSRange(0, 17)])
        #expect(context.selectedRanges == [NSRange(8, 1), NSRange(13, 0), NSRange(17, 1)])
        
        #expect(string.moveLineDown(in: [NSRange(14, 1)]) == nil)
    }
    
    
    @Test func sortLinesAscending() throws {
        
        let string = """
            ccc
            aa
            bbbb
            """
        var context: EditingContext
        
        #expect(string.sortLinesAscending(in: NSRange(4, 1)) == nil)
        
        context = try #require(string.sortLinesAscending(in: string.range))
        #expect(context.strings == ["aa\nbbbb\nccc"])
        #expect(context.ranges == [NSRange(0, 11)])
        #expect(context.selectedRanges == [NSRange(0, 11)])
        
        context = try #require(string.sortLinesAscending(in: NSRange(2, 4)))
        #expect(context.strings == ["aa\nccc"])
        #expect(context.ranges == [NSRange(0, 6)])
        #expect(context.selectedRanges == [NSRange(0, 6)])
    }
    
    
    @Test func reverseLines() throws {
        
        let string = """
            aa
            bbbb
            ccc
            """
        var context: EditingContext
        
        #expect(string.reverseLines(in: NSRange(4, 1)) == nil)
        
        context = try #require(string.reverseLines(in: string.range))
        #expect(context.strings == ["ccc\nbbbb\naa"])
        #expect(context.ranges == [NSRange(0, 11)])
        #expect(context.selectedRanges == [NSRange(0, 11)])
        
        context = try #require(string.reverseLines(in: NSRange(2, 4)))
        #expect(context.strings == ["bbbb\naa"])
        #expect(context.ranges == [NSRange(0, 7)])
        #expect(context.selectedRanges == [NSRange(0, 7)])
    }
    
    
    @Test func deleteDuplicateLine() throws {
        
        let string = """
            aa
            bbbb
            ccc
            ccc
            bbbb
            """
        var context: EditingContext
        
        #expect(string.deleteDuplicateLine(in: [NSRange(4, 1)]) == nil)
        
        context = try #require(string.deleteDuplicateLine(in: [string.range]))
        #expect(context.strings == ["", ""])
        #expect(context.ranges == [NSRange(12, 4), NSRange(16, 4)])
        #expect(context.selectedRanges == nil)
        
        context = try #require(string.deleteDuplicateLine(in: [NSRange(10, 4)]))
        #expect(context.strings == [""])
        #expect(context.ranges == [NSRange(12, 4)])
        #expect(context.selectedRanges == nil)
        
        context = try #require(string.deleteDuplicateLine(in: [NSRange(9, 1), NSRange(11, 0), NSRange(13, 2)]))
        #expect(context.strings == [""])
        #expect(context.ranges == [NSRange(12, 4)])
        #expect(context.selectedRanges == nil)
    }
    
    
    @Test func duplicateLine() throws {
        
        let string = """
            aa
            bbbb
            ccc
            """
        var context: EditingContext
        
        context = try #require(string.duplicateLine(in: [NSRange(4, 1)], lineEnding: "\n"))
        #expect(context.strings == ["bbbb\n"])
        #expect(context.ranges == [NSRange(3, 0)])
        #expect(context.selectedRanges == [NSRange(9, 1)])
        
        context = try #require(string.duplicateLine(in: [NSRange(4, 1), NSRange(6, 4)], lineEnding: "\n"))
        #expect(context.strings == ["bbbb\nccc\n"])
        #expect(context.ranges == [NSRange(3, 0)])
        #expect(context.selectedRanges == [NSRange(13, 1), NSRange(15, 4)])
        
        context = try #require(string.duplicateLine(in: [NSRange(4, 1), NSRange(6, 1), NSRange(10, 0)], lineEnding: "\n"))
        #expect(context.strings == ["bbbb\n", "ccc\n"])
        #expect(context.ranges == [NSRange(3, 0), NSRange(8, 0)])
        #expect(context.selectedRanges == [NSRange(9, 1), NSRange(11, 1), NSRange(19, 0)])
    }
    
    
    @Test func deleteLine() throws {
        
        let string = """
            aa
            bbbb
            ccc
            """
        var context: EditingContext
        
        context = try #require(string.deleteLine(in: [NSRange(4, 1)]))
        #expect(context.strings == [""])
        #expect(context.ranges == [NSRange(3, 5)])
        #expect(context.selectedRanges == [NSRange(3, 0)])
        
        context = try #require(string.deleteLine(in: [NSRange(4, 1), NSRange(6, 1), NSRange(10, 0)]))
        #expect(context.strings == ["", ""])
        #expect(context.ranges == [NSRange(3, 5), NSRange(8, 3)])
        #expect(context.selectedRanges == [NSRange(3, 0)])
    }
    
    
    @Test func joinLinesIn() {
        
        let string = """
            aa
              bbbb
            ccc
            d
            """
        let context = string.joinLines(in: [NSRange(1, 6), NSRange(10, 1)])
        
        #expect(context.strings == ["a bb", "c"])
        #expect(context.ranges == [NSRange(1, 6), NSRange(10, 1)])
        #expect(context.selectedRanges == [NSRange(1, 4), NSRange(8, 1)])
    }
    
    
    @Test func joinLinesAfter() {
        
        let string = """
            aa
              bbbb
            ccc
            d
            """
        let context = string.joinLines(after: [NSRange(1, 0), NSRange(10, 0), NSRange(14, 0)])
        
        #expect(context.strings == [" ", " "])
        #expect(context.ranges == [NSRange(2, 3), NSRange(13, 1)])
        #expect(context.selectedRanges == nil)
    }
}


struct StringTrimmingTests {
    
    @Test func trimWhitespace() throws {
        
        let string = """
            
            abc def
                \t
            white space -> \t
            abc
            """
        
        let trimmed = try string.trim(ranges: string.rangesOfTrailingWhitespace(ignoringEmptyLines: false))
        let expectedTrimmed = """
            
            abc def
            
            white space ->
            abc
            """
        #expect(trimmed == expectedTrimmed)
        
        let trimmedIgnoringEmptyLines = try string.trim(ranges: string.rangesOfTrailingWhitespace(ignoringEmptyLines: true))
        let expectedTrimmedIgnoringEmptyLines = """
            
            abc def
                \t
            white space ->
            abc
            """
        #expect(trimmedIgnoringEmptyLines == expectedTrimmedIgnoringEmptyLines)
    }
}


// MARK: -

private extension String {
    
    func trim(ranges: [NSRange]) throws -> String {
        
        try ranges.reversed()
            .map { try #require(Range($0, in: self)) }
            .reduce(self) { $0.replacingCharacters(in: $1, with: "") }
    }
}


private extension NSRange {
    
    init(_ location: Int, _ length: Int) {
        
        self.init(location: location, length: length)
    }
}
