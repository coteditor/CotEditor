//
//  StringIndentationTests.swift
//  TextEditingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2026 1024jp
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

struct StringIndentationTests {
    
    // MARK: Indentation Style Detection Tests
    
    @Test func detectIndentStyle() {
        
        let string = "\t\tfoo\tbar"
        
        #expect(string.detectedIndentStyle == nil)
    }
    
    
    // MARK: Indentation Style Standardization Tests
    
    @Test func standardizeIndentStyleToTab() {
        
        let string = "     foo    bar\n  "
        
        // spaces to tab
        #expect(string.standardizingIndent(to: .tab, tabWidth: 2) == "\t\t foo    bar\n\t")
        #expect(string.standardizingIndent(to: .space, tabWidth: 2) == string)
    }
    
    
    @Test func standardizeIndentStyleToSpace() {
        
        let string = "\t\tfoo\tbar"
        
        #expect(string.standardizingIndent(to: .space, tabWidth: 2) == "    foo\tbar")
        #expect(string.standardizingIndent(to: .tab, tabWidth: 2) == string)
    }
    
    
    // MARK: Text Editing Tests
    
    @Test func indent() {
        
        let string = "foo\nbar\nbaz"
        let range = NSRange(location: 4, length: 3)
        
        let context = string.indent(style: .space, indentWidth: 2, in: [range])
        
        #expect(context.strings == ["  bar\n"])
        #expect(context.ranges == [NSRange(location: 4, length: 4)])
        #expect(context.selectedRanges == [NSRange(location: 6, length: 3)])
    }
    
    
    @Test func outdent() throws {
        
        let string = "  foo\n\tbar\nbaz"
        let range = NSRange(location: 0, length: string.utf16.count)
        
        let context = try #require(string.outdent(style: .space, indentWidth: 2, in: [range]))
        
        #expect(context.strings == ["foo\n", "bar\n", "baz"])
        #expect(context.ranges == [
            NSRange(location: 0, length: 6),
            NSRange(location: 6, length: 5),
            NSRange(location: 11, length: 3),
        ])
        #expect(context.selectedRanges == [NSRange(location: 0, length: range.length - 3)])
    }
    
    
    @Test func outdentNoChange() {
        
        let string = "foo\nbar"
        let range = NSRange(location: 0, length: string.utf16.count)
        
        #expect(string.outdent(style: .space, indentWidth: 2, in: [range]) == nil)
    }
    
    @Test func smartOutdentLevel() {
        
        let string = "{\n    foo\n    "
        let range = NSRange(location: string.utf16.count, length: 0)
        
        #expect(string.smartOutdentLevel(with: "}", indentWidth: 4, in: range) == 1)
        #expect(string.smartOutdentLevel(with: ")", indentWidth: 4, in: range) == 0)
        
        let noOutdentString = "{\n    foo\n    bar"
        let noOutdentRange = NSRange(location: noOutdentString.utf16.count, length: 0)
        
        #expect(noOutdentString.smartOutdentLevel(with: "}", indentWidth: 4, in: noOutdentRange) == 0)
    }
    
    
    @Test func convertIndentation() throws {
        
        #expect("".convertIndentation(to: .space, indentWidth: 2, in: [NSRange(0..<0)]) == nil)
        
        let string = "\tfoo\n\tbar"
        let range = NSRange(location: 0, length: 0)
        let context = try #require(string.convertIndentation(to: .space, indentWidth: 2, in: [range]))
        
        #expect(context.strings == ["  foo\n  bar"])
        #expect(context.ranges == [NSRange(location: 0, length: string.utf16.count)])
        #expect(context.selectedRanges == nil)
    }
    
    
    // MARK: Editing Range Detection Tests
    
    @Test func rangeOfIndent() {
        
        let string = "  foo\n\tbar\nbaz"
        
        #expect(string.rangeOfIndent(at: 0) == NSRange(location: 0, length: 2))
        #expect(string.rangeOfIndent(at: 3) == NSRange(location: 0, length: 2))
        #expect(string.rangeOfIndent(at: 7) == NSRange(location: 6, length: 1))
        #expect(string.rangeOfIndent(at: 11) == nil)
        
        let index = string.index(string.startIndex, offsetBy: 7)
        #expect(string.rangeOfIndent(at: index) == string.index(string.startIndex, offsetBy: 6)..<string.index(string.startIndex, offsetBy: 7))
    }
    
    @Test func detectIndentLevel() {
        
        #expect("    foo".indentLevel(at: 0, tabWidth: 4) == 1)
        #expect("    foo".indentLevel(at: 4, tabWidth: 2) == 2)
        #expect("\tfoo".indentLevel(at: 4, tabWidth: 2) == 1)
        
        // tab-space mix
        #expect("  \t foo".indentLevel(at: 4, tabWidth: 2) == 2)
        #expect("   \t foo".indentLevel(at: 4, tabWidth: 2) == 3)
        
        // multiline
        #expect("    foo\n  bar".indentLevel(at: 10, tabWidth: 2) == 1)
    }
    
    
    @Test func softTab() {
        
        #expect("abc".softTab(at: 0, tabWidth: 4) == "    ")
        #expect("abc".softTab(at: 2, tabWidth: 4) == "  ")
        #expect("\t".softTab(at: 1, tabWidth: 4) == "    ")
    }
    
    
    @Test func deleteSoftTab() {
        
        let string = "     foo\n  bar   "
        
        #expect(string.rangeForSoftTabDeletion(in: NSRange(0..<0), tabWidth: 2) == nil)
        #expect(string.rangeForSoftTabDeletion(in: NSRange(4..<5), tabWidth: 2) == nil)
        #expect(string.rangeForSoftTabDeletion(in: NSRange(6..<6), tabWidth: 2) == nil)
        #expect(string.rangeForSoftTabDeletion(in: NSRange(5..<5), tabWidth: 2) == NSRange(4..<5))
        #expect(string.rangeForSoftTabDeletion(in: NSRange(4..<4), tabWidth: 2) == NSRange(2..<4))
        #expect(string.rangeForSoftTabDeletion(in: NSRange(10..<10), tabWidth: 2) == nil)
        #expect(string.rangeForSoftTabDeletion(in: NSRange(11..<11), tabWidth: 2) == NSRange(9..<11))
        #expect(string.rangeForSoftTabDeletion(in: NSRange(16..<16), tabWidth: 2) == nil)
    }
}


private extension String {
    
    func indentLevel(at location: Int, tabWidth: Int) -> Int {
        
        let index = self.index(self.startIndex, offsetBy: location)
        
        return self.indentLevel(at: index, tabWidth: tabWidth)
    }
}
