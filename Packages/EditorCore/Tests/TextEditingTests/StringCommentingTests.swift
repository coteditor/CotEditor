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
//  © 2019-2026 1024jp
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
import struct StringUtils.Pair
@testable import TextEditing

struct StringCommentingTests {
    
    // MARK: String extension Tests
    
    @Test func inlineCommentOut() {
        
        #expect("foo".inlineCommentOut(delimiter: "//", spacer: "", ranges: [], at: .selection).isEmpty)
        
        #expect("foo".inlineCommentOut(delimiter: "//", spacer: "", ranges: [NSRange(0..<0)], at: .selection) ==
                [.init(string: "//", location: 0, forward: true)])
        
        #expect("foo".inlineCommentOut(delimiter: "//", spacer: " ", ranges: [NSRange(0..<0)], at: .selection) ==
                [.init(string: "// ", location: 0, forward: true)])
        #expect("foo".inlineCommentOut(delimiter: "//", spacer: "", ranges: [NSRange(1..<2)], at: .selection) ==
                [.init(string: "//", location: 1, forward: true)])
    }
    
    
    @Test func inlineCommentOutAfterIndent() {
        
        #expect("".inlineCommentOut(delimiter: "//", ranges: [NSRange(0..<0)], at: .afterIndent(tabWidth: 2)) ==
                [.init(string: "//", location: 0, forward: true)])
        
        // inset at level 1
        let text1 = """
          aaaa
            aaa
          aaaa
        """
        #expect(text1.inlineCommentOut(delimiter: "//", ranges: [NSRange(1..<16)], at: .afterIndent(tabWidth: 2)) == [
            .init(string: "//", location: 2, forward: true),
            .init(string: "//", location: 9, forward: true),
            .init(string: "//", location: 17, forward: true),
        ])
        
        let text2 = """
        a
          bb
            ccc
        """
        #expect(text2.inlineCommentOut(delimiter: "//", ranges: [text2.nsRange], at: .afterIndent(tabWidth: 2)).map(\.location) ==
                [0, 2, 7])
        #expect(text2.inlineCommentOut(delimiter: "//", ranges: [NSRange(3..<(text2.count - 2))], at: .afterIndent(tabWidth: 2)).map(\.location) ==
                [4, 9])
        
        // inset at level 1 with spacer
        let text3 = """
          a
          b
        """
        #expect(text3.inlineCommentOut(delimiter: "//", spacer: " ", ranges: [text3.nsRange], at: .afterIndent(tabWidth: 2)) == [
            .init(string: "// ", location: 2, forward: true),
            .init(string: "// ", location: 6, forward: true),
        ])
        
        // inset at level 1 with tab
        let text4 = """
              a
        \t  b
        """
        #expect(text4.inlineCommentOut(delimiter: "//", spacer: " ", ranges: [text4.nsRange], at: .afterIndent(tabWidth: 2)) == [
            .init(string: "// ", location: 4, forward: true),
            .init(string: "// ", location: 11, forward: true),
        ])
    }
    
    
    @Test func blockCommentOut() {
        
        #expect("foo".blockCommentOut(delimiters: Pair("<-", "->"), spacer: "", ranges: [], at: .selection).isEmpty)
        
        #expect("foo".blockCommentOut(delimiters: Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<0)], at: .selection) ==
                [.init(string: "<-", location: 0, forward: true), .init(string: "->", location: 0, forward: false)])
        
        #expect("foo".blockCommentOut(delimiters: Pair("<-", "->"), spacer: " ", ranges: [NSRange(0..<3)], at: .selection) ==
                       [.init(string: "<- ", location: 0, forward: true), .init(string: " ->", location: 3, forward: false)])
        #expect("foo".blockCommentOut(delimiters: Pair("<-", "->"), spacer: " ", ranges: [NSRange(1..<2)], at: .selection) ==
                       [.init(string: "<- ", location: 1, forward: true), .init(string: " ->", location: 2, forward: false)])
    }
    
    
    @Test func blockCommentOutAfterIndent() {
        
        #expect("".blockCommentOut(delimiters: Pair("<-", "->"), ranges: [NSRange(0..<0)], at: .afterIndent(tabWidth: 2)) ==
                [.init(string: "<-", location: 0, forward: true), .init(string: "->", location: 0, forward: false)])
        
        // inset at level 1
        let text1 = """
          aaaa
            aaa
          aaaa
        """
        #expect(text1.blockCommentOut(delimiters: Pair("<-", "->"), ranges: [NSRange(1..<16)], at: .afterIndent(tabWidth: 2)) ==
                [.init(string: "<-", location: 2, forward: true), .init(string: "->", location: 21, forward: false)])
        
        let text2 = """
        a
          bb
            ccc
        """
        #expect(text2.blockCommentOut(delimiters: Pair("<-", "->"), ranges: [text2.nsRange], at: .afterIndent(tabWidth: 2)) ==
                [.init(string: "<-", location: 0, forward: true), .init(string: "->", location: 14, forward: false)])
        #expect(text2.blockCommentOut(delimiters: Pair("<-", "->"), ranges: [NSRange(3..<(text2.count - 2))], at: .afterIndent(tabWidth: 2)) ==
                [.init(string: "<-", location: 4, forward: true), .init(string: "->", location: 14, forward: false)])
        
        // inset at level 1 with spacer
        let text3 = """
          a
          b
        """
        #expect(text3.blockCommentOut(delimiters: Pair("<-", "->"), spacer: " ", ranges: [text3.nsRange], at: .afterIndent(tabWidth: 2)) ==
                [.init(string: "<- ", location: 2, forward: true), .init(string: " ->", location: 7, forward: false)])
        
        // inset at level 1 with tab
        let text4 = """
              a
        \t  b
        """
        #expect(text4.blockCommentOut(delimiters: Pair("<-", "->"), spacer: " ", ranges: [text4.nsRange], at: .afterIndent(tabWidth: 2)) ==
                [.init(string: "<- ", location: 6, forward: true), .init(string: " ->", location: 12, forward: false)])
    }
    
    
    @Test func commentOutWithEmptyDelimiters() {
        
        let delimiters = Delimiters()
        
        let string = "foo"
        let context = string.commentOut(types: .inline, delimiters: delimiters, spacer: "", in: [NSRange(0..<3)], at: .selection)
        
        #expect(context == nil)
    }
    
    
    @Test func commentOutPrefersInline() throws {
        
        let string = "foo"
        let delimiters = Delimiters(inlineDelimiters: ["//"], blocks: [Pair("<-", "->")])
        let context = try #require(string.commentOut(types: .both, delimiters: delimiters, spacer: " ", in: [NSRange(0..<3)], at: .selection))
        
        #expect(context.strings == ["// "])
        #expect(context.ranges == [NSRange(location: 0, length: 0)])
        #expect(context.selectedRanges == [NSRange(location: 0, length: 6)])
    }
    
    
    @Test func uncommentPrefersBlock() throws {
        
        let string = "<-foo->"
        let delimiters = Delimiters(inlineDelimiters: ["//"], blocks: [Pair("<-", "->")])
        let context = try #require(string.uncomment(delimiters: delimiters, spacer: "", in: [NSRange(0..<7)]))
        
        #expect(context.strings == ["", ""])
        #expect(context.ranges == [NSRange(0..<2), NSRange(5..<7)])
        #expect(context.selectedRanges == [NSRange(0..<3)])
    }
    
    
    @Test func canUncommentWithEmptyDelimiters() {
        
        let delimiters = Delimiters()
        
        #expect(!"// foo".canUncomment(partly: false, delimiters: delimiters, in: [NSRange(0..<6)]))
    }
    
    
    @Test func inlineUncomment() {
        
        #expect("foo".rangesOfInlineDelimiter("//", spacer: "", ranges: [])?.isEmpty == true)
        #expect("foo".rangesOfInlineDelimiter("//", spacer: "", ranges: [NSRange(0..<0)])?.isEmpty == true)
        
        #expect("//foo".rangesOfInlineDelimiter("//", spacer: "", ranges: [NSRange(0..<5)]) == [NSRange(0..<2)])
        #expect("//foo".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<5)]) == [NSRange(0..<2)])
        #expect("// foo".rangesOfInlineDelimiter("//", spacer: "", ranges: [NSRange(0..<5)]) == [NSRange(0..<2)])
        #expect("// foo".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<5)]) == [NSRange(0..<3)])
        
        #expect("  //foo".rangesOfInlineDelimiter("//", spacer: "", ranges: [NSRange(0..<7)]) == [NSRange(2..<4)])
        #expect("// foo".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<1)]) == nil)
        #expect("// foo".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(1..<3)]) == nil)
        #expect("// foo".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<2)]) == [NSRange(0..<2)])
        
        #expect("// foo\n//bar".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<12)]) == [NSRange(0..<3), NSRange(7..<9)])
        #expect(" //foo\n//bar".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<12)]) == [NSRange(1..<3), NSRange(7..<9)])
        #expect(" //foo\n//bar".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<3), NSRange(0..<6)]) == [NSRange(1..<3)])
        
        #expect("// foo\n//bar".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<5), NSRange(7..<12)]) == [NSRange(0..<3), NSRange(7..<9)])
    }
    
    
    @Test func blockUncomment() {
        
        #expect("foo".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [])?.isEmpty == true)
        #expect("foo".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<0)])?.isEmpty == true)
        
        #expect("<-foo->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<7)]) == [NSRange(0..<2), NSRange(5..<7)])
        #expect("<-foo->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: " ", ranges: [NSRange(0..<7)]) == [NSRange(0..<2), NSRange(5..<7)])
        #expect("<- foo ->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<9)]) == [NSRange(0..<2), NSRange(7..<9)])
        #expect("<- foo ->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: " ", ranges: [NSRange(0..<9)]) == [NSRange(0..<3), NSRange(6..<9)])
        
        #expect(" <-foo-> ".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<9)]) == [NSRange(1..<3), NSRange(6..<8)])
        #expect(" <-foo-> ".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(1..<7)]) == nil)
        
        // ok, this is currently in spec, but not a good one...
        #expect("<-foo-><-bar->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<14)]) == [NSRange(0..<2), NSRange(12..<14)])
        #expect("<- foo ->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: " ", ranges: [NSRange(0..<3), NSRange(6..<9)]) == nil)
        
        #expect("a<- foo ->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<3), NSRange(6..<9)]) == nil)
    }
    
    
    // MARK: TextView extension Tests
    
    @Test func textViewInlineComment() throws {
        
        var editor = Editor(string: "foo\nbar", selectedRanges: [NSRange(0..<3), NSRange(4..<7)])
        
        editor.commentOut(types: .inline, at: .line)
        #expect(editor.string == "//foo\n//bar")
        #expect(editor.selectedRanges == [NSRange(0..<5), NSRange(6..<11)])
        #expect(editor.canUncomment(partly: false))
        editor.uncomment()
        #expect(editor.string == "foo\nbar")
        #expect(editor.selectedRanges == [NSRange(0..<3), NSRange(4..<7)])
        
        editor.selectedRanges = [NSRange(1..<1), NSRange(5..<5)]
        editor.commentOut(types: .inline, at: .line)
        #expect(editor.string == "//foo\n//bar")
        #expect(editor.selectedRanges == [NSRange(3..<3), NSRange(9..<9)])
        #expect(editor.canUncomment(partly: false))
        editor.uncomment()
        #expect(editor.string == "foo\nbar")
        #expect(editor.selectedRanges == [NSRange(1..<1), NSRange(5..<5)])
    }
    
    
    @Test func textViewBlockComment() {
        
        var editor = Editor(string: "foo\nbar", selectedRanges: [NSRange(0..<3), NSRange(4..<7)])
        
        editor.commentOut(types: .block, at: .line)
        #expect(editor.string == "<-foo->\n<-bar->")
        #expect(editor.selectedRanges == [NSRange(0..<7), NSRange(8..<15)])
        #expect(editor.canUncomment(partly: false))
        editor.uncomment()
        #expect(editor.string == "foo\nbar")
        #expect(editor.selectedRanges == [NSRange(0..<3), NSRange(4..<7)])
        
        editor.selectedRanges = [NSRange(1..<1), NSRange(5..<5)]
        editor.commentOut(types: .block, at: .line)
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


// MARK: - Mocks

private struct Delimiters: CommentDelimiters {
    
    var inlineDelimiters: [String] = []
    var blocks: [Pair<String>] = []
    
    var isEmpty: Bool { self.inlineDelimiters.isEmpty && self.blocks.isEmpty }
}


/// TextView mock
private struct Editor {
    
    private let delimiters = Delimiters(inlineDelimiters: ["//"], blocks: [Pair("<-", "->")])
    
    var string: String
    var selectedRanges: [NSRange] = []
    
    
    mutating func commentOut(types: CommentTypes, spacer: String = "", at location: CommentOutLocation) {
        
        guard let context = self.string.commentOut(types: types, delimiters: self.delimiters, spacer: spacer, in: self.selectedRanges, at: location) else { return }
        
        self.edit(with: context)
    }
    
    
    mutating func uncomment(spacer: String = "") {
        
        guard let context = self.string.uncomment(delimiters: self.delimiters, spacer: spacer, in: self.selectedRanges) else { return }
        
        self.edit(with: context)
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
