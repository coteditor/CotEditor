//
//  EditorCounterTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-01-25.
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

import AppKit
import Testing
@testable import CotEditor

@MainActor final class EditorCounterTests {
    
    @MainActor final class Provider: TextViewProvider {
        
        var textView: NSTextView? = NSTextView()
        
        
        init(string: String, selectedRange: NSRange) {
            
            self.textView?.string = string
            self.textView?.selectedRange = selectedRange
        }
    }
    
    
    private let testString = """
        dog is 🐕.
        cow is 🐄.
        Both are 👍🏼.
        """
    
    @Test func noRequiredInfo() throws {
        
        let provider = Provider(string: self.testString, selectedRange: NSRange(0..<3))
        
        let counter = EditorCounter()
        counter.document = provider
        counter.invalidateContent()
        counter.invalidateSelection()
        
        #expect(counter.result.lines.entire == nil)
        #expect(counter.result.characters.entire == nil)
        #expect(counter.result.words.entire == nil)
        #expect(counter.result.location == nil)
        #expect(counter.result.line == nil)
        #expect(counter.result.column == nil)
    }
    
    
    @Test func allRequiredInfo() throws {
        
        let provider = Provider(string: self.testString, selectedRange: NSRange(11..<21))
        
        let counter = EditorCounter()
        counter.document = provider
        counter.updatesAll = true
        counter.invalidateContent()
        counter.invalidateSelection()
        
        withKnownIssue("values will be updated asynchronously (This is the issue on the test side.)") {
            #expect(counter.result.lines.entire == 3)
            #expect(counter.result.characters.entire == 31)
            #expect(counter.result.words.entire == 6)
            
            #expect(counter.result.characters.selected == 9)
            #expect(counter.result.lines.selected == 1)
            #expect(counter.result.words.selected == 2)
            
            #expect(counter.result.location == 10)
            #expect(counter.result.column == 0)
            #expect(counter.result.line == 2)
        }
    }
    
    
    @Test func skipWholeText() throws {
        
        let provider = Provider(string: self.testString, selectedRange: NSRange(11..<21))
        
        let counter = EditorCounter()
        counter.document = provider
        counter.updatesAll = true
        counter.invalidateSelection()
        
        #expect(counter.result.lines.entire == nil)
        #expect(counter.result.characters.entire == nil)
        #expect(counter.result.words.entire == nil)
        
        withKnownIssue("values will be updated asynchronously (This is the issue on the test side.)") {
            #expect(counter.result.lines.selected == 1)
            #expect(counter.result.characters.selected == 9)
            #expect(counter.result.words.selected == 2)
            
            #expect(counter.result.location == 10)
            #expect(counter.result.column == 0)
            #expect(counter.result.line == 2)
        }
    }
    
    
    @Test func crlf() throws {
        
        let provider = Provider(string: "a\r\nb", selectedRange: NSRange(1..<4))
        
        let counter = EditorCounter()
        counter.document = provider
        counter.updatesAll = true
        counter.invalidateContent()
        counter.invalidateSelection()
        
//        #expect(counter.result.lines.entire == 2)
//        #expect(counter.result.characters.entire == 3)
//        #expect(counter.result.words.entire == 2)
        
//        #expect(counter.result.lines.selected == 2)
//        #expect(counter.result.characters.selected == 2)
//        #expect(counter.result.words.selected == 1)
        
//        #expect(counter.result.location == 1)
//        #expect(counter.result.column == 1)
//        #expect(counter.result.line == 1)
    }
    
    
    @Test func formatEditorCount() {
        
        var count = EditorCount()
        
        #expect(count.formatted == nil)
        
        count.entire = 1000
        #expect(count.formatted == "1,000")
        
        count.selected = 100
        #expect(count.formatted == "1,000 (100)")
        
        count.entire = nil
        #expect(count.formatted == nil)
    }
}
