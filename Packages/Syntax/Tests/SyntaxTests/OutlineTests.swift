//
//  OutlineTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2026 1024jp
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
import StringUtils
import Testing
@testable import Syntax

struct OutlineTests {
    
    private let items: [OutlineItem] = [
        OutlineItem(title: "dog", range: NSRange(location: 10, length: 5)),         // 0
        OutlineItem.separator(range: NSRange(location: 20, length: 5)),
        OutlineItem.separator(range: NSRange(location: 30, length: 5)),
        OutlineItem(title: "dogcow", range: NSRange(location: 40, length: 5)),      // 3
        OutlineItem.separator(range: NSRange(location: 50, length: 5)),
        OutlineItem(title: "cow", range: NSRange(location: 60, length: 5)),         // 5
        OutlineItem.separator(range: NSRange(location: 70, length: 5)),
    ]
    
    private let emptyItems: [OutlineItem] = []
    
    
    @Test func index() throws {
        
        #expect(self.emptyItems.item(at: 10) == nil)
        
        #expect(self.items.item(at: 9) == nil)
        #expect(self.items.item(at: 10) == self.items[0])
        #expect(self.items.item(at: 18) == self.items[0])
        #expect(self.items.item(at: 20) == self.items[0])
        #expect(self.items.item(at: 40) == self.items[3])
        #expect(self.items.item(at: 50) == self.items[3])
        #expect(self.items.item(at: 59) == self.items[3])
        #expect(self.items.item(at: 60) == self.items[5])
    }
    
    
    @Test func previousItem() throws {
        
        #expect(self.emptyItems.previousItem(for: NSRange(10..<20)) == nil)
        
        #expect(self.items.previousItem(for: NSRange(10..<20)) == nil)
        #expect(self.items.previousItem(for: NSRange(19..<19)) == nil)
        #expect(self.items.previousItem(for: NSRange(59..<70)) == items[0])
        #expect(self.items.previousItem(for: NSRange(60..<70)) == items[3])
    }
    
    
    @Test func nextItem() throws {
        
        #expect(self.emptyItems.nextItem(for: NSRange(10..<20)) == nil)
        
        #expect(self.items.nextItem(for: NSRange(0..<0)) == items[0])
        #expect(self.items.nextItem(for: NSRange(0..<10)) == items[3])
        #expect(self.items.nextItem(for: NSRange(40..<40)) == items[5])
        #expect(self.items.nextItem(for: NSRange(60..<60)) == nil)
        #expect(self.items.nextItem(for: NSRange(40..<61)) == nil)
    }
    
    
    @Test func filter() throws {
        
        #expect(self.items.compactMap { $0.filter("", keyPath: \.title) }.count == 7)
        #expect(self.items.compactMap { $0.filter("cat", keyPath: \.title) }.count == 0)
        #expect(self.items.compactMap { $0.filter("dog", keyPath: \.title) }.count == 2)
        #expect(self.items.compactMap { $0.filter("dow", keyPath: \.title) }.count == 1)
    }
    
    
    @Test func normalizedLevels() throws {
        
        let items: [OutlineItem] = [
            OutlineItem(title: "a", range: NSRange(location: 0, length: 1), indent: .level(3)),
            OutlineItem(title: "b", range: NSRange(location: 1, length: 1), indent: .level(5)),
            OutlineItem(title: "c", range: NSRange(location: 2, length: 1), indent: .level(6)),
            OutlineItem(title: "d", range: NSRange(location: 3, length: 1), indent: .level(4)),
            OutlineItem(title: "e", range: NSRange(location: 4, length: 1), indent: .level(2)),
            OutlineItem(title: "f", range: NSRange(location: 5, length: 1), indent: .level(2)),
            OutlineItem(title: "g", range: NSRange(location: 6, length: 1), indent: .level(7)),
            OutlineItem.separator(range: NSRange(location: 7, length: 1), indent: .level(2)),
            OutlineItem(title: "h", range: NSRange(location: 8, length: 1), indent: .string("")),
        ]
        
        let normalizedLevels = items.normalizedLevels().map(\.indent.level)
        
        #expect(normalizedLevels == [0, 1, 2, 0, 0, 0, 1, 0, nil])
    }
    
    
    @Test func normalizedLevelsSectionMarkersDoNotAffectFollowingHierarchy() throws {
        
        let items: [OutlineItem] = [
            OutlineItem(title: "a", range: NSRange(location: 0, length: 1), indent: .level(3)),
            OutlineItem(title: "b", range: NSRange(location: 1, length: 1), indent: .level(5)),
            OutlineItem(title: "MARK", range: NSRange(location: 2, length: 1), kind: .mark, indent: .level(4)),
            OutlineItem.separator(range: NSRange(location: 3, length: 1), indent: .level(4)),
            OutlineItem(title: "c", range: NSRange(location: 4, length: 1), indent: .level(5)),
        ]
        
        let policy = OutlineNormalizationPolicy(
            sectionMarkerKinds: [.separator, .mark],
            adjustSectionMarkerDepth: true
        )
        let normalizedLevels = items.normalizedLevels(policy: policy)
            .map(\.indent.level)
        
        #expect(normalizedLevels == [0, 1, 1, 1, 1])
    }
    
    
    @Test func normalizedLevelsCanBeFlattened() throws {
        
        let items: [OutlineItem] = [
            OutlineItem(title: "a", range: NSRange(location: 0, length: 1), indent: .level(3)),
            OutlineItem(title: "b", range: NSRange(location: 1, length: 1), kind: .mark, indent: .level(5)),
            OutlineItem.separator(range: NSRange(location: 2, length: 1), indent: .level(4)),
            OutlineItem(title: "c", range: NSRange(location: 3, length: 1), indent: .string("")),
        ]
        
        let policy = OutlineNormalizationPolicy(
            sectionMarkerKinds: [.separator, .mark],
            adjustSectionMarkerDepth: true,
            flattenLevels: true
        )
        let normalizedLevels = items.normalizedLevels(policy: policy)
            .map(\.indent.level)
        
        #expect(normalizedLevels == [0, 0, 0, nil])
    }
    
    
    @Test func removingDuplicateIDs() throws {
        
        struct TestItem: Identifiable, Equatable {
            
            var id: Int
            var value: String
        }
        
        let items: [TestItem] = [
            TestItem(id: 1, value: "a"),
            TestItem(id: 1, value: "b"),
            TestItem(id: 2, value: "c"),
            TestItem(id: 3, value: "d"),
            TestItem(id: 3, value: "e"),
        ]
        
        let uniqueItems = items.removingDuplicateIDs
        
        #expect(uniqueItems == [
            TestItem(id: 1, value: "a"),
            TestItem(id: 2, value: "c"),
            TestItem(id: 3, value: "d"),
        ])
    }
}
