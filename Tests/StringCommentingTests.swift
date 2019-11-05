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
//  © 2019 1024jp
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

class StringCommentingTests: XCTestCase {
    
    // MARK: NSRange extension Tests
    
    func testRangeInsrtion() {
        
        XCTAssertEqual(NSRange(0..<0).inserted(items: []), NSRange(0..<0))
        XCTAssertEqual(NSRange(0..<0).inserted(items: [.init(string: "", location: 0, forward: true)]), NSRange(0..<0))
        
        XCTAssertEqual(NSRange(0..<0).inserted(items: [.init(string: "abc", location: 0, forward: true)]), NSRange(3..<3))
        XCTAssertEqual(NSRange(0..<0).inserted(items: [.init(string: "abc", location: 0, forward: false)]), NSRange(0..<0))
        XCTAssertEqual(NSRange(1..<1).inserted(items: [.init(string: "abc", location: 0, forward: false)]), NSRange(4..<4))
        XCTAssertEqual(NSRange(0..<5).inserted(items: [.init(string: "abc", location: 2, forward: true)]), NSRange(0..<8))
        XCTAssertEqual(NSRange(0..<5).inserted(items: [.init(string: "abc", location: 6, forward: true)]), NSRange(0..<5))
        
        XCTAssertEqual(NSRange(2..<2).inserted(items: [.init(string: "abc", location: 2, forward: true),
                                                       .init(string: "abc", location: 2, forward: false)]), NSRange(5..<5))
        XCTAssertEqual(NSRange(2..<3).inserted(items: [.init(string: "abc", location: 2, forward: true),
                                                       .init(string: "abc", location: 2, forward: false)]), NSRange(2..<6))
        XCTAssertEqual(NSRange(2..<3).inserted(items: [.init(string: "abc", location: 3, forward: true),
                                                       .init(string: "abc", location: 3, forward: false)]), NSRange(2..<6))
    }
    
    
    func testRangeDeletion() {
        
        XCTAssertEqual(NSRange(0..<0).deleted(ranges: []), NSRange(0..<0))
        XCTAssertEqual(NSRange(0..<0).deleted(ranges: [NSRange(0..<0)]), NSRange(0..<0))
        
        XCTAssertEqual(NSRange(0..<10).deleted(ranges: [NSRange(2..<4)]), NSRange(0..<8))
        XCTAssertEqual(NSRange(1..<10).deleted(ranges: [NSRange(0..<2)]), NSRange(0..<8))
        XCTAssertEqual(NSRange(1..<10).deleted(ranges: [NSRange(11..<20)]), NSRange(1..<10))
        
        XCTAssertEqual(NSRange(1..<10).deleted(ranges: [NSRange(2..<4), NSRange(3..<5)]), NSRange(1..<7))
        XCTAssertEqual(NSRange(1..<10).deleted(ranges: [NSRange(0..<2), NSRange(3..<5), NSRange(9..<20)]), NSRange(0..<5))
    }
    
    
    
    // MARK: String extension Tests
    
