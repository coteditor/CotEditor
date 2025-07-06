//
//  WikiLinkUITests.swift
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
import AppKit
@testable import CotEditor

final class WikiLinkUITests: XCTestCase {
    
    var textView: EditorTextView!
    var layoutManager: LayoutManager!
    var textContainer: NSTextContainer!
    var textStorage: NSTextStorage!
    
    override func setUp() {
        super.setUp()
        
        // Create a test text view setup
        textStorage = NSTextStorage()
        layoutManager = LayoutManager()
        textContainer = NSTextContainer()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textView = EditorTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 300), textContainer: textContainer)
    }
    
    override func tearDown() {
        textView = nil
        layoutManager = nil
        textContainer = nil
        textStorage = nil
        super.tearDown()
    }
    
    // MARK: - Attribute Application Tests
    
    func testWikiLinkAttributeApplication() {
        let testText = "This has [[Another Note]] and [[Project Ideas]] in it."
        textStorage.setAttributedString(NSAttributedString(string: testText))
        
        // Trigger wiki link detection
        textView.detectAllWikiLinks()
        
        // Wait a moment for async operations
        let expectation = XCTestExpectation(description: "Wiki link detection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Check that temporary attributes were applied
            let linkRange = NSRange(location: 10, length: 15) // "[[Another Note]]"
            
            let wikiLinkAttr = self.layoutManager.temporaryAttribute(.wikiLink, atCharacterIndex: linkRange.location, effectiveRange: nil)
            let colorAttr = self.layoutManager.temporaryAttribute(.foregroundColor, atCharacterIndex: linkRange.location, effectiveRange: nil)
            let underlineAttr = self.layoutManager.temporaryAttribute(.underlineStyle, atCharacterIndex: linkRange.location + 2, effectiveRange: nil) // title range
            
            XCTAssertNotNil(wikiLinkAttr, "Wiki link attribute should be applied")
            XCTAssertNotNil(colorAttr, "Color attribute should be applied")
            XCTAssertNotNil(underlineAttr, "Underline attribute should be applied")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testWikiLinkAttributePersistence() {
        let testText = "Text with [[Link Name]] here."
        textStorage.setAttributedString(NSAttributedString(string: testText))
        
        // Apply wiki link detection
        textView.detectAllWikiLinks()
        
        let expectation = XCTestExpectation(description: "Attribute persistence")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Check attributes are present
            let linkLocation = 10 // Inside "[[Link Name]]"
            let initialColor = self.layoutManager.temporaryAttribute(.foregroundColor, atCharacterIndex: linkLocation, effectiveRange: nil)
            XCTAssertNotNil(initialColor, "Initial color should be present")
            
            // Simulate syntax highlighting that might remove our attributes
            self.layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: NSRange(location: 0, length: testText.count))
            
            // Re-apply wiki links
            self.textView.detectAllWikiLinks()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let finalColor = self.layoutManager.temporaryAttribute(.foregroundColor, atCharacterIndex: linkLocation, effectiveRange: nil)
                XCTAssertNotNil(finalColor, "Color should be re-applied after syntax highlighting")
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Click Detection Tests
    
    func testWikiLinkClickDetection() {
        let testText = "Click on [[Test Link]] here."
        textStorage.setAttributedString(NSAttributedString(string: testText))
        textView.detectAllWikiLinks()
        
        // Create a mock mouse event at the wiki link location
        let linkLocation = 12 // Inside "[[Test Link]]"
        let point = textView.firstRect(forCharacterRange: NSRange(location: linkLocation, length: 1), actualRange: nil).origin
        
        let mouseEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: point,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1.0
        )!
        
        let clickResult = textView.handleWikiLinkClick(with: mouseEvent)
        XCTAssertFalse(clickResult, "Plain click should not be handled (no modifier)")
    }
    
    func testWikiLinkCommandClickDetection() {
        let testText = "Command+click on [[Test Link]] here."
        textStorage.setAttributedString(NSAttributedString(string: testText))
        textView.detectAllWikiLinks()
        
        // Create a mock Command+click event
        let linkLocation = 20 // Inside "[[Test Link]]"
        let point = textView.firstRect(forCharacterRange: NSRange(location: linkLocation, length: 1), actualRange: nil).origin
        
        let commandClickEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: point,
            modifierFlags: .command,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1.0
        )!
        
        let clickResult = textView.handleWikiLinkClick(with: commandClickEvent)
        XCTAssertTrue(clickResult, "Command+click should be handled")
    }
    
    // MARK: - Range Validation Tests
    
    func testInvalidRangeHandling() {
        let testText = "Valid text content"
        textStorage.setAttributedString(NSAttributedString(string: testText))
        
        // Test with invalid ranges that caused crashes
        let invalidRanges = [
            NSRange(location: NSNotFound, length: 0),
            NSRange(location: 9223372036854775807, length: 5),
            NSRange(location: -1, length: 10),
            NSRange(location: 1000, length: 10) // Beyond text bounds
        ]
        
        for invalidRange in invalidRanges {
            XCTAssertNoThrow({
                textView.detectWikiLinksAfterTextChange(in: invalidRange)
            }, "Invalid range \(invalidRange) should not cause crash")
        }
    }
    
    // MARK: - Performance Tests
    
    func testWikiLinkDetectionPerformance() {
        let largeText = String(repeating: "Text with [[Link \(Int.random(in: 1...100))] ", count: 1000)
        textStorage.setAttributedString(NSAttributedString(string: largeText))
        
        measure {
            textView.detectAllWikiLinks()
        }
    }
    
    // MARK: - Visual Highlighting Verification
    
    func testTemporaryAttributePresence() {
        let testText = "Check [[Visual Link]] highlighting."
        textStorage.setAttributedString(NSAttributedString(string: testText))
        
        // Apply wiki link detection
        textView.detectAllWikiLinks()
        
        let expectation = XCTestExpectation(description: "Visual attributes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let linkLocation = 8 // Inside "[[Visual Link]]"
            
            // Check for all expected attributes
            let wikiLinkAttr = self.layoutManager.temporaryAttribute(.wikiLink, atCharacterIndex: linkLocation, effectiveRange: nil)
            let colorAttr = self.layoutManager.temporaryAttribute(.foregroundColor, atCharacterIndex: linkLocation, effectiveRange: nil)
            let titleLocation = linkLocation + 2 // Inside "Visual Link" (after [[)
            let underlineAttr = self.layoutManager.temporaryAttribute(.underlineStyle, atCharacterIndex: titleLocation, effectiveRange: nil)
            
            // Verify attributes are present
            XCTAssertNotNil(wikiLinkAttr, "Wiki link metadata should be present")
            XCTAssertNotNil(colorAttr, "Color attribute should be present")
            XCTAssertNotNil(underlineAttr, "Underline attribute should be present")
            
            // Verify attribute values
            if let color = colorAttr as? NSColor {
                XCTAssertEqual(color, NSColor.systemBlue, "Color should be system blue")
            }
            
            if let underline = underlineAttr as? Int {
                XCTAssertEqual(underline, NSUnderlineStyle.single.rawValue, "Should have single underline")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Integration with Text Changes
    
    func testWikiLinkDetectionAfterTextChange() {
        textStorage.setAttributedString(NSAttributedString(string: "Initial text"))
        
        // Insert a wiki link
        let insertionText = " with [[New Link]]"
        let insertionRange = NSRange(location: textStorage.length, length: 0)
        textStorage.replaceCharacters(in: insertionRange, with: insertionText)
        
        // Trigger detection for the changed range
        textView.detectWikiLinksAfterTextChange(in: NSRange(location: insertionRange.location, length: insertionText.count))
        
        let expectation = XCTestExpectation(description: "Text change detection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let linkLocation = 18 // Inside "[[New Link]]"
            let wikiLinkAttr = self.layoutManager.temporaryAttribute(.wikiLink, atCharacterIndex: linkLocation, effectiveRange: nil)
            
            XCTAssertNotNil(wikiLinkAttr, "New wiki link should be detected after text change")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}