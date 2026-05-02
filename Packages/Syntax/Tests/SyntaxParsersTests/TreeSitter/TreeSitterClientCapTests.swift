//
//  TreeSitterClientCapTests.swift
//  SyntaxParsersTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

import Foundation
import Testing
import StringUtils
import SyntaxFormat
import ValueRange
@testable import SyntaxParsers

struct TreeSitterClientCapTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func limitsHighlightingToParseCap() async throws {
        
        let cappedSource = "func inside() {}\n"
        let source = cappedSource + "func outside() {}\n"
        let client = try self.swiftClient(maximumParseLength: cappedSource.length)
        
        let result = try #require(await client.parseHighlights(in: source, range: source.nsRange))
        let highlightedTexts = self.highlightedTexts(in: result, source: source)
        
        #expect(result.updateRange.upperBound <= cappedSource.length)
        #expect(highlightedTexts.contains("inside"))
        #expect(!highlightedTexts.contains("outside"))
    }
    
    
    @Test func ignoresEditsAfterParseCap() async throws {
        
        let cappedSource = "func inside() {}\n"
        let source = cappedSource + "func outside() {}\n"
        let client = try self.swiftClient(maximumParseLength: cappedSource.length)
        
        _ = try #require(await client.parseHighlights(in: source, range: source.nsRange))
        
        let editTarget = "outside"
        let insertedText = "beyond"
        let editLocation = (source as NSString).range(of: editTarget).location
        let editedRange = NSRange(location: editLocation, length: insertedText.length)
        let editedSource = (source as NSString).replacingCharacters(in: NSRange(location: editLocation, length: editTarget.length), with: insertedText)
        
        try await client.noteEdit(editedRange: editedRange, delta: insertedText.length - editTarget.length, insertedText: insertedText)
        let outsideResult = try await client.parseHighlights(in: editedSource, range: editedRange)
        
        #expect(outsideResult == nil)
        
        let result = try #require(await client.parseHighlights(in: editedSource, range: editedSource.nsRange))
        let highlightedTexts = self.highlightedTexts(in: result, source: editedSource)
        
        #expect(highlightedTexts.contains("inside"))
        #expect(!highlightedTexts.contains("beyond"))
    }
    
    
    @Test func resetsParserForEditsCrossingParseCap() async throws {
        
        let cappedSource = "func inside() {}\n"
        let source = cappedSource + "func outside() {}\n"
        let client = try self.swiftClient(maximumParseLength: cappedSource.length)
        
        _ = try #require(await client.parseHighlights(in: source, range: source.nsRange))
        
        let deletedRange = NSRange(location: cappedSource.length - 1, length: 6)
        let editedSource = (source as NSString).replacingCharacters(in: deletedRange, with: "")
        
        try await client.noteEdit(editedRange: NSRange(location: deletedRange.location, length: 0), delta: -deletedRange.length, insertedText: "")
        
        let result = try #require(await client.parseHighlights(in: editedSource, range: editedSource.nsRange))
        
        #expect(result.updateRange.location == 0)
        #expect(result.updateRange.length == cappedSource.length)
    }
    
    
    // MARK: Private Methods
    
    /// Returns a Swift tree-sitter client with the given parse length cap.
    ///
    /// - Parameters:
    ///   - maximumParseLength: The maximum UTF-16 length to parse.
    /// - Returns: A Swift parser client.
    private func swiftClient(maximumParseLength: Int) throws -> TreeSitterClient {
        
        let config = try self.registry.configuration(for: .swift)
        
        return try TreeSitterClient(languageConfig: config,
                                    languageProvider: self.registry.languageProvider,
                                    syntax: .swift,
                                    maximumParseLength: maximumParseLength)
    }
    
    
    /// Returns the highlighted texts in the given source.
    ///
    /// - Parameters:
    ///   - result: The parse result to inspect.
    ///   - source: The highlighted source string.
    /// - Returns: The texts represented by this parse result.
    private func highlightedTexts(in result: (highlights: [Highlight], updateRange: NSRange), source: String) -> [String] {
        
        result.highlights.map { (source as NSString).substring(with: $0.range) }
    }
}
