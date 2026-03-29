//
//  OutlineItemIdentityResolverTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-02.
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

struct OutlineItemIdentityResolverTests {
    
    @Test func resolveStableIDsWhenRangesShift() throws {
        
        var resolver = OutlineItem.IdentityResolver()
        let oldAlphaID = UUID()
        let oldBetaID = UUID()
        let newAlphaID = UUID()
        let newBetaID = UUID()
        
        let firstItems = resolver.resolve([
            OutlineItem(title: "Alpha", range: NSRange(location: 10, length: 1), kind: .container, id: oldAlphaID),
            OutlineItem(title: "Beta", range: NSRange(location: 20, length: 1), kind: .function, id: oldBetaID),
        ])
        let secondItems = resolver.resolve([
            OutlineItem(title: "Alpha", range: NSRange(location: 40, length: 1), kind: .container, id: newAlphaID),
            OutlineItem(title: "Beta", range: NSRange(location: 50, length: 1), kind: .function, id: newBetaID),
        ])
        
        #expect(secondItems.map(\.id) == firstItems.map(\.id))
    }
    
    
    @Test func resolveStableIDsKeepsInsertedItemAsNew() throws {
        
        var resolver = OutlineItem.IdentityResolver()
        let oldAlphaID = UUID()
        let oldBetaID = UUID()
        let newAlphaID = UUID()
        let insertedGammaID = UUID()
        let newBetaID = UUID()
        
        _ = resolver.resolve([
            OutlineItem(title: "Alpha", range: NSRange(location: 10, length: 1), kind: .container, id: oldAlphaID),
            OutlineItem(title: "Beta", range: NSRange(location: 20, length: 1), kind: .function, id: oldBetaID),
        ])
        let updatedItems = resolver.resolve([
            OutlineItem(title: "Alpha", range: NSRange(location: 11, length: 1), kind: .container, id: newAlphaID),
            OutlineItem(title: "Gamma", range: NSRange(location: 15, length: 1), kind: .function, id: insertedGammaID),
            OutlineItem(title: "Beta", range: NSRange(location: 21, length: 1), kind: .function, id: newBetaID),
        ])
        
        #expect(updatedItems.map(\.id) == [oldAlphaID, insertedGammaID, oldBetaID])
    }
    
    
    @Test func resolveStableIDsWhenItemsMove() throws {
        
        var resolver = OutlineItem.IdentityResolver()
        let oldAlphaID = UUID()
        let oldBetaID = UUID()
        let oldGammaID = UUID()
        let newAlphaID = UUID()
        let newBetaID = UUID()
        let newGammaID = UUID()
        
        _ = resolver.resolve([
            OutlineItem(title: "Alpha", range: NSRange(location: 10, length: 1), kind: .container, id: oldAlphaID),
            OutlineItem(title: "Beta", range: NSRange(location: 20, length: 1), kind: .function, id: oldBetaID),
            OutlineItem(title: "Gamma", range: NSRange(location: 30, length: 1), kind: .function, id: oldGammaID),
        ])
        let updatedItems = resolver.resolve([
            OutlineItem(title: "Gamma", range: NSRange(location: 31, length: 1), kind: .function, id: newGammaID),
            OutlineItem(title: "Alpha", range: NSRange(location: 11, length: 1), kind: .container, id: newAlphaID),
            OutlineItem(title: "Beta", range: NSRange(location: 21, length: 1), kind: .function, id: newBetaID),
        ])
        
        #expect(updatedItems.map(\.id) == [oldGammaID, oldAlphaID, oldBetaID])
    }
    
    
    @Test func resolveStableIDsDoesNotReuseIDWhenKindChanges() throws {
        
        var resolver = OutlineItem.IdentityResolver()
        let oldAlphaID = UUID()
        let newAlphaID = UUID()
        
        _ = resolver.resolve([
            OutlineItem(title: "Alpha", range: NSRange(location: 10, length: 1), kind: .container, id: oldAlphaID),
        ])
        let updatedItems = resolver.resolve([
            OutlineItem(title: "Alpha", range: NSRange(location: 10, length: 1), kind: .function, id: newAlphaID),
        ])
        
        #expect(updatedItems.map(\.id) == [newAlphaID])
    }
    
    
    @Test func resolveStableIDsResetsPreviousSnapshotWhenItemsBecomeEmpty() throws {
        
        var resolver = OutlineItem.IdentityResolver()
        let oldAlphaID = UUID()
        let newAlphaID = UUID()
        
        _ = resolver.resolve([
            OutlineItem(title: "Alpha", range: NSRange(location: 10, length: 1), kind: .container, id: oldAlphaID),
        ])
        _ = resolver.resolve([])
        let updatedItems = resolver.resolve([
            OutlineItem(title: "Alpha", range: NSRange(location: 11, length: 1), kind: .container, id: newAlphaID),
        ])
        
        #expect(updatedItems.map(\.id) == [newAlphaID])
    }
    
    
    @Test func resolveStableIDsWithManyDuplicateKeysKeepsUniqueIDs() throws {
        
        var resolver = OutlineItem.IdentityResolver()
        let oldIDs = (0..<200).map { _ in UUID() }
        let oldIDSet = Set(oldIDs)
        
        let firstItems = oldIDs.enumerated().map { index, id in
            OutlineItem(title: "Item", range: NSRange(location: index * 10, length: 1), kind: .function, id: id)
        }
        _ = resolver.resolve(firstItems)
        
        var newIDs: [UUID] = []
        while newIDs.count < 220 {
            let id = UUID()
            guard !oldIDSet.contains(id) else { continue }
            newIDs.append(id)
        }
        let newIDSet = Set(newIDs)
        
        let secondItems = newIDs.enumerated().map { index, id in
            OutlineItem(title: "Item", range: NSRange(location: index * 10 + 5, length: 1), kind: .function, id: id)
        }
        let updatedItems = resolver.resolve(secondItems)
        
        let updatedIDs = updatedItems.map(\.id)
        let uniqueUpdatedIDs = Set(updatedIDs)
        let reusedCount = updatedIDs.reduce(into: 0) { count, id in
            if oldIDSet.contains(id) {
                count += 1
            }
        }
        let newCount = updatedIDs.reduce(into: 0) { count, id in
            if newIDSet.contains(id) {
                count += 1
            }
        }
        
        #expect(uniqueUpdatedIDs.count == updatedIDs.count)
        #expect(reusedCount == oldIDs.count)
        #expect(newCount == secondItems.count - oldIDs.count)
    }
}
