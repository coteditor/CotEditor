//
//  StringEditingTests.swift
//  TextEditingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by OpenAI Codex on 2026-03-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

struct StringEditingTests {
    
    @Test func surround() throws {
        
        let string = "foo\nbar\nbaz"
        let context = try #require(string.surround(in: [NSRange(0..<3), NSRange(4..<4), NSRange(8..<11)], begin: "<", end: ">"))
        
        #expect(context.strings == ["<foo>", "<>", "<baz>"])
        #expect(context.ranges == [NSRange(0..<3), NSRange(4..<4), NSRange(8..<11)])
        #expect(context.selectedRanges == [NSRange(1..<4), NSRange(7..<7), NSRange(13..<16)])
        #expect(string.applying(context) == "<foo>\n<>bar\n<baz>")
    }
    
    
    @Test func surroundWithoutRanges() {
        
        #expect("foo".surround(in: [], begin: "(", end: ")") == nil)
    }
    
    
    @Test func transformSelections() throws {
        
        let string = "foo bar baz"
        let context = try #require(string.transformSelections(in: [NSRange(0..<3), NSRange(4..<4), NSRange(8..<11)]) { "<\($0)>" })
        
        #expect(context.strings == ["<foo>", "<baz>"])
        #expect(context.ranges == [NSRange(0..<3), NSRange(8..<11)])
        #expect(context.selectedRanges == [NSRange(0..<5), NSRange(10..<15)])
        #expect(string.applying(context) == "<foo> bar <baz>")
    }
    
    
    @Test func transformSelectionsWithoutNonEmptyRanges() {
        
        #expect("foo".transformSelections(in: [NSRange(0..<0), NSRange(3..<3)]) { $0.uppercased() } == nil)
    }
}


private extension String {
    
    func applying(_ context: EditingContext) -> String {
        
        let string = NSMutableString(string: self)
        
        for (replacementString, range) in zip(context.strings, context.ranges).reversed() {
            string.replaceCharacters(in: range, with: replacementString)
        }
        
        return string as String
    }
}
