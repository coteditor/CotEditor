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
        
        let snippet = Snippet(name: "", format: "<h1><<<CURSOR>>></h1>")
        
        XCTAssertEqual(snippet.string, "<h1></h1>")
        XCTAssertEqual(snippet.selections, [NSRange(location: 4, length: 0)])
    }
    
    
    func testMultipleLines() {
        
        let format = """
            <ul>
                <li><<<CURSOR>>></li>
                <li><<<CURSOR>>></li>
            </ul>
            """
        let snippet = Snippet(name: "", format: format)
        
        let expectedString = """
            <ul>
                <li></li>
                <li></li>
            </ul>
            """
        XCTAssertEqual(snippet.string, expectedString)
        XCTAssertEqual(snippet.selections, [NSRange(location: 13, length: 0),
                                            NSRange(location: 27, length: 0)])
        
        let indentedSnippet = snippet.indented(with: "    ")
        
        let expectedIndentString = """
            <ul>
                    <li></li>
                    <li></li>
                </ul>
            """
        XCTAssertEqual(indentedSnippet.string, expectedIndentString)
        XCTAssertEqual(indentedSnippet.selections, [NSRange(location: 17, length: 0),
                                                    NSRange(location: 35, length: 0)])
    }
}
