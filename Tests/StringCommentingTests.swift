//
//  StringCommentingTests.swift
//  Tests
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

import AppKit
import Testing
@testable import CotEditor

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
    
    @MainActor @Test func textViewInlineComment() {
        
        let textView = CommentingTextView()
        
        textView.string = "foo\nbar"
        textView.selectedRanges = [NSRange(0..<3), NSRange(4..<7)] as [NSValue]
        textView.commentOut(types: .inline, fromLineHead: true)
        #expect(textView.string == "//foo\n//bar")
        #expect(textView.selectedRanges == [NSRange(0..<5), NSRange(6..<11)] as [NSValue])
        #expect(textView.canUncomment(partly: false))
        textView.uncomment()
        #expect(textView.string == "foo\nbar")
        #expect(textView.selectedRanges == [NSRange(0..<3), NSRange(4..<7)] as [NSValue])
        
        textView.selectedRanges = [NSRange(1..<1)] as [NSValue]
        textView.insertionLocations = [5]
        textView.commentOut(types: .inline, fromLineHead: true)
        #expect(textView.string == "//foo\n//bar")
        #expect(textView.rangesForUserTextChange == [NSRange(3..<3), NSRange(9..<9)] as [NSValue])
        #expect(textView.canUncomment(partly: false))
        textView.uncomment()
        #expect(textView.string == "foo\nbar")
        #expect(textView.rangesForUserTextChange == [NSRange(1..<1), NSRange(5..<5)] as [NSValue])
    }
    
    
    @MainActor @Test func textViewBlockComment() {
        
        let textView = CommentingTextView()
        
        textView.string = "foo\nbar"
        textView.selectedRanges = [NSRange(0..<3), NSRange(4..<7)] as [NSValue]
        textView.commentOut(types: .block, fromLineHead: true)
        #expect(textView.string == "<-foo->\n<-bar->")
        #expect(textView.selectedRanges == [NSRange(0..<7), NSRange(8..<15)] as [NSValue])
        #expect(textView.canUncomment(partly: false))
        textView.uncomment()
        #expect(textView.string == "foo\nbar")
        #expect(textView.selectedRanges == [NSRange(0..<3), NSRange(4..<7)] as [NSValue])
        
        textView.selectedRanges = [NSRange(1..<1)] as [NSValue]
        textView.insertionLocations = [5]
        textView.commentOut(types: .block, fromLineHead: true)
        #expect(textView.string == "<-foo->\n<-bar->")
        #expect(textView.rangesForUserTextChange == [NSRange(3..<3), NSRange(11..<11)] as [NSValue])
        #expect(textView.canUncomment(partly: false))
        textView.uncomment()
        #expect(textView.string == "foo\nbar")
        #expect(textView.rangesForUserTextChange == [NSRange(1..<1), NSRange(5..<5)] as [NSValue])
    }
    
    
    @MainActor @Test func checkIncompatibility() {
        
        let textView = CommentingTextView()
        
        textView.string = """
            // foo
            //
            // foo bar
            """
        textView.selectedRange = textView.string.nsRange
        #expect(textView.canUncomment(partly: false))
        #expect(textView.canUncomment(partly: true))
        
        textView.string = """
            // foo
            
            // foo bar
            """
        textView.selectedRange = textView.string.nsRange
        #expect(!textView.canUncomment(partly: false))
        #expect(textView.canUncomment(partly: true))
    }
}



private final class CommentingTextView: NSTextView, Commenting, MultiCursorEditing {
    
    // Commenting
    var commentDelimiters = Syntax.Comment(inline: "//", blockBegin: "<-", blockEnd: "->")
    
    // MultiCursorEditing
    var insertionLocations: [Int] = []
    var selectionOrigins: [Int] = []
    var insertionPointTimer: (any DispatchSourceTimer)?
    var insertionPointOn: Bool = false
    var isPerformingRectangularSelection: Bool = false
    var insertionIndicators: [NSTextInsertionIndicator] = []
    
    
    override var rangesForUserTextChange: [NSValue]? {
        
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        let insertionRanges = self.insertionLocations.map { NSRange(location: $0, length: 0) }
        
        return (selectedRanges + insertionRanges).sorted(\.location) as [NSValue]
    }
}
