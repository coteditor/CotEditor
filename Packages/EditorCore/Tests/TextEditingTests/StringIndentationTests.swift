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
//  © 2015-2024 1024jp
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
    
    
    // MARK: Other Tests
    
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
