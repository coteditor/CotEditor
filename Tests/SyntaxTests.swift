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
    
    private let syntaxDirectoryName = "Syntaxes"
    
    private var syntaxDicts: [String: SyntaxManager.SyntaxDictionary] = [:]
    private var htmlSyntax: Syntax?
    private var htmlSource: String?
    
    private var outlineParseCancellable: AnyCancellable?
    
    
    
    override func setUpWithError() throws {
        
        try super.setUpWithError()
        
        let bundle = Bundle(for: type(of: self))
        
        // load syntaxes
        let urls = try XCTUnwrap(bundle.urls(forResourcesWithExtension: "yml", subdirectory: syntaxDirectoryName))
        self.syntaxDicts = try urls.reduce(into: [:]) { (dict, url) in
            let string = try String(contentsOf: url)
            let name = url.deletingPathExtension().lastPathComponent
            
            dict[name] = try XCTUnwrap(Yams.load(yaml: string) as? [String: Any])
        }
        
        // create HTML syntax
        let htmlDict = try XCTUnwrap(self.syntaxDicts["HTML"])
        self.htmlSyntax = Syntax(dictionary: htmlDict, name: "HTML")
        
        XCTAssertNotNil(self.htmlSyntax)
        
        // load test file
        let sourceURL = try XCTUnwrap(bundle.url(forResource: "sample", withExtension: "html"))
        self.htmlSource = try String(contentsOf: sourceURL)
        
        XCTAssertNotNil(self.htmlSource)
    }
    
    
    func testAllSyntaxes() {
        
        for (name, dict) in self.syntaxDicts {
            let validator = SyntaxValidator(syntax: .init(dictionary: dict))
            XCTAssert(validator.validate())
            
            for error in validator.errors {
                XCTFail("\(name): \(error)")
            }
        }
    }
    
    
    func testEquality() {
        
        XCTAssertEqual(self.htmlSyntax, self.htmlSyntax)
    }
    
    
    func testNoneSyntax() {
        
        let syntax = Syntax.none
        
        XCTAssertEqual(syntax.name, "None")
        XCTAssertEqual(syntax.kind, .code)
        XCTAssert(syntax.highlightParser.isEmpty)
        XCTAssertNil(syntax.inlineCommentDelimiter)
        XCTAssertNil(syntax.blockCommentDelimiters)
    }
    
    
    func testXMLSyntax() throws {
        
        let syntax = try XCTUnwrap(self.htmlSyntax)
        
        XCTAssertEqual(syntax.name, "HTML")
        XCTAssertFalse(syntax.highlightParser.isEmpty)
        XCTAssertNil(syntax.inlineCommentDelimiter)
        XCTAssertEqual(syntax.blockCommentDelimiters?.begin, "<!--")
        XCTAssertEqual(syntax.blockCommentDelimiters?.end, "-->")
    }
    
    
    func testOutlineParse() throws {
        
        let syntax = try XCTUnwrap(self.htmlSyntax)
        let source = try XCTUnwrap(self.htmlSource)
        
        let textStorage = NSTextStorage(string: source)
        let parser = SyntaxParser(textStorage: textStorage, syntax: syntax)
        
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
