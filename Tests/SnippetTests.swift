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
//  © 2022-2023 1024jp
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

final class SnippetTests: XCTestCase {
    
    func testSimpleSnippet() {
        
        let snippet = Snippet(name: "", format: "<h1><<<SELECTION>>><<<CURSOR>>></h1>")
        let (string, selections) = snippet.insertion(selectedString: "abc")
        
        XCTAssertEqual(string, "<h1>abc</h1>")
        XCTAssertEqual(selections, [NSRange(location: 7, length: 0)])
    }
    
    
    func testMultipleLines() {
        
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
        XCTAssertEqual(string, expectedString)
        XCTAssertEqual(selections, [NSRange(location: 13, length: 0),
                                    NSRange(location: 27, length: 0)])
        
        let (indentedString, indentedSelections) = snippet.insertion(selectedString: "", indent: "    ")
        
        let expectedIndentString = """
            <ul>
                    <li></li>
                    <li></li>
                </ul>
            """
        XCTAssertEqual(indentedString, expectedIndentString)
        XCTAssertEqual(indentedSelections, [NSRange(location: 17, length: 0),
                                            NSRange(location: 35, length: 0)])
    }
    
    
    func testMultipleInsertions() {
        
        let string = """
                aaa
            
            bbcc
            """
        let snippet = Snippet(name: "", format: "<li><<<SELECTION>>><<<CURSOR>>></li>")
        let (strings, selections) = snippet.insertions(for: string, ranges: [
            NSRange(location: 4, length: 3),
            NSRange(location: 8, length: 0),
            NSRange(location: 9, length: 2),
        ])
        
        let expectedStrings = [
            "<li>aaa</li>",
            "<li></li>",
            "<li>bb</li>",
        ]
        let expectedSelections = [NSRange(location: 11, length: 0),
                                  NSRange(location: 21, length: 0),
                                  NSRange(location: 33, length: 0)]
        XCTAssertEqual(strings, expectedStrings)
        XCTAssertEqual(selections, expectedSelections)
    }
}
