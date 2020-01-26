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
//  © 2016-2019 1024jp
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
import YAML
@testable import CotEditor

let styleDirectoryName = "Syntaxes"
let styleExtension = "yaml"


final class SyntaxTests: XCTestCase {
    
    var styleDicts: [String: SyntaxManager.StyleDictionary] = [:]
    var htmlStyle: SyntaxStyle?
    var htmlSource: String?
    
    var outlineParseExpectation: XCTestExpectation?
    
    
    
    override func setUp() {
        
        super.setUp()
        
        let bundle = Bundle(for: type(of: self))
        
        // load styles
        let dictsWithNames = bundle.urls(forResourcesWithExtension: "yaml", subdirectory: styleDirectoryName)!
            .map { url -> (String, SyntaxManager.StyleDictionary) in
                let data = try! Data(contentsOf: url)
                let name = url.deletingPathExtension().lastPathComponent
                let dict = try! YAMLSerialization.object(withYAMLData: data, options: kYAMLReadOptionMutableContainersAndLeaves) as! [String: Any]
                
                return (name, dict)
            }
        self.styleDicts = .init(uniqueKeysWithValues: dictsWithNames)
        
        // create HTML style
        self.htmlStyle = SyntaxStyle(dictionary: self.styleDicts["HTML"]!, name: "HTML")
        
        XCTAssertNotNil(self.htmlStyle)
        
        // load test file
        let sourceURL = bundle.url(forResource: "sample", withExtension: "html")
        self.htmlSource = try? String(contentsOf: sourceURL!, encoding: .utf8)
        
        XCTAssertNotNil(self.htmlSource)
    }
    
    
    func testAllSyntaxStyles() {
        
        for (name, dict) in self.styleDicts {
            for error in SyntaxStyleValidator.validate(dict) {
                XCTFail("\(name) \(error.errorDescription!) -> \(error.failureReason!)")
            }
        }
    }
    
    
    func testEquality() {
        
        XCTAssertEqual(self.htmlStyle, self.htmlStyle)
    }
    
    
    func testNoneSytle() {
        
        let style = SyntaxStyle()
        
        XCTAssertEqual(style.name, "None")
        XCTAssert(style.isNone)
        XCTAssertFalse(style.hasHighlightDefinition)
        XCTAssertNil(style.inlineCommentDelimiter)
        XCTAssertNil(style.blockCommentDelimiters)
    }
    
    
    func testXMLSytle() {
        
        let style = self.htmlStyle!
        
        XCTAssertEqual(style.name, "HTML")
        XCTAssertFalse(style.isNone)
        XCTAssert(style.hasHighlightDefinition)
        XCTAssertNil(style.inlineCommentDelimiter)
        XCTAssertEqual(style.blockCommentDelimiters?.begin, "<!--")
        XCTAssertEqual(style.blockCommentDelimiters?.end, "-->")
    }
    
    
    func testOutlineParse() {
        
        let style = self.htmlStyle!
        let source = self.htmlSource!
        
        let textStorage = NSTextStorage(string: source)
        let parser = SyntaxParser(textStorage: textStorage, style: style)
        
        // test outline parsing with delegate
        parser.delegate = self
        self.outlineParseExpectation = self.expectation(description: "didParseOutline")
        parser.invalidateOutline()
        self.waitForExpectations(timeout: 1)
    }
    
}



// MARK: Syntax Parser Delegate

extension SyntaxTests: SyntaxParserDelegate {

    func syntaxParser(_ syntaxParser: SyntaxParser, didStartParsingOutline progress: Progress) {
        
    }
    
    
    func syntaxParser(_ syntaxParser: SyntaxParser, didParseOutline outlineItems: [OutlineItem]) {
        
        self.outlineParseExpectation?.fulfill()
        
        XCTAssertEqual(outlineItems.count, 3)
        
        XCTAssertEqual(syntaxParser.outlineItems, outlineItems)
        
        let item = outlineItems[1]
        XCTAssertEqual(item.title, "   h2: 🐕🐄")
        XCTAssertEqual(item.range.location, 354)
        XCTAssertEqual(item.range.length, 13)
        XCTAssertTrue(item.style.isEmpty)
    }
    
}
