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
//  © 2016-2024 1024jp
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
    
    private var syntaxes: [String: Syntax] = [:]
    private var htmlSyntax: Syntax?
    private var htmlSource: String?
    
    private var outlineParseCancellable: AnyCancellable?
    
    
    
    override func setUpWithError() throws {
        
        try super.setUpWithError()
        
        let bundle = Bundle(for: type(of: self))
        let urls = try XCTUnwrap(bundle.urls(forResourcesWithExtension: "yml", subdirectory: self.syntaxDirectoryName))
        
        // load syntaxes
        let decoder = YAMLDecoder()
        self.syntaxes = try urls.reduce(into: [:]) { (dict, url) in
            let data = try Data(contentsOf: url)
            let name = url.deletingPathExtension().lastPathComponent
            
            dict[name] = try decoder.decode(Syntax.self, from: data)
        }
        self.htmlSyntax = try XCTUnwrap(self.syntaxes["HTML"])
        
        XCTAssertNotNil(self.htmlSyntax)
        
        // load test file
        let sourceURL = try XCTUnwrap(bundle.url(forResource: "sample", withExtension: "html"))
        self.htmlSource = try String(contentsOf: sourceURL)
        
        XCTAssertNotNil(self.htmlSource)
    }
    
    
    func testAllSyntaxes() {
        
        for (name, syntax) in self.syntaxes {
            let model = SyntaxObject(value: syntax)
            let errors = model.validate()
            
            XCTAssert(errors.isEmpty)
            for error in errors {
                XCTFail("\(name): \(error)")
            }
        }
    }
    
    
    func testSanitization() {
        
        for (name, syntax) in self.syntaxes {
            let sanitized = syntax.sanitized
            
            XCTAssertEqual(syntax.kind, sanitized.kind)
            
            for type in SyntaxType.allCases {
                let keyPath = Syntax.highlightKeyPath(for: type)
                XCTAssertEqual(syntax[keyPath: keyPath], sanitized[keyPath: keyPath],
                               ".\(type.rawValue) of “\(name)” is not sanitized in the latest manner")
            }
            
            XCTAssertEqual(syntax.outlines, sanitized.outlines,
                           ".outlines of “\(name)” is not sanitized in the latest manner")
            XCTAssertEqual(syntax.completions, sanitized.completions,
                           ".completions of “\(name)” is not sanitized in the latest manner")
            XCTAssertEqual(syntax.commentDelimiters, sanitized.commentDelimiters,
                           ".commentDelimiters of “\(name)” is not sanitized in the latest manner")
            XCTAssertEqual(syntax.extensions, sanitized.extensions,
                           ".extensions of “\(name)” is not sanitized in the latest manner")
            XCTAssertEqual(syntax.filenames, sanitized.filenames,
                           ".filenames of “\(name)” is not sanitized in the latest manner")
            XCTAssertEqual(syntax.interpreters, sanitized.interpreters,
                           ".interpreters of “\(name)” is not sanitized in the latest manner")
            XCTAssertEqual(syntax.metadata, sanitized.metadata,
                           ".metadata of “\(name)” is not sanitized in the latest manner")
        }
    }
    
    
    func testEquality() {
        
        XCTAssertEqual(self.htmlSyntax, self.htmlSyntax)
    }
    
    
    func testNoneSyntax() {
        
        let syntax = Syntax.none
        
        XCTAssertEqual(syntax.kind, .code)
        XCTAssert(syntax.highlightParser.isEmpty)
        XCTAssertNil(syntax.commentDelimiters.inline)
        XCTAssertNil(syntax.commentDelimiters.block)
    }
    
    
    func testXMLSyntax() throws {
        
        let syntax = try XCTUnwrap(self.htmlSyntax)
        
        XCTAssertFalse(syntax.highlightParser.isEmpty)
        XCTAssertNil(syntax.commentDelimiters.inline)
        XCTAssertEqual(syntax.commentDelimiters.block, Pair("<!--", "-->"))
    }
    
    
    func testOutlineParse() throws {
        
        let syntax = try XCTUnwrap(self.htmlSyntax)
        let source = try XCTUnwrap(self.htmlSource)
        
        let textStorage = NSTextStorage(string: source)
        let parser = SyntaxParser(textStorage: textStorage, syntax: syntax, name: "HTML")
        
        // test outline parsing with publisher
        let outlineParseExpectation = self.expectation(description: "didParseOutline")
        self.outlineParseCancellable = parser.$outlineItems
            .compactMap { $0 }  // ignore the initial invocation
            .receive(on: RunLoop.main)
            .sink { outlineItems in
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
    
    
    func testViewModelHighlightEquality() {
        
        let termA = SyntaxObject.Highlight(begin: "abc", end: "def")
        let termB = SyntaxObject.Highlight(begin: "abc", end: "def")
        let termC = SyntaxObject.Highlight(begin: "abc")
        
        XCTAssertEqual(termA, termB)
        XCTAssertNotEqual(termA, termC)
        XCTAssertNotEqual(termA.id, termB.id)
    }
}
