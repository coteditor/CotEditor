//
//  OutlinePolicyTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-16.
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
@testable import Syntax

struct OutlinePolicyTests {
    
    @Test func normalizeLevels() {
        
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
        
        let normalizedLevels = OutlinePolicy().normalize(items).map(\.indent.level)
        
        #expect(normalizedLevels == [0, 1, 2, 0, 0, 0, 1, 0, nil])
    }
    
    
    @Test func normalizeSectionMarkers() {
        
        let policy = OutlinePolicy(
            normalization: .init(sectionMarkerKinds: [.separator, .mark], adjustSectionMarkerDepth: true)
        )
        let items: [OutlineItem] = [
            OutlineItem(title: "a", range: NSRange(location: 0, length: 1), indent: .level(3)),
            OutlineItem(title: "b", range: NSRange(location: 1, length: 1), indent: .level(5)),
            OutlineItem(title: "MARK", range: NSRange(location: 2, length: 1), kind: .mark, indent: .level(4)),
            OutlineItem.separator(range: NSRange(location: 3, length: 1), indent: .level(4)),
            OutlineItem(title: "c", range: NSRange(location: 4, length: 1), indent: .level(5)),
        ]
        
        let normalizedLevels = policy.normalize(items).map(\.indent.level)
        
        #expect(normalizedLevels == [0, 1, 1, 1, 1])
    }
    
    
    @Test func normalizeSectionMarkersAtEdgesAndConsecutive() {
        
        let policy = OutlinePolicy(
            normalization: .init(sectionMarkerKinds: [.separator, .mark], adjustSectionMarkerDepth: true)
        )
        let items: [OutlineItem] = [
            OutlineItem(title: "MARK-1", range: NSRange(location: 0, length: 1), kind: .mark, indent: .level(4)),
            OutlineItem.separator(range: NSRange(location: 1, length: 1), indent: .level(3)),
            OutlineItem(title: "a", range: NSRange(location: 2, length: 1), indent: .level(2)),
            OutlineItem(title: "b", range: NSRange(location: 3, length: 1), indent: .level(5)),
            OutlineItem(title: "MARK-2", range: NSRange(location: 4, length: 1), kind: .mark, indent: .level(4)),
            OutlineItem.separator(range: NSRange(location: 5, length: 1), indent: .level(4)),
            OutlineItem(title: "c", range: NSRange(location: 6, length: 1), indent: .level(5)),
            OutlineItem(title: "MARK-3", range: NSRange(location: 7, length: 1), kind: .mark, indent: .level(1)),
            OutlineItem.separator(range: NSRange(location: 8, length: 1), indent: .level(1)),
        ]
        
        let normalizedLevels = policy.normalize(items).map(\.indent.level)
        
        #expect(normalizedLevels == [0, 0, 0, 1, 1, 1, 1, 1, 1])
    }
    
    
    @Test func normalizeFlattenLevels() {
        
        let policy = OutlinePolicy(normalization: .init(flattenLevels: true))
        let items: [OutlineItem] = [
            OutlineItem(title: "x", range: NSRange(location: 0, length: 1), indent: .level(4)),
            OutlineItem.separator(range: NSRange(location: 1, length: 1), indent: .level(2)),
            OutlineItem(title: "y", range: NSRange(location: 2, length: 1), indent: .string("")),
        ]
        
        let normalizedLevels = policy.normalize(items).map(\.indent.level)
        
        #expect(normalizedLevels == [0, 0, nil])
    }
    
    
    @Test func normalizeFlattenLevelsWithSectionMarkers() {
        
        let policy = OutlinePolicy(
            normalization: .init(sectionMarkerKinds: [.separator, .mark], adjustSectionMarkerDepth: true, flattenLevels: true)
        )
        let items: [OutlineItem] = [
            OutlineItem(title: "a", range: NSRange(location: 0, length: 1), indent: .level(3)),
            OutlineItem(title: "b", range: NSRange(location: 1, length: 1), kind: .mark, indent: .level(5)),
            OutlineItem.separator(range: NSRange(location: 2, length: 1), indent: .level(4)),
            OutlineItem(title: "c", range: NSRange(location: 3, length: 1), indent: .string("")),
        ]
        
        let normalizedLevels = policy.normalize(items).map(\.indent.level)
        
        #expect(normalizedLevels == [0, 0, 0, nil])
    }
}
