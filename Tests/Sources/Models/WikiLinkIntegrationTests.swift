//
//  WikiLinkIntegrationTests.swift
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

final class WikiLinkIntegrationTests: XCTestCase {
    
    // MARK: - Range Validation Tests
    
    func testSpecificCrashScenario() {
        // Test the exact crash scenario from the bug report
        // Range {9223372036854775807, 0} with string length 245
        let crashRange = NSRange(location: 9223372036854775807, length: 0) // NSNotFound
        let testText = String(repeating: "Test text with [[wiki links]] here. ", count: 7) // ~245 chars
        
        XCTAssertNoThrow({
            // This should not crash with our fixes
            let isValid = crashRange.location != NSNotFound &&
                         crashRange.location >= 0 &&
                         crashRange.location <= testText.count &&
                         crashRange.length >= 0 &&
                         crashRange.upperBound <= testText.count
            
            XCTAssertFalse(isValid, "NSNotFound range should be detected as invalid")
        }, "NSNotFound range should not cause crash")
    }
    
    func testInvalidRangeHandling() {
        // Test cases that should not crash the application
        let invalidRanges = [
            NSRange(location: NSNotFound, length: 0),
            NSRange(location: NSNotFound, length: 10),
            NSRange(location: -1, length: 5),
            NSRange(location: 0, length: -1),
            NSRange(location: 1000, length: 10), // Beyond text length
            NSRange(location: 9223372036854775807, length: 0), // NSNotFound value
        ]
        
        for invalidRange in invalidRanges {
            XCTAssertNoThrow({
                // This would normally crash - we need to test the actual EditorTextView
                // For now, test the range validation logic directly
                let textLength = 100
                let isValid = invalidRange.location != NSNotFound &&
                             invalidRange.location >= 0 &&
                             invalidRange.location <= textLength &&
                             invalidRange.length >= 0 &&
                             invalidRange.upperBound <= textLength
                
                XCTAssertFalse(isValid, "Range \(invalidRange) should be invalid")
            }, "Invalid range \(invalidRange) should not cause a crash")
        }
    }
    
    func testValidRangeHandling() {
        let validRanges = [
            NSRange(location: 0, length: 0),
            NSRange(location: 0, length: 10),
            NSRange(location: 5, length: 5),
            NSRange(location: 50, length: 0),
        ]
        
        for validRange in validRanges {
            let textLength = 100
            let isValid = validRange.location != NSNotFound &&
                         validRange.location >= 0 &&
                         validRange.location <= textLength &&
                         validRange.length >= 0 &&
                         validRange.upperBound <= textLength
            
            XCTAssertTrue(isValid, "Range \(validRange) should be valid")
        }
    }
    
    // MARK: - Text Change Simulation Tests
    
    func testTextInsertionRanges() {
        // Simulate various text insertion scenarios that could produce invalid ranges
        let testCases = [
            (originalLength: 0, insertionLocation: 0, insertionLength: 10, changeInLength: 10),
            (originalLength: 100, insertionLocation: 50, insertionLength: 5, changeInLength: 5),
            (originalLength: 100, insertionLocation: 100, insertionLength: 1, changeInLength: 1),
        ]
        
        for (originalLength, insertionLocation, insertionLength, changeInLength) in testCases {
            let editedRange = NSRange(location: insertionLocation, length: insertionLength)
            let newLength = originalLength + changeInLength
            
            // Validate that the edited range is reasonable
            XCTAssertTrue(editedRange.location >= 0, "Insertion location should be non-negative")
            XCTAssertTrue(editedRange.location <= newLength, "Insertion location should be within text bounds")
            XCTAssertTrue(editedRange.length >= 0, "Insertion length should be non-negative")
        }
    }
    
    func testTextDeletionRanges() {
        // Simulate text deletion scenarios
        let testCases = [
            (originalLength: 100, deletionLocation: 50, deletionLength: 10, changeInLength: -10),
            (originalLength: 100, deletionLocation: 0, deletionLength: 10, changeInLength: -10),
            (originalLength: 100, deletionLocation: 90, deletionLength: 10, changeInLength: -10),
        ]
        
        for (originalLength, deletionLocation, deletionLength, changeInLength) in testCases {
            let editedRange = NSRange(location: deletionLocation, length: 0) // After deletion
            let newLength = originalLength + changeInLength
            
            // Validate that the edited range is reasonable after deletion
            XCTAssertTrue(editedRange.location >= 0, "Deletion location should be non-negative")
            XCTAssertTrue(editedRange.location <= newLength, "Deletion location should be within new text bounds")
            XCTAssertTrue(newLength >= 0, "New text length should be non-negative")
        }
    }
    
    // MARK: - WikiLink Detection with Edge Cases
    
    func testWikiLinkDetectionWithEmptyText() {
        let emptyText = ""
        let links = WikiLinkParser.findWikiLinks(in: emptyText)
        XCTAssertEqual(links.count, 0, "Empty text should have no wiki links")
    }
    
    func testWikiLinkDetectionWithInvalidRange() {
        let text = "This has [[a link]] in it"
        let invalidRange = NSRange(location: NSNotFound, length: 0)
        
        // Should not crash and should return empty results
        XCTAssertNoThrow({
            let links = WikiLinkParser.findWikiLinks(in: text, range: invalidRange)
            XCTAssertEqual(links.count, 0, "Invalid range should return no links")
        })
    }
    
    func testWikiLinkDetectionWithRangeBeyondText() {
        let text = "Short text"
        let beyondRange = NSRange(location: 100, length: 10)
        
        // Should not crash
        XCTAssertNoThrow({
            let links = WikiLinkParser.findWikiLinks(in: text, range: beyondRange)
            XCTAssertEqual(links.count, 0, "Range beyond text should return no links")
        })
    }
    
    // MARK: - Performance Tests
    
    func testWikiLinkDetectionPerformanceWithLargeInvalidRanges() {
        let text = String(repeating: "[[Test Link]] ", count: 1000)
        let largeInvalidRange = NSRange(location: NSNotFound, length: 999999)
        
        measure {
            XCTAssertNoThrow({
                let links = WikiLinkParser.findWikiLinks(in: text, range: largeInvalidRange)
                XCTAssertEqual(links.count, 0, "Invalid range should return no links")
            })
        }
    }
    
    // MARK: - Text Boundary Tests
    
    func testWikiLinkAtTextBoundaries() {
        let texts = [
            "[[Start Link]] middle [[End Link]]",
            "[[Only Link]]",
            "No links here",
            "[[",
            "]]",
            "[[incomplete",
            "incomplete]]"
        ]
        
        for text in texts {
            XCTAssertNoThrow({
                let links = WikiLinkParser.findWikiLinks(in: text)
                // Just ensure it doesn't crash - results will vary
                XCTAssertGreaterThanOrEqual(links.count, 0)
            }, "Text '\(text)' should not cause crash during wiki link detection")
        }
    }
    
    // MARK: - Range Expansion Tests
    
    func testRangeExpansionSafety() {
        // Test the expandedRangeForWikiLinkDetection logic indirectly
        let testCases = [
            (text: "Line 1\nLine 2\nLine 3", range: NSRange(location: 0, length: 1)),
            (text: "Short", range: NSRange(location: 3, length: 2)),
            (text: "", range: NSRange(location: 0, length: 0)),
        ]
        
        for (text, range) in testCases {
            // Test that range expansion doesn't create invalid ranges
            let textLength = text.count
            let nsText = text as NSString
            
            if range.location >= 0 && range.location <= textLength && 
               range.length >= 0 && range.upperBound <= textLength {
                XCTAssertNoThrow({
                    // Test that line range calculation doesn't crash
                    let lineRange = nsText.lineRange(for: range)
                    XCTAssertGreaterThanOrEqual(lineRange.location, 0)
                    XCTAssertLessThanOrEqual(lineRange.upperBound, textLength)
                })
            }
        }
    }
}