//
//  StringCommentingTests.swift
//  TextEditingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-11-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2024 1024jp
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
import Syntax
import struct StringUtils.Pair
@testable import TextEditing

struct StringCommentingTests {
    
    // MARK: String extension Tests
    
    @Test func inlineCommentOut() {
        
        #expect("foo".inlineCommentOut(delimiter: "//", ranges: []).isEmpty)
        
        #expect("foo".inlineCommentOut(delimiter: "//", ranges: [NSRange(0..<0)]) ==
                [.init(string: "//", location: 0, forward: true)])
        #expect("foo".inlineCommentOut(delimiter: "//", ranges: [NSRange(1..<2)]) ==
                [.init(string: "//", location: 1, forward: true)])
    }
    
    
    @Test func blockCommentOut() {
        
        #expect("foo".blockCommentOut(delimiters: Pair("<-", "->"), ranges: []).isEmpty)
        
        #expect("foo".blockCommentOut(delimiters: Pair("<-", "->"), ranges: [NSRange(0..<0)]) ==
                [.init(string: "<-", location: 0, forward: true), .init(string: "->", location: 0, forward: false)])
    }
    
    
    @Test func inlineUncomment() {
        
        #expect("foo".rangesOfInlineDelimiter("//", ranges: [])?.isEmpty == true)
        #expect("foo".rangesOfInlineDelimiter("//", ranges: [NSRange(0..<0)])?.isEmpty == true)
        
        #expect("//foo".rangesOfInlineDelimiter("//", ranges: [NSRange(0..<5)]) == [NSRange(0..<2)])
        #expect("// foo".rangesOfInlineDelimiter("//", ranges: [NSRange(0..<5)]) == [NSRange(0..<2)])
        
        #expect("  //foo".rangesOfInlineDelimiter("//", ranges: [NSRange(0..<7)]) == [NSRange(2..<4)])
    }
    
    
    @Test func blockUncomment() {
        
        #expect("foo".rangesOfBlockDelimiters(Pair("<-", "->"), ranges: [])?.isEmpty == true)
        #expect("foo".rangesOfBlockDelimiters(Pair("<-", "->"), ranges: [NSRange(0..<0)])?.isEmpty == true)
        
        #expect("<-foo->".rangesOfBlockDelimiters(Pair("<-", "->"), ranges: [NSRange(0..<7)]) == [NSRange(0..<2), NSRange(5..<7)])
        #expect("<- foo ->".rangesOfBlockDelimiters(Pair("<-", "->"), ranges: [NSRange(0..<9)]) == [NSRange(0..<2), NSRange(7..<9)])
        
        #expect(" <-foo-> ".rangesOfBlockDelimiters(Pair("<-", "->"), ranges: [NSRange(0..<9)]) == [NSRange(1..<3), NSRange(6..<8)])
        #expect(" <-foo-> ".rangesOfBlockDelimiters(Pair("<-", "->"), ranges: [NSRange(1..<7)]) == nil)
        
        // ok, this is currently in spec, but not a good one...
        #expect("<-foo-><-bar->".rangesOfBlockDelimiters(Pair("<-", "->"), ranges: [NSRange(0..<14)]) == [NSRange(0..<2), NSRange(12..<14)])
    }
    
    
    // MARK: TextView extension Tests
    
    @Test func textViewInlineComment() throws {
        
        var editor = Editor(string: "foo\nbar", selectedRanges: [NSRange(0..<3), NSRange(4..<7)])
        
        editor.commentOut(types: .inline, fromLineHead: true)
        #expect(editor.string == "//foo\n//bar")
        #expect(editor.selectedRanges == [NSRange(0..<5), NSRange(6..<11)])
        #expect(editor.canUncomment(partly: false))
        editor.uncomment()
        #expect(editor.string == "foo\nbar")
        #expect(editor.selectedRanges == [NSRange(0..<3), NSRange(4..<7)])
        
        editor.selectedRanges = [NSRange(1..<1), NSRange(5..<5)]
        editor.commentOut(types: .inline, fromLineHead: true)
        #expect(editor.string == "//foo\n//bar")
        #expect(editor.selectedRanges == [NSRange(3..<3), NSRange(9..<9)])
        #expect(editor.canUncomment(partly: false))
        editor.uncomment()
        #expect(editor.string == "foo\nbar")
        #expect(editor.selectedRanges == [NSRange(1..<1), NSRange(5..<5)])
    }
    
    
    @Test func textViewBlockComment() {
        
        var editor = Editor(string: "foo\nbar", selectedRanges: [NSRange(0..<3), NSRange(4..<7)])
        
        editor.commentOut(types: .block, fromLineHead: true)
        #expect(editor.string == "<-foo->\n<-bar->")
        #expect(editor.selectedRanges == [NSRange(0..<7), NSRange(8..<15)])
        #expect(editor.canUncomment(partly: false))
        editor.uncomment()
        #expect(editor.string == "foo\nbar")
        #expect(editor.selectedRanges == [NSRange(0..<3), NSRange(4..<7)])
        
        editor.selectedRanges = [NSRange(1..<1), NSRange(5..<5)]
        editor.commentOut(types: .block, fromLineHead: true)
        #expect(editor.string == "<-foo->\n<-bar->")
        #expect(editor.selectedRanges == [NSRange(3..<3), NSRange(11..<11)])
        #expect(editor.canUncomment(partly: false))
        editor.uncomment()
        #expect(editor.string == "foo\nbar")
        #expect(editor.selectedRanges == [NSRange(1..<1), NSRange(5..<5)])
    }
    
    
    @Test func checkIncompatibility() {
        
        let string = """
            // foo
            //
            // foo bar
            """
        let editor = Editor(string: string, selectedRanges: [string.range])
        
        #expect(editor.canUncomment(partly: false))
        #expect(editor.canUncomment(partly: true))
    }
    
    
    @Test func checkPartialIncompatibility() {
        
        let string = """
            // foo
            
            // foo bar
            """
        let editor = Editor(string: string, selectedRanges: [string.range])
        
        #expect(!editor.canUncomment(partly: false))
        #expect(editor.canUncomment(partly: true))
    }
}


/// TextView mock
private struct Editor {
    
    let delimiters = Syntax.Comment(inline: "//", blockBegin: "<-", blockEnd: "->")
    
    var string: String
    var selectedRanges: [NSRange] = []
    
    
    mutating func commentOut(types: CommentTypes, fromLineHead: Bool) {
        
        guard let contents = self.string.commentOut(types: types, delimiters: self.delimiters, fromLineHead: true, in: self.selectedRanges) else { return }
        
        self.edit(with: contents)
    }
    
    
    mutating func uncomment() {
        
        guard let contents = self.string.uncomment(delimiters: self.delimiters, in: self.selectedRanges) else { return }
        
        self.edit(with: contents)
    }
    
    
    func canUncomment(partly: Bool) -> Bool {
        
        self.string.canUncomment(partly: partly, delimiters: self.delimiters, in: self.selectedRanges)
    }
    
    
    mutating func edit(with context: EditingContext) {
        
        let mutableString = NSMutableString(string: self.string)
        for (string, range) in zip(context.strings, context.ranges).reversed() {
            mutableString.replaceCharacters(in: range, with: string)
        }
        
        self.string = mutableString as String
        self.selectedRanges = context.selectedRanges ?? self.selectedRanges
    }
}
