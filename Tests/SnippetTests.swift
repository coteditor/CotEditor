//
//  SnippetTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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

struct SnippetTests {
    
    @Test func simpleSnippet() {
        
        let snippet = Snippet(name: "", format: "<h1><<<SELECTION>>><<<CURSOR>>></h1>")
        let (string, selections) = snippet.insertion(selectedString: "abc")
        
        #expect(string == "<h1>abc</h1>")
        #expect(selections == [NSRange(location: 7, length: 0)])
    }
    
    
    @Test func multipleLines() {
        
        let format = """
            <ul>
                <li><<<CURSOR>>></li>
                <li><<<CURSOR>>></li>
            </ul>
            """
        let snippet = Snippet(name: "", format: format)
        let (string, selections) = snippet.insertion(selectedString: "")
        
        let expectedString = """
            <ul>
                <li></li>
                <li></li>
            </ul>
            """
        #expect(string == expectedString)
        #expect(selections == [NSRange(location: 13, length: 0),
                               NSRange(location: 27, length: 0)])
        
        let (indentedString, indentedSelections) = snippet.insertion(selectedString: "", indent: "    ")
        
        let expectedIndentString = """
            <ul>
                    <li></li>
                    <li></li>
                </ul>
            """
        #expect(indentedString == expectedIndentString)
        #expect(indentedSelections == [NSRange(location: 17, length: 0),
                                       NSRange(location: 35, length: 0)])
    }
    
    
    @Test func multipleInsertions() {
        
        let string = """
                aaa
            
            bbcc
            """
        let snippet = Snippet(name: "", format: "<li><<<SELECTION>>><<<CURSOR>>></li>")
        let context = snippet.insertions(for: string, ranges: [
            NSRange(location: 4, length: 3),
            NSRange(location: 8, length: 0),
            NSRange(location: 9, length: 2),
        ])
        
        #expect(context.strings == [
            "<li>aaa</li>",
            "<li></li>",
            "<li>bb</li>",
        ])
        #expect(context.selectedRanges == [
            NSRange(location: 11, length: 0),
            NSRange(location: 21, length: 0),
            NSRange(location: 33, length: 0),
        ])
    }
}
