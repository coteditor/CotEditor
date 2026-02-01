//
//  HighlightSortingTests.swift
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
@testable import Syntax

struct HighlightSortingTests {
    
    @Test func emptyDictionary() throws {
        
        let result = try Highlight.highlights(dictionary: [:])
        
        #expect(result.isEmpty)
    }
    
    
    @Test func basicSorting() throws {
        
        // non-overlapping ranges for different types
        let dict: [SyntaxType: [NSRange]] = [
            .keywords: [NSRange(location: 10, length: 2)],
            .strings: [NSRange(location: 0, length: 3)],
            .comments: [NSRange(location: 5, length: 2)],
        ]
        let result = try Highlight.highlights(dictionary: dict)
        
        #expect(result == [
            Highlight(value: .strings, range: NSRange(location: 0, length: 3)),
            Highlight(value: .comments, range: NSRange(location: 5, length: 2)),
            Highlight(value: .keywords, range: NSRange(location: 10, length: 2)),
        ])
    }
    
    
    @Test func overlapResolutionByPriority() throws {
        
        // overlapping ranges across different types
        let dict: [SyntaxType: [NSRange]] = [
            .strings: [NSRange(location: 0, length: 10)],
            .comments: [NSRange(location: 3, length: 4)],
            .keywords: [NSRange(location: 5, length: 4)],
        ]
        let result = try Highlight.highlights(dictionary: dict)
        
        // 1) No overlaps among output
        for (index, range) in result.map(\.range).enumerated() {
            for nextRange in result[(index + 1)...].map(\.range) {
                #expect(!(range.lowerBound < nextRange.upperBound && nextRange.lowerBound < range.upperBound))
            }
        }
        
        // 2) Coverage equals union of inputs
        func union(_ ranges: [NSRange]) -> IndexSet {
            ranges.reduce(into: IndexSet()) { $0.insert(integersIn: $1.lowerBound..<$1.upperBound) }
        }
        let inputUnion = union(dict.values.flatMap(\.self))
        let outputUnion = union(result.map(\.range))
        #expect(inputUnion == outputUnion)
        
        // 3) Deterministic order by location
        let sortedByLocation = result.sorted(using: KeyPathComparator(\.range.location))
        #expect(result == sortedByLocation)
        
        // 4) Sanity check that some portion near 5..9 is attributed to exactly one type
        let coveredAt6 = result.filter { $0.range.contains(6) }
        #expect(coveredAt6.count == 1)
    }
    
    
    @Test func subtractOverlapsProducesHoles() throws {
        
        let inner = NSRange(location: 3, length: 4)
        let outer = NSRange(location: 0, length: 10)
        let dict: [SyntaxType: [NSRange]] = [
            .values: [inner],
            .keywords: [outer],
        ]
        
        let result = try Highlight.highlights(dictionary: dict)
        
        #expect(result.count == 3)
        #expect(result[0] == Highlight(value: .keywords, range: NSRange(location: 0, length: 3)))
        #expect(result[1] == Highlight(value: .values, range: NSRange(location: 3, length: 4)))
        #expect(result[2] == Highlight(value: .keywords, range: NSRange(location: 7, length: 3)))
    }
    
    
    @Test func subtractOverlapsWinsHigherPriorityKey() throws {
        
        let inner = NSRange(location: 3, length: 4)
        let outer = NSRange(location: 0, length: 10)
        let dict: [SyntaxType: [NSRange]] = [
            .values: [outer],
            .keywords: [inner],
        ]
        
        let result = try Highlight.highlights(dictionary: dict)
        
        #expect(result.count == 1)
        #expect(result[0] == Highlight(value: .values, range: outer))
    }
    
    
    @Test func cancellation() async throws {
        
        let dict: [SyntaxType: [NSRange]] = [
            .strings: [NSRange(location: 0, length: 1000)],
            .comments: [NSRange(location: 0, length: 1000)],
            .keywords: [NSRange(location: 0, length: 1000)],
        ]
        
        let task = Task<[Highlight], any Error> {
            try Task.checkCancellation()
            return try ValueRange<SyntaxType>.highlights(dictionary: dict)
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
    }
}
