//
//  TextFindTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2018 1024jp
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
        
        result = textFind.find(forward: true, isWrap: false)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.range, NSRange(location: 0, length: 3))
        XCTAssertEqual(result.wrapped, false)
        
        result = textFind.find(forward: false, isWrap: false)
        XCTAssertEqual(result.count, 2)
        XCTAssertNil(result.range)
        XCTAssertEqual(result.wrapped, false)
        
        
        settings = TextFind.Settings()
        textFind = try! TextFind(for: text, findString: findString, settings: settings, selectedRanges: [NSRange(location: 1, length: 0)])
        
        result = textFind.find(forward: true, isWrap: true)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.range, NSRange(location: 8, length: 3))
        XCTAssertEqual(result.wrapped, false)
        
        result = textFind.find(forward: false, isWrap: true)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.range, NSRange(location: 8, length: 3))
        XCTAssertEqual(result.wrapped, true)
        
        
        settings = TextFind.Settings(textualOptions: [.caseInsensitive])
        textFind = try! TextFind(for: text, findString: findString, settings: settings, selectedRanges: [NSRange(location: 1, length: 0)])
        
        result = textFind.find(forward: false, isWrap: true)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.range, NSRange(location: 16, length: 3))
        XCTAssertEqual(result.wrapped, true)
    }
    
    
    func testVerticalTabFind() {
        
        let text = "\u{b}000\\v000\n"
        let findString = "\\v"
        
        let settings = TextFind.Settings(usesRegularExpression: true,
                                         regexOptions: [.caseInsensitive],
                                         unescapesReplacementString: true)
        
        let textFind = try! TextFind(for: text, findString: findString, settings: settings)
        let result = textFind.find(forward: false, isWrap: true)
        XCTAssertEqual(result.count, 1)
        
        // wrong pattern with raw NSRegularExpression
        let regex = try! NSRegularExpression(pattern: findString)
        let numberOfMatches = regex.numberOfMatches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        XCTAssertEqual(numberOfMatches, 2)
    }
    
    
    func testSingleRegexFindAndReplacement() {
        
        let findString = "(?!=a)b(c)(?=d)"
        
        var settings: TextFind.Settings
        var textFind: TextFind
        var result: (range: NSRange?, count: Int, wrapped: Bool)
        var replacementResult: ReplacementItem?
        
        settings = TextFind.Settings(usesRegularExpression: true,
                                     regexOptions: [.caseInsensitive],
                                     unescapesReplacementString: true)
        
        
        textFind = try! TextFind(for: "abcdefg abcdefg ABCDEFG", findString: findString, settings: settings, selectedRanges: [NSRange(location: 1, length: 1)])
        
        result = textFind.find(forward: true, isWrap: true)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.range, NSRange(location: 9, length: 2))
        XCTAssertEqual(result.wrapped, false)
        
        result = textFind.find(forward: false, isWrap: true)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.range, NSRange(location: 17, length: 2))
        XCTAssertEqual(result.wrapped, true)
        
        
        textFind = try! TextFind(for: "ABCDEFG", findString: findString, settings: settings, selectedRanges: [NSRange(location: 1, length: 1)])
        
        result = textFind.find(forward: true, isWrap: true)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.range, NSRange(location: 1, length: 2))
        XCTAssertEqual(result.wrapped, true)
        
        result = textFind.find(forward: false, isWrap: true)
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
        
        var matches = [[NSRange]]()
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
        
        
        textFind = try! TextFind(for: "abcdefg ABCDEFG", findString: "ab", settings: settings)
        
        matches = [[NSRange]]()
        textFind.findAll { (matchedRanges, stop) in
            matches.append(matchedRanges)
        }
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches[0].count, 1)
        XCTAssertEqual(matches[0][0], NSRange(location: 0, length: 2))
        XCTAssertEqual(matches[1].count, 1)
        XCTAssertEqual(matches[1][0], NSRange(location: 8, length: 2))
    }
    
    
    func testReplaceAll() {
        
        var settings: TextFind.Settings
        var textFind: TextFind
        var replacementItems: [ReplacementItem]
        var selectedRanges: [NSRange]?
        
        settings = TextFind.Settings(usesRegularExpression: true,
                                     regexOptions: [.caseInsensitive])
        textFind = try! TextFind(for: "abcdefg ABCDEFG", findString: "(?!=a)b(c)(?=d)", settings: settings)
        
        (replacementItems, selectedRanges) = textFind.replaceAll(with: "$1\\\\t") { (_, _)  in }
        XCTAssertEqual(replacementItems.count, 1)
        XCTAssertEqual(replacementItems[0].string, "ac\\tdefg AC\\tDEFG")
        XCTAssertEqual(replacementItems[0].range, NSRange(location: 0, length: 15))
        XCTAssertNil(selectedRanges)
        
        
        settings = TextFind.Settings(usesRegularExpression: true,
                                     inSelection: true)
        textFind = try! TextFind(for: "abcdefg abcdefg abcdefg", findString: "abc", settings: settings, selectedRanges: [NSRange(location: 1, length: 14),
                                                                                                                         NSRange(location: 16, length: 7)])
        
        (replacementItems, selectedRanges) = textFind.replaceAll(with: "_") { (_, _)  in }
        XCTAssertEqual(replacementItems.count, 2)
        XCTAssertEqual(replacementItems[0].string, "bcdefg _defg")
        XCTAssertEqual(replacementItems[0].range, NSRange(location: 1, length: 14))
        XCTAssertEqual(replacementItems[1].string, "_defg")
        XCTAssertEqual(replacementItems[1].range, NSRange(location: 16, length: 7))
        XCTAssertEqual(selectedRanges![0], NSRange(location: 1, length: 12))
        XCTAssertEqual(selectedRanges![1], NSRange(location: 14, length: 5))
    }
    
}



// MARK: - Helper Extension

private extension TextFind.Settings {
    
    /// omittable initializer
    init(usesRegularExpression: Bool = false, inSelection: Bool = false, textualOptions: NSString.CompareOptions = [], regexOptions: NSRegularExpression.Options = [], unescapesReplacementString: Bool = false) {
        
        self = TextFind.Settings(usesRegularExpression: usesRegularExpression,
                                 inSelection: inSelection,
                                 textualOptions: textualOptions,
                                 regexOptions: regexOptions,
                                 unescapesReplacementString: unescapesReplacementString)
    }
}
