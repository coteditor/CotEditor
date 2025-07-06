//
//  WikiLinkTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by Claude Code on 2025-01-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 CotEditor Project
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

final class WikiLinkTests: XCTestCase {
    
    // MARK: - Basic Detection Tests
    
    func testBasicWikiLinkDetection() {
        let text = "This is a [[Simple Note]] in the text."
        let links = WikiLinkParser.findWikiLinks(in: text)
        
        XCTAssertEqual(links.count, 1)
        
        let link = links[0]
        XCTAssertEqual(link.title, "Simple Note")
        XCTAssertEqual(link.range, NSRange(location: 10, length: 15)) // [[Simple Note]]
        XCTAssertEqual(link.titleRange, NSRange(location: 12, length: 11)) // Simple Note
    }
    
    func testMultipleWikiLinks() {
        let text = "See [[Note One]] and [[Note Two]] for details."
        let links = WikiLinkParser.findWikiLinks(in: text)
        
        XCTAssertEqual(links.count, 2)
        
        XCTAssertEqual(links[0].title, "Note One")
        XCTAssertEqual(links[1].title, "Note Two")
    }
    
    func testWikiLinkWithSpaces() {
        let text = "Reference: [[Note with Multiple Spaces]]"
        let links = WikiLinkParser.findWikiLinks(in: text)
        
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0].title, "Note with Multiple Spaces")
    }
    
    func testWikiLinkWithSpecialCharacters() {
        let text = "Check [[Note-123_test.md]] and [[📝 Unicode Note]]"
        let links = WikiLinkParser.findWikiLinks(in: text)
        
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[0].title, "Note-123_test.md")
        XCTAssertEqual(links[1].title, "📝 Unicode Note")
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyWikiLink() {
        let text = "Empty link: [[]]"
        let links = WikiLinkParser.findWikiLinks(in: text)
        
        XCTAssertEqual(links.count, 0) // Empty links should be ignored
    }
    
    func testWhitespaceOnlyWikiLink() {
        let text = "Whitespace: [[   ]]"
        let links = WikiLinkParser.findWikiLinks(in: text)
        
        XCTAssertEqual(links.count, 0) // Whitespace-only links should be ignored
    }
    
    func testNestedBrackets() {
        let text = "Nested: [[[Invalid]]] and [[Valid]]"
        let links = WikiLinkParser.findWikiLinks(in: text)
        
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0].title, "Valid")
    }
    
    func testMalformedLinks() {
        let text = "Malformed: [Note] and [[Unclosed and ]Broken]"
        let links = WikiLinkParser.findWikiLinks(in: text)
        
        XCTAssertEqual(links.count, 0) // Malformed links should not be detected
    }
    
    func testPartialLinks() {
        let text = "Partial: [[Note and incomplete ["
        let links = WikiLinkParser.findWikiLinks(in: text)
        
        XCTAssertEqual(links.count, 0) // Incomplete links should not be detected
    }
    
    // MARK: - Range-based Detection Tests
    
    func testRangeBasedDetection() {
        let text = "[[Note One]] middle text [[Note Two]]"
        let searchRange = NSRange(location: 0, length: 20) // Only covers first part
        let links = WikiLinkParser.findWikiLinks(in: text, range: searchRange)
        
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[0].title, "Note One")
    }
    
    func testRangeBasedDetectionEmpty() {
        let text = "[[Note One]] middle text [[Note Two]]"
        let searchRange = NSRange(location: 13, length: 10) // Only covers middle text
        let links = WikiLinkParser.findWikiLinks(in: text, range: searchRange)
        
        XCTAssertEqual(links.count, 0)
    }
    
    func testInvalidRange() {
        let text = "[[Note One]]"
        let searchRange = NSRange(location: 50, length: 10) // Beyond text length
        let links = WikiLinkParser.findWikiLinks(in: text, range: searchRange)
        
        XCTAssertEqual(links.count, 0)
    }
    
    // MARK: - Position-based Tests
    
    func testWikiLinkAtPosition() {
        let text = "Text [[Note Title]] more text"
        
        // Test position inside link
        let linkInsidePosition = 10 // Inside [[Note Title]]
        let linkAtPosition = WikiLinkParser.wikiLink(at: linkInsidePosition, in: text)
        XCTAssertNotNil(linkAtPosition)
        XCTAssertEqual(linkAtPosition?.title, "Note Title")
        
        // Test position outside link
        let outsidePosition = 25 // After the link
        let noLink = WikiLinkParser.wikiLink(at: outsidePosition, in: text)
        XCTAssertNil(noLink)
    }
    
    // MARK: - Validation Tests
    
    func testValidNoteTitle() {
        XCTAssertTrue(WikiLinkParser.isValidNoteTitle("Simple Note"))
        XCTAssertTrue(WikiLinkParser.isValidNoteTitle("Note with spaces"))
        XCTAssertTrue(WikiLinkParser.isValidNoteTitle("Note-123_test"))
        XCTAssertTrue(WikiLinkParser.isValidNoteTitle("📝 Unicode"))
    }
    
    func testInvalidNoteTitle() {
        XCTAssertFalse(WikiLinkParser.isValidNoteTitle("")) // Empty
        XCTAssertFalse(WikiLinkParser.isValidNoteTitle("   ")) // Whitespace only
        XCTAssertFalse(WikiLinkParser.isValidNoteTitle("Note[with]brackets")) // Contains brackets
        XCTAssertFalse(WikiLinkParser.isValidNoteTitle(String(repeating: "a", count: 300))) // Too long
    }
    
    func testCreateWikiLink() {
        XCTAssertEqual(WikiLinkParser.createWikiLink(title: "Test Note"), "[[Test Note]]")
        XCTAssertEqual(WikiLinkParser.createWikiLink(title: "  Trimmed  "), "[[Trimmed]]")
        XCTAssertNil(WikiLinkParser.createWikiLink(title: "")) // Invalid title
        XCTAssertNil(WikiLinkParser.createWikiLink(title: "Note[bad]")) // Invalid title
    }
    
    // MARK: - String Extension Tests
    
    func testStringExtensions() {
        let textWithLinks = "See [[Note One]] and [[Note Two]]"
        let textWithoutLinks = "Just regular text"
        
        XCTAssertEqual(textWithLinks.wikiLinks.count, 2)
        XCTAssertTrue(textWithLinks.containsWikiLinks)
        
        XCTAssertEqual(textWithoutLinks.wikiLinks.count, 0)
        XCTAssertFalse(textWithoutLinks.containsWikiLinks)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeText() {
        // Create a large text with many wiki links
        var largeText = ""
        for i in 0..<1000 {
            largeText += "Some text [[Note \(i)]] more text. "
        }
        
        measure {
            let links = WikiLinkParser.findWikiLinks(in: largeText)
            XCTAssertEqual(links.count, 1000)
        }
    }
    
    func testPerformanceWithoutLinks() {
        // Large text without any wiki links
        let largeText = String(repeating: "This is regular text without any special formatting. ", count: 10000)
        
        measure {
            let links = WikiLinkParser.findWikiLinks(in: largeText)
            XCTAssertEqual(links.count, 0)
        }
    }
    
    // MARK: - Real-world Example Tests
    
    func testRealWorldExample() {
        let text = """
        # Meeting Notes
        
        Discussed the project with [[John Smith]] and [[Mary Johnson]].
        
        Key points:
        - Review [[Project Plan]]
        - Update [[Timeline Document]]
        - Check [[Budget Spreadsheet]]
        
        Follow up: [[Action Items]] by Friday.
        
        Related: [[Previous Meeting]] notes.
        """
        
        let links = WikiLinkParser.findWikiLinks(in: text)
        XCTAssertEqual(links.count, 7)
        
        let expectedTitles = ["John Smith", "Mary Johnson", "Project Plan", 
                            "Timeline Document", "Budget Spreadsheet", 
                            "Action Items", "Previous Meeting"]
        
        let actualTitles = links.map { $0.title }
        XCTAssertEqual(Set(actualTitles), Set(expectedTitles))
    }
}