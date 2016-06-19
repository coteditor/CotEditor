/*
 
 SyntaxTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-11.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import XCTest

let StyleDirectoryName = "Syntaxes"
let StyleExtension = "yaml"


class SyntaxTests: XCTestCase, CESyntaxStyleDelegate {
    
    var htmlStyle: CESyntaxStyle?
    var htmlSource: String?
    
    var outlineParseExpectation: XCTestExpectation?
    
    
    override func setUp() {
        super.setUp()
        
        let bundle = Bundle(for: self.dynamicType)
        
        // load XML style
        let styleURL = bundle.urlForResource("HTML", withExtension: StyleExtension, subdirectory: StyleDirectoryName)
        let data = try? Data(contentsOf: styleURL!)
        let dict = try? YAMLSerialization.object(withYAMLData: data, options: kYAMLReadOptionMutableContainersAndLeaves) as? [String: AnyObject]
        self.htmlStyle = CESyntaxStyle(dictionary: dict!, name: "HTML")
        
        XCTAssertNotNil(self.htmlStyle)
        
        // load test file
        let sourceURL = bundle.urlForResource("sample", withExtension: "html")
        self.htmlSource = try? NSString(contentsOf: sourceURL!, encoding: String.Encoding.utf8.rawValue) as String
        
        XCTAssertNotNil(self.htmlSource)
    }
    
    
    func testNoneSytle() {
        let style = CESyntaxStyle(dictionary: nil, name: "foo")
        
        XCTAssertEqual(style.styleName, "foo")
        XCTAssert(style.isNone)
        XCTAssertFalse(style.canParse())
        XCTAssertNil(style.inlineCommentDelimiter)
        XCTAssertNil(style.blockCommentDelimiters)
    }
    
    
    func testXMLSytle() {
        guard let style = self.htmlStyle else { return }
        
        XCTAssertEqual(style.styleName, "HTML")
        XCTAssertFalse(style.isNone)
        XCTAssert(style.canParse())
        XCTAssertNil(style.inlineCommentDelimiter)
        XCTAssertEqual(style.blockCommentDelimiters?["beginDelimiter"], "<!--")
        XCTAssertEqual(style.blockCommentDelimiters?["endDelimiter"], "-->")
    }
    
    
    func testOutlineParse() {
        guard let style = self.htmlStyle, let source = self.htmlSource else { return }
        
        // create dummy textView
        let textView = NSTextView()
        textView.string = source
        
        style.textStorage = textView.textStorage
        style.delegate = self
        
        // test outline parsing with delegate
        self.outlineParseExpectation = self.expectation(withDescription: "didParseOutline")
        style.invalidateOutline()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func syntaxStyle(_ syntaxStyle: CESyntaxStyle, didParseOutline outlineItems: [CEOutlineItem]?) {
        self.outlineParseExpectation?.fulfill()
        
        XCTAssertEqual(outlineItems?.count, 3)
        
        XCTAssertEqual(syntaxStyle.outlineItems!, outlineItems!)
        
        if let item = outlineItems?[1] {
            XCTAssertEqual(item.title, "   h2: 🐕🐄")
            XCTAssertEqual(item.range.location, 354)
            XCTAssertEqual(item.range.length, 13)
            XCTAssertFalse(item.isBold)
            XCTAssertFalse(item.isItalic)
            XCTAssertFalse(item.hasUnderline)
        } else {
            XCTFail()
        }
    }
    
}
