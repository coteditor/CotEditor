/*
 
 TextFindTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-03.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import XCTest
@testable import CotEditor

class TextFindTests: XCTestCase {
    
    func testCaptureGroupCount() {
        
        var settings: TextFind.Settings
        var textFind: TextFind
        
        settings = TextFind.Settings(usesRegularExpression: true)
        
        textFind = try! TextFind(for: "", findString: "a", settings: settings)
        XCTAssertEqual(textFind.numberOfCaptureGroups, 0)
        
        textFind = try! TextFind(for: "", findString: "(?!=a)(b)(c)(?=d)", settings: settings)
        XCTAssertEqual(textFind.numberOfCaptureGroups, 2)
        
        settings = TextFind.Settings(usesRegularExpression: false)
        textFind = try! TextFind(for: "", findString: "(?!=a)(b)(c)(?=d)", settings: settings)
        XCTAssertEqual(textFind.numberOfCaptureGroups, 0)
    }
    

    func testSingleFind() {
        
        let text = "abcdefg abcdefg ABCDEFG"
        let findString = "abc"
        
        var settings: TextFind.Settings
        var textFind: TextFind
        var result: (range: NSRange?, count: Int, wrapped: Bool)
        
        settings = TextFind.Settings()
        textFind = try! TextFind(for: text, findString: findString, settings: settings)
        
        result = textFind.find(forward: true)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.range, NSRange(location: 0, length: 3))
        XCTAssertEqual(result.wrapped, false)
        
        result = textFind.find(forward: false)
        XCTAssertEqual(result.count, 2)
        XCTAssertNil(result.range)
        XCTAssertEqual(result.wrapped, false)
        
        
        settings = TextFind.Settings(isWrap: true)
        textFind = try! TextFind(for: text, findString: findString, settings: settings, selectedRanges: [NSRange(location: 1, length: 0)])
        
        result = textFind.find(forward: true)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.range, NSRange(location: 8, length: 3))
        XCTAssertEqual(result.wrapped, false)
        
        result = textFind.find(forward: false)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.range, NSRange(location: 8, length: 3))
        XCTAssertEqual(result.wrapped, true)
        
        
        settings = TextFind.Settings(isWrap: true,
                                     textualOptions: [.caseInsensitive])
        textFind = try! TextFind(for: text, findString: findString, settings: settings, selectedRanges: [NSRange(location: 1, length: 0)])
        
        result = textFind.find(forward: false)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.range, NSRange(location: 16, length: 3))
        XCTAssertEqual(result.wrapped, true)
    }
    
    
    func testSingleRegexFindAndReplacement() {
        
        let findString = "(?!=a)b(c)(?=d)"
        
        var settings: TextFind.Settings
        var textFind: TextFind
        var result: (range: NSRange?, count: Int, wrapped: Bool)
        var replacementResult: ReplacementItem?
        
        settings = TextFind.Settings(usesRegularExpression: true,
                                     isWrap: true,
                                     regexOptions: [.caseInsensitive],
                                     unescapesReplacementString: true)
        
        
        textFind = try! TextFind(for: "abcdefg abcdefg ABCDEFG", findString: findString, settings: settings, selectedRanges: [NSRange(location: 1, length: 1)])
        
        result = textFind.find(forward: true)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.range, NSRange(location: 9, length: 2))
        XCTAssertEqual(result.wrapped, false)
        
        result = textFind.find(forward: false)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.range, NSRange(location: 17, length: 2))
        XCTAssertEqual(result.wrapped, true)
        
        
        textFind = try! TextFind(for: "ABCDEFG", findString: findString, settings: settings, selectedRanges: [NSRange(location: 1, length: 1)])
        
        result = textFind.find(forward: true)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.range, NSRange(location: 1, length: 2))
        XCTAssertEqual(result.wrapped, true)
        
        result = textFind.find(forward: false)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.range, NSRange(location: 1, length: 2))
        XCTAssertEqual(result.wrapped, true)
        
        replacementResult = textFind.replace(with: "$1")
        XCTAssertNil(replacementResult)
        
        
        textFind = try! TextFind(for: "ABCDEFG", findString: findString, settings: settings, selectedRanges: [NSRange(location: 1, length: 2)])
        
        replacementResult = textFind.replace(with: "$1\\t")
        XCTAssertEqual(replacementResult!.string, "C\t")
        XCTAssertEqual(replacementResult!.range, NSRange(location: 1, length: 2))
    }
    
    
    func testFindAll() {
        
        var settings: TextFind.Settings
        var textFind: TextFind
        
        settings = TextFind.Settings(usesRegularExpression: true,
                                     regexOptions: [.caseInsensitive])
        textFind = try! TextFind(for: "abcdefg ABCDEFG", findString: "(?!=a)b(c)(?=d)", settings: settings)
        
        var matches = [[NSRange?]]()
        textFind.findAll { (matchedRanges, stop) in
            matches.append(matchedRanges)
        }
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches[0].count, 2)
        XCTAssertEqual(matches[0][0], NSRange(location: 1, length: 2))
        XCTAssertEqual(matches[0][1], NSRange(location: 2, length: 1))
        XCTAssertEqual(matches[1].count, 2)
        XCTAssertEqual(matches[1][0], NSRange(location: 9, length: 2))
        XCTAssertEqual(matches[1][1], NSRange(location: 10, length: 1))
    }
    
    
    func testReplaceAll() {
        
        var settings: TextFind.Settings
        var textFind: TextFind
        var replacementItems: [ReplacementItem]
        var selectedRanges: [NSRange]?
        
        settings = TextFind.Settings(usesRegularExpression: true,
                                     regexOptions: [.caseInsensitive])
        textFind = try! TextFind(for: "abcdefg ABCDEFG", findString: "(?!=a)b(c)(?=d)", settings: settings)
        
        (replacementItems, selectedRanges) = textFind.replaceAll(with: "$1\\\\t") { _ in }
        XCTAssertEqual(replacementItems.count, 2)
        XCTAssertEqual(replacementItems[0].string, "c\\t")
        XCTAssertEqual(replacementItems[0].range, NSRange(location: 1, length: 2))
        XCTAssertEqual(replacementItems[1].string, "C\\t")
        XCTAssertEqual(replacementItems[1].range, NSRange(location: 9, length: 2))
        XCTAssertNil(selectedRanges)
        
        
        settings = TextFind.Settings(usesRegularExpression: true,
                                     inSelection: true)
        textFind = try! TextFind(for: "abcdefg abcdefg abcdefg", findString: "abc", settings: settings, selectedRanges: [NSRange(location: 1, length: 15),
                                                                                                                         NSRange(location: 16, length: 7)])
        
        (replacementItems, selectedRanges) = textFind.replaceAll(with: "_") { _ in }
        XCTAssertEqual(replacementItems.count, 2)
        XCTAssertEqual(replacementItems[0].string, "_")
        XCTAssertEqual(replacementItems[0].range, NSRange(location: 8, length: 3))
        XCTAssertEqual(replacementItems[1].string, "_")
        XCTAssertEqual(replacementItems[1].range, NSRange(location: 16, length: 3))
        XCTAssertEqual(selectedRanges![0], NSRange(location: 2, length: 13))
        XCTAssertEqual(selectedRanges![1], NSRange(location: 15, length: 5))
    }
    
}



// MARK: - Helper Extension

private extension TextFind.Settings {
    
    /// omittable initializer
    init(usesRegularExpression: Bool = false, isWrap: Bool = false, inSelection: Bool = false, textualOptions: String.CompareOptions = [], regexOptions: NSRegularExpression.Options = [], unescapesReplacementString: Bool = false) {
        
        self.usesRegularExpression = usesRegularExpression
        self.isWrap = isWrap
        self.inSelection = inSelection
        self.textualOptions = textualOptions
        self.regexOptions = regexOptions
        self.unescapesReplacementString = unescapesReplacementString
    }
}
