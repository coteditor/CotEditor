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
import SyntaxFormat
@testable import SyntaxParsers

struct OutlinePolicyTests {
    
    @Test func depthParsesNumericHeadingCaptureLevelTokens() {
        
        let policy = OutlinePolicy()
        
        #expect(policy.depth(captureNameComponents: ["outline", "heading", "2"], captureNode: nil) == 2)
        #expect(policy.depth(captureNameComponents: ["outline", "heading", "0"], captureNode: nil) == 1)
        #expect(policy.depth(captureNameComponents: ["outline", "heading", "10"], captureNode: nil) == 1)
        #expect(policy.depth(captureNameComponents: ["outline", "heading", "h2"], captureNode: nil) == 1)
    }
    
    
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
        
        #expect(normalizedLevels == [0, 0, 0, 1, 1, 1, 1, 0, 0])
    }
    
    
    @Test func normalizeSectionMarkerAtRootAfterDeepNesting() {

        let policy = OutlinePolicy(
            normalization: .init(sectionMarkerKinds: [.separator, .mark], adjustSectionMarkerDepth: true)
        )
        let items: [OutlineItem] = [
            OutlineItem(title: "Struct", range: NSRange(location: 0, length: 1), kind: .container, indent: .level(2)),
            OutlineItem(title: "func", range: NSRange(location: 1, length: 1), kind: .function, indent: .level(5)),
            OutlineItem(title: "prop", range: NSRange(location: 2, length: 1), kind: .value, indent: .level(7)),
            OutlineItem(title: "MARK", range: NSRange(location: 3, length: 1), kind: .mark, indent: .level(2)),
            OutlineItem.separator(range: NSRange(location: 4, length: 1), indent: .level(2)),
            OutlineItem(title: "Preview", range: NSRange(location: 5, length: 1), kind: .function, indent: .level(2)),
        ]

        let normalizedLevels = policy.normalize(items).map(\.indent.level)

        // `MARK` and separator at root depth should return to level 0 after deep nesting.
        #expect(normalizedLevels == [0, 1, 2, 0, 0, 0])
    }


    @Test func normalizeTitleLevels() {
        
        let items: [OutlineItem] = [
            OutlineItem(title: "h1", range: NSRange(location: 0, length: 1), kind: .heading(nil), indent: .level(1)),
            OutlineItem(title: "title-a", range: NSRange(location: 1, length: 1), kind: .title, indent: .level(0)),
            OutlineItem(title: "title-b", range: NSRange(location: 2, length: 1), kind: .title, indent: .level(0)),
            OutlineItem(title: "h2", range: NSRange(location: 3, length: 1), kind: .heading(nil), indent: .level(2)),
            OutlineItem(title: "title-c", range: NSRange(location: 4, length: 1), kind: .title, indent: .level(0)),
            OutlineItem(title: "func", range: NSRange(location: 5, length: 1), kind: .function, indent: .level(3)),
            OutlineItem(title: "title-d", range: NSRange(location: 6, length: 1), kind: .title, indent: .level(0)),
            OutlineItem(title: "h1-b", range: NSRange(location: 7, length: 1), kind: .heading(nil), indent: .level(1)),
        ]
        
        let normalizedLevels = OutlinePolicy().normalize(items).map(\.indent.level)
        
        // title after heading → one level below; title after title/function → same level
        #expect(normalizedLevels == [0, 1, 1, 1, 2, 2, 2, 0])
    }
    
    
    @Test func normalizeTitleAtStart() {
        
        let items: [OutlineItem] = [
            OutlineItem(title: "title-first", range: NSRange(location: 0, length: 1), kind: .title, indent: .level(0)),
            OutlineItem(title: "h1", range: NSRange(location: 1, length: 1), kind: .heading(nil), indent: .level(1)),
        ]
        
        let normalizedLevels = OutlinePolicy().normalize(items).map(\.indent.level)
        
        // title at start → level 0; heading after title → normal normalization
        #expect(normalizedLevels == [0, 0])
    }
    
    
    @Test func titleDoesNotAffectDepthStack() {
        
        let items: [OutlineItem] = [
            OutlineItem(title: "h1", range: NSRange(location: 0, length: 1), kind: .heading(nil), indent: .level(1)),
            OutlineItem(title: "h2", range: NSRange(location: 1, length: 1), kind: .heading(nil), indent: .level(2)),
            OutlineItem(title: "title", range: NSRange(location: 2, length: 1), kind: .title, indent: .level(0)),
            OutlineItem(title: "h2-b", range: NSRange(location: 3, length: 1), kind: .heading(nil), indent: .level(2)),
        ]
        
        let normalizedLevels = OutlinePolicy().normalize(items).map(\.indent.level)
        
        // title should not change the depth stack; h2-b should remain at level 1
        #expect(normalizedLevels == [0, 1, 2, 1])
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
