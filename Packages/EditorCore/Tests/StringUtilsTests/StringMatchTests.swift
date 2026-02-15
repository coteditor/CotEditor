//
//  StringMatchTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2016 1024jp
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
@testable import StringUtils

struct StringMatchTests {
    
    private struct Item: Identifiable, Sendable {
        
        let name: String
        
        var id: String { self.name }
    }
    
    
    @Test func filterItem() throws {
        
        let item = Item(name: "CotEditor")
        
        let noFilter = try #require(item.filter("", keyPath: \.name))
        switch noFilter.state {
            case .noFilter:
                #expect(noFilter.string == "CotEditor")
            case .filtered:
                Issue.record("Expected .noFilter state.")
        }
        
        let filtered = try #require(item.filter("cte", keyPath: \.name))
        switch filtered.state {
            case .noFilter:
                Issue.record("Expected .filtered state.")
            case .filtered(let ranges):
                #expect(ranges.count == 3)
        }
        
        #expect(item.filter("zzz", keyPath: \.name) == nil)
    }
    
    
    @Test func abbreviatedMatch() throws {
        
        let string = "The fox jumps over the lazy dogcow."
        
        #expect(string.abbreviatedMatch(with: "quick") == nil)
        
        let dogcow = try #require(string.abbreviatedMatch(with: "dogcow"))
        #expect(dogcow.score == 6)
        #expect(dogcow.ranges.count == 6)
        #expect(dogcow.remaining.isEmpty)
        
        let ow = try #require(string.abbreviatedMatch(with: "ow"))
        #expect(ow.score == 29)
        #expect(ow.ranges.count == 2)
        #expect(ow.remaining.isEmpty)
        
        let lazyTanuki = try #require(string.abbreviatedMatch(with: "lazy tanuki"))
        #expect(lazyTanuki.score == 5)
        #expect(lazyTanuki.ranges.count == 5)
        #expect(lazyTanuki.remaining == "tanuki")
        
        #expect(string.abbreviatedMatchedRanges(with: "lazy tanuki") == nil)
        #expect(string.abbreviatedMatchedRanges(with: "lazy tanuki", incomplete: true)?.count == 5)
        
        #expect(string.abbreviatedMatchedRanges(with: "lazy w")?.count == 6)
        #expect(string.abbreviatedMatchedRanges(with: "lazy w", incomplete: true)?.count == 6)
    }
    
    
    @Test func abbreviatedMatchedRanges() {
        
        let string = "AbC"
        
        #expect(string.abbreviatedMatchedRanges(with: "") == nil)
        #expect("".abbreviatedMatchedRanges(with: "a") == nil)
        #expect(string.abbreviatedMatchedRanges(with: "ac")?.count == 2)
        #expect(string.abbreviatedMatchedRanges(with: "ac", incomplete: true)?.count == 2)
        #expect(string.abbreviatedMatchedRanges(with: "ad") == nil)
        #expect(string.abbreviatedMatchedRanges(with: "ad", incomplete: true)?.count == 1)
    }
    
    
    @Test func attributedString() throws {
        
        let item = Item(name: "tanuki")
        let filtered = try #require(item.filter("tnk", keyPath: \.name))
        let attributed = filtered.attributedString
        let ranges = try #require("tanuki".abbreviatedMatchedRanges(with: "tnk"))
        
        #expect(attributed.inlinePresentationIntent == nil)
        
        for range in ranges {
            let attributedRange = try #require(Range(range, in: attributed))
            #expect(attributed[attributedRange].inlinePresentationIntent == .stronglyEmphasized)
        }
    }
    
    
    @Test func attributedStringNoFilter() throws {
        
        let item = Item(name: "tanuki")
        let noFilter = try #require(item.filter("", keyPath: \.name))
        let attributed = noFilter.attributedString
        
        #expect(String(attributed.characters) == "tanuki")
        #expect(attributed.inlinePresentationIntent == nil)
        #expect(attributed.runs.allSatisfy { $0.inlinePresentationIntent == nil })
    }
}
