//
//  RegexHighlightParserTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-01.
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

import Testing
import Foundation
import ValueRange
import StringUtils
@testable import Syntax

struct RegexHighlightParserTests {
    
    /// Minimal stub extractor to feed deterministic ranges.
    private struct StubExtractor: HighlightExtractable {
        
        let ranges: [NSRange]
        
        func ranges(in string: String, range: NSRange) throws -> [NSRange] { self.ranges }
    }
    
    
    @Test func returnsEmptyWhenNoParsers() async throws {
        
        let parser = RegexHighlightParser(extractors: [:], nestables: [:])
        let highlights = try await parser.parseHighlights(in: "", range: NSRange(0..<0))
        
        #expect(highlights.isEmpty)
    }
    
    
    @Test func mergesExtractorsAndNestables() async throws {
        
        let extractors: [SyntaxType: [any HighlightExtractable]] = [
            .keywords: [StubExtractor(ranges: [NSRange(location: 0, length: 3)])],
            .strings: [StubExtractor(ranges: [NSRange(location: 10, length: 2)])],
        ]
        let nestables: [NestableToken: SyntaxType] = [
            .inline("#", leadingOnly: false): .comments
        ]
        let parser = RegexHighlightParser(extractors: extractors, nestables: nestables)
        let source = """
                     abc def ghi # cmt
                     ..........
                     
                     """
        
        let highlights = try await parser.parseHighlights(in: source, range: source.nsRange)
        
        #expect(highlights.count >= 3)
        #expect(highlights == highlights.sorted(using: KeyPathComparator(\.range.location)))
        
        // -> The order is not specified.
        #expect(highlights.contains { $0.value == .keywords && $0.range == NSRange(location: 0, length: 3) })
        #expect(highlights.contains { $0.value == .strings && $0.range == NSRange(location: 10, length: 2) })
        #expect(highlights.contains { $0.value == .comments })
    }
    
    
    @Test func overlapIsResolvedAndCoverageMaintained() async throws {
        
        let valueRange = NSRange(location: 0, length: 10)
        let numberRange = NSRange(location: 3, length: 4)
        let extractors: [SyntaxType: [any HighlightExtractable]] = [
            .values: [StubExtractor(ranges: [valueRange])],
            .numbers: [StubExtractor(ranges: [numberRange])],
        ]
        let parser = RegexHighlightParser(extractors: extractors, nestables: [:])
        let source = String(repeating: "x", count: 10)
        
        let highlights = try await parser.parseHighlights(in: source, range: source.nsRange)
        
        #expect(highlights.map(\.range).union == [valueRange, numberRange].union)
        
        for (index, highlight) in highlights.enumerated() {
            for nextHighlight in highlights[(index + 1)...] {
                #expect(!(highlight.lowerBound < nextHighlight.upperBound && nextHighlight.lowerBound < highlight.upperBound))
            }
        }
    }
    
    
    @Test func cancellation() async throws {
        
        let many = [NSRange](repeating: NSRange(location: 0, length: 5000), count: 40)
        let extractors: [SyntaxType: [any HighlightExtractable]] = [
            .keywords: [StubExtractor(ranges: many)],
            .strings: [StubExtractor(ranges: many)],
        ]
        let parser = RegexHighlightParser(extractors: extractors, nestables: [:])
        let source = String(repeating: "a", count: 5000)
        
        let task = Task<[Highlight], any Error> {
            try Task.checkCancellation()
            return try await parser.parseHighlights(in: source, range: source.nsRange)
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
    }
}


// MARK: -

private extension [NSRange] {
    
    var union: IndexSet {
        
        self.reduce(into: IndexSet()) { $0.insert(integersIn: $1.lowerBound..<$1.upperBound) }
    }
}