    func testInlineCommentOut() {
        
        XCTAssertEqual("foo".inlineCommentOut(delimiter: "//", spacer: "", ranges: []), [])
        
        XCTAssertEqual("foo".inlineCommentOut(delimiter: "//", spacer: "", ranges: [NSRange(0..<0)]),
                       [.init(string: "//", location: 0, forward: true)])
        XCTAssertEqual("foo".inlineCommentOut(delimiter: "//", spacer: " ", ranges: [NSRange(0..<0)]),
                       [.init(string: "// ", location: 0, forward: true)])
        XCTAssertEqual("foo".inlineCommentOut(delimiter: "//", spacer: "", ranges: [NSRange(1..<2)]),
                       [.init(string: "//", location: 1, forward: true)])
    }
    
    
    func testBlockCommentOut() {
        
        XCTAssertEqual("foo".blockCommentOut(delimiters: Pair("<-", "->"), spacer: "", ranges: []), [])
        
        XCTAssertEqual("foo".blockCommentOut(delimiters: Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<0)]),
                       [.init(string: "<-", location: 0, forward: true), .init(string: "->", location: 0, forward: false)])
        XCTAssertEqual("foo".blockCommentOut(delimiters: Pair("<-", "->"), spacer: " ", ranges: [NSRange(0..<3)]),
                       [.init(string: "<- ", location: 0, forward: true), .init(string: " ->", location: 3, forward: false)])
        XCTAssertEqual("foo".blockCommentOut(delimiters: Pair("<-", "->"), spacer: " ", ranges: [NSRange(1..<2)]),
                       [.init(string: "<- ", location: 1, forward: true), .init(string: " ->", location: 2, forward: false)])
    }
    
    
    func testInlineUncomment() {
        
        XCTAssertEqual("foo".rangesOfInlineDelimiter("//", spacer: "", ranges: []), [])
        XCTAssertEqual("foo".rangesOfInlineDelimiter("//", spacer: "", ranges: [NSRange(0..<0)]), [])
        
        XCTAssertEqual("//foo".rangesOfInlineDelimiter("//", spacer: "", ranges: [NSRange(0..<5)]), [NSRange(0..<2)])
        XCTAssertEqual("//foo".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<5)]), [NSRange(0..<2)])
        XCTAssertEqual("// foo".rangesOfInlineDelimiter("//", spacer: "", ranges: [NSRange(0..<5)]), [NSRange(0..<2)])
        XCTAssertEqual("// foo".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<5)]), [NSRange(0..<3)])
        
        XCTAssertEqual("  //foo".rangesOfInlineDelimiter("//", spacer: "", ranges: [NSRange(0..<7)]), [NSRange(2..<4)])
        XCTAssertNil("// foo".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<1)]))
        XCTAssertNil("// foo".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(1..<3)]))
        XCTAssertEqual("// foo".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<2)]), [NSRange(0..<2)])
        
        XCTAssertEqual("// foo\n//bar".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<12)]), [NSRange(0..<3), NSRange(7..<9)])
        XCTAssertEqual(" //foo\n//bar".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<12)]), [NSRange(1..<3), NSRange(7..<9)])
        XCTAssertEqual(" //foo\n//bar".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<3), NSRange(0..<6)]), [NSRange(1..<3)])
        
        XCTAssertEqual("// foo\n//bar".rangesOfInlineDelimiter("//", spacer: " ", ranges: [NSRange(0..<5), NSRange(7..<12)]), [NSRange(0..<3), NSRange(7..<9)])
    }

    
    func testBlockUncomment() {
        
        XCTAssertEqual("foo".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: []), [])
        XCTAssertEqual("foo".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<0)]), [])
        
        XCTAssertEqual("<-foo->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<7)]), [NSRange(0..<2), NSRange(5..<7)])
        XCTAssertEqual("<-foo->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: " ", ranges: [NSRange(0..<7)]), [NSRange(0..<2), NSRange(5..<7)])
        XCTAssertEqual("<- foo ->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<9)]), [NSRange(0..<2), NSRange(7..<9)])
        XCTAssertEqual("<- foo ->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: " ", ranges: [NSRange(0..<9)]), [NSRange(0..<3), NSRange(6..<9)])
        
        XCTAssertEqual(" <-foo-> ".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<9)]), [NSRange(1..<3), NSRange(6..<8)])
        XCTAssertNil(" <-foo-> ".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(1..<7)]))
        
        // ok, this is currently in spec, but not a good one...
        XCTAssertEqual("<-foo-><-bar->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: "", ranges: [NSRange(0..<14)]), [NSRange(0..<2), NSRange(12..<14)])
        
        XCTAssertNil("<- foo ->".rangesOfBlockDelimiters(Pair("<-", "->"), spacer: " ", ranges: [NSRange(0..<3), NSRange(6..<9)]))
    }
    
    
    
    // MARK: TextView extension Tests
    
    func testTextViewInlineComment() {
        
        let textView = CommentingTextView()
        
        textView.string = "foo\nbar"
        textView.selectedRanges = [NSRange(0..<3), NSRange(4..<7)] as [NSValue]
        textView.commentOut(types: .inline, fromLineHead: true)
        XCTAssertEqual(textView.string, "// foo\n// bar")
        XCTAssertEqual(textView.selectedRanges, [NSRange(0..<6), NSRange(7..<13)] as [NSValue])
        XCTAssertTrue(textView.canUncomment(partly: false))
        textView.uncomment(fromLineHead: true)
        XCTAssertEqual(textView.string, "foo\nbar")
        XCTAssertEqual(textView.selectedRanges, [NSRange(0..<3), NSRange(4..<7)] as [NSValue])
        
        textView.selectedRanges = [NSRange(1..<1)] as [NSValue]
        textView.insertionLocations = [5]
        textView.commentOut(types: .inline, fromLineHead: true)
        XCTAssertEqual(textView.string, "// foo\n// bar")
        XCTAssertEqual(textView.rangesForUserTextChange, [NSRange(4..<4), NSRange(11..<11)] as [NSValue])
        XCTAssertFalse(textView.canUncomment(partly: false))
        textView.uncomment(fromLineHead: true)
        XCTAssertEqual(textView.string, "foo\nbar")
        XCTAssertEqual(textView.rangesForUserTextChange, [NSRange(1..<1), NSRange(5..<5)] as [NSValue])
    }
        
    
    func testTextViewBlockComment() {
        
        let textView = CommentingTextView()
        
        textView.string = "foo\nbar"
        textView.selectedRanges = [NSRange(0..<3), NSRange(4..<7)] as [NSValue]
        textView.commentOut(types: .block, fromLineHead: true)
        XCTAssertEqual(textView.string, "<- foo ->\n<- bar ->")
        XCTAssertEqual(textView.selectedRanges, [NSRange(0..<9), NSRange(10..<19)] as [NSValue])
        XCTAssertTrue(textView.canUncomment(partly: false))
        textView.uncomment(fromLineHead: true)
        XCTAssertEqual(textView.string, "foo\nbar")
        XCTAssertEqual(textView.selectedRanges, [NSRange(0..<3), NSRange(4..<7)] as [NSValue])
        
        textView.selectedRanges = [NSRange(1..<1)] as [NSValue]
        textView.insertionLocations = [5]
        textView.commentOut(types: .block, fromLineHead: true)
        XCTAssertEqual(textView.string, "<- foo ->\n<- bar ->")
        XCTAssertEqual(textView.rangesForUserTextChange, [NSRange(4..<4), NSRange(14..<14)] as [NSValue])
        XCTAssertFalse(textView.canUncomment(partly: false))
        textView.uncomment(fromLineHead: true)
        XCTAssertEqual(textView.string, "foo\nbar")
        XCTAssertEqual(textView.rangesForUserTextChange, [NSRange(1..<1), NSRange(5..<5)] as [NSValue])
    }
    
    
    func testUncommentability() {
        
        let textView = CommentingTextView()
        
        textView.string = """
        // foo
        //
        // foo bar
        """
        textView.selectedRange = textView.string.nsRange
        XCTAssertTrue(textView.canUncomment(partly: false))
        XCTAssertTrue(textView.canUncomment(partly: true))
        
        textView.string = """
        // foo
        
        // foo bar
        """
        textView.selectedRange = textView.string.nsRange
        XCTAssertFalse(textView.canUncomment(partly: false))
        XCTAssertTrue(textView.canUncomment(partly: true))
    }
    
}



private final class CommentingTextView: NSTextView, Commenting, MultiCursorEditing {
    
    // Commenting
    var inlineCommentDelimiter: String? = "//"
    var blockCommentDelimiters: Pair<String>? = Pair("<-", "->")
    var appendsCommentSpacer: Bool = true
    var commentsAtLineHead: Bool = false
    
    // MultiCursorEditing
    var insertionLocations: [Int] = []
    var selectionOrigins: [Int] = []
    var insertionPointTimer: DispatchSourceTimer?
    var insertionPointOn: Bool = false
    var isPerformingRectangularSelection: Bool = false
    
    
    override var rangesForUserTextChange: [NSValue]? {
        
        return self.selectedRanges + self.insertionLocations.map { NSValue(range: NSRange($0..<$0)) }
    }
    
}
