//
//  SyntaxTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2023 1024jp
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
import Combine
import Yams
@testable import CotEditor

final class SyntaxTests: XCTestCase {
    
    private let styleDirectoryName = "Syntaxes"
    private let styleExtension = "yaml"
    
    private var styleDicts: [String: SyntaxManager.StyleDictionary] = [:]
    private var htmlStyle: SyntaxStyle?
    private var htmlSource: String?
    
    private var outlineParseCancellable: AnyCancellable?
    
    
    
    override func setUpWithError() throws {
        
        try super.setUpWithError()
        
        let bundle = Bundle(for: type(of: self))
        
        // load styles
        let urls = try XCTUnwrap(bundle.urls(forResourcesWithExtension: "yml", subdirectory: styleDirectoryName))
        self.styleDicts = try urls.reduce(into: [:]) { (dict, url) in
            let string = try String(contentsOf: url)
            let name = url.deletingPathExtension().lastPathComponent
            
            dict[name] = try XCTUnwrap(Yams.load(yaml: string) as? [String: Any])
        }
        
        // create HTML style
        let htmlDict = try XCTUnwrap(self.styleDicts["HTML"])
        self.htmlStyle = SyntaxStyle(dictionary: htmlDict, name: "HTML")
        
        XCTAssertNotNil(self.htmlStyle)
        
        // load test file
        let sourceURL = try XCTUnwrap(bundle.url(forResource: "sample", withExtension: "html"))
        self.htmlSource = try String(contentsOf: sourceURL)
        
        XCTAssertNotNil(self.htmlSource)
    }
    
    
    func testAllSyntaxStyles() {
        
        for (name, dict) in self.styleDicts {
            let validator = SyntaxStyleValidator(style: .init(dictionary: dict))
            XCTAssert(validator.validate())
            
            for error in validator.errors {
                XCTFail("\(name): \(error)")
            }
        }
    }
    
    
    func testEquality() {
        
        XCTAssertEqual(self.htmlStyle, self.htmlStyle)
    }
    
    
    func testNoneSytle() {
        
        let style = SyntaxStyle()
        
        XCTAssertEqual(style.name, "None")
        XCTAssert(style.highlightParser.isEmpty)
        XCTAssertNil(style.inlineCommentDelimiter)
        XCTAssertNil(style.blockCommentDelimiters)
    }
    
    
    func testXMLSytle() throws {
        
        let style = try XCTUnwrap(self.htmlStyle)
        
        XCTAssertEqual(style.name, "HTML")
        XCTAssertFalse(style.highlightParser.isEmpty)
        XCTAssertNil(style.inlineCommentDelimiter)
        XCTAssertEqual(style.blockCommentDelimiters?.begin, "<!--")
        XCTAssertEqual(style.blockCommentDelimiters?.end, "-->")
    }
    
    
    func testOutlineParse() throws {
        
        let style = try XCTUnwrap(self.htmlStyle)
        let source = try XCTUnwrap(self.htmlSource)
        
        let textStorage = NSTextStorage(string: source)
        let parser = SyntaxParser(textStorage: textStorage, style: style)
        
        // test outline parsing with publisher
        let outlineParseExpectation = self.expectation(description: "didParseOutline")
        self.outlineParseCancellable = parser.$outlineItems
            .compactMap { $0 }  // ignore the initial invocation
            .receive(on: RunLoop.main)
            .sink { (outlineItems) in
                outlineParseExpectation.fulfill()
                
                XCTAssertEqual(outlineItems.count, 3)
                
                XCTAssertEqual(parser.outlineItems, outlineItems)
                
                let item = outlineItems[1]
                XCTAssertEqual(item.title, "   h2: 🐕🐄")
                XCTAssertEqual(item.range.location, 354)
                XCTAssertEqual(item.range.length, 13)
                XCTAssertTrue(item.style.isEmpty)
            }
        parser.invalidateOutline()
        self.waitForExpectations(timeout: 1)
    }
}
