//
//  OutlineItem.IdentityResolver.swift
//  Syntax
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
import SyntaxFormat

extension OutlineItem {
    
    struct IdentityResolver: Sendable {
        
        private var previousItems: [OutlineItem] = []
        
        
        /// Returns items whose IDs are reused from the previous resolved snapshot when possible.
        ///
        /// - Parameter items: The newly parsed outline items.
        /// - Returns: Outline items with stable IDs.
        /// - Complexity: Approximately O(n log n), where `n` is the number of outline items.
        mutating func resolve(_ items: [OutlineItem]) -> [OutlineItem] {
            
            let resolvedItems = self.reusingStableIDs(in: items)
            self.previousItems = resolvedItems
            
            return resolvedItems
        }
    }
}


// MARK: - Private

private extension OutlineItem.IdentityResolver {
    
    private static let moveInferenceItemLimit = 1_000
    
    
    private struct AssignmentState {
        
        var resolvedItems: [OutlineItem]
        var assignedOldOffsets: [Int?]
        var usedOldOffsets: Set<Int> = []
        
        
        /// Creates state used while assigning stable IDs.
        ///
        /// - Parameter items: The current outline items that receive reused IDs.
        init(items: [OutlineItem]) {
            
            self.resolvedItems = items
            self.assignedOldOffsets = [Int?](repeating: nil, count: items.count)
        }
    }
    
    
    private struct IdentityKey: Hashable {
        
        var title: String
        var kind: Syntax.Outline.Kind?
        
        
        /// Creates an identity key from an outline item.
        ///
        /// - Parameter item: The source outline item.
        init(_ item: OutlineItem) {
            
            self.title = item.title
            self.kind = item.kind
        }
    }
    
    
    /// Reuses IDs from `previousItems` and returns a new list with stabilized identities.
    ///
    /// - Parameters:
    ///   - items: The newly parsed outline items.
    /// - Returns: Outline items with reused IDs where possible.
    func reusingStableIDs(in items: [OutlineItem]) -> [OutlineItem] {
        
        guard
            !items.isEmpty,
            !self.previousItems.isEmpty
        else { return items }
        
        let currentKeys = items.map(IdentityKey.init)
        let previousKeys = self.previousItems.map(IdentityKey.init)
        let difference = (max(currentKeys.count, previousKeys.count) <= Self.moveInferenceItemLimit)
            ? currentKeys.difference(from: previousKeys).inferringMoves()
            : currentKeys.difference(from: previousKeys)
            // -> Skip move inference for large outlines to keep diff computation cheaper.
        
        var assignmentState = AssignmentState(items: items)
        let changedOffsets = self.assignIDsForMoves(in: difference, assignmentState: &assignmentState)
        self.assignIDsForStableSequence(changedOffsets: changedOffsets, assignmentState: &assignmentState)
        self.assignRemainingIDsByKey(assignmentState: &assignmentState)
        
        return assignmentState.resolvedItems
    }
    
    
    /// Assigns an ID from a previous item to a current item and records the mapping.
    ///
    /// - Parameters:
    ///   - oldOffset: The source index in the previous outline items.
    ///   - newOffset: The destination index in the current outline items.
    ///   - assignmentState: The state that tracks assignments while resolving IDs.
    private func assignID(from oldOffset: Int, to newOffset: Int, assignmentState: inout AssignmentState) {
        
        assignmentState.resolvedItems[newOffset].id = self.previousItems[oldOffset].id
        assignmentState.assignedOldOffsets[newOffset] = oldOffset
        assignmentState.usedOldOffsets.insert(oldOffset)
    }
    
    
    /// Applies IDs for move-associated changes and collects changed offsets in a single pass.
    ///
    /// - Parameters:
    ///   - difference: The difference from previous keys to current keys.
    ///   - assignmentState: The state that tracks assignments while resolving IDs.
    /// - Returns: Removed old offsets and inserted new offsets.
    private func assignIDsForMoves(in difference: CollectionDifference<IdentityKey>, assignmentState: inout AssignmentState) -> (removed: IndexSet, inserted: IndexSet) {
        
        var removedOldOffsets = IndexSet()
        var insertedNewOffsets = IndexSet()
        
        for change in difference {
            switch change {
                case let .remove(oldOffset, _, _):
                    removedOldOffsets.insert(oldOffset)
                case let .insert(newOffset, _, oldOffset?):
                    insertedNewOffsets.insert(newOffset)
                    if newOffset < assignmentState.resolvedItems.count,
                       oldOffset < self.previousItems.count
                    {
                        self.assignID(from: oldOffset, to: newOffset, assignmentState: &assignmentState)
                    }
                case let .insert(newOffset, _, nil):
                    insertedNewOffsets.insert(newOffset)
            }
        }
        
        return (removedOldOffsets, insertedNewOffsets)
    }
    
    
    /// Applies IDs for the stable subsequence shared between old and new outlines.
    ///
    /// - Parameters:
    ///   - changedOffsets: Removed old offsets and inserted new offsets.
    ///   - assignmentState: The state that tracks assignments while resolving IDs.
    private func assignIDsForStableSequence(changedOffsets: (removed: IndexSet, inserted: IndexSet), assignmentState: inout AssignmentState) {
        
        var oldOffset = 0
        var newOffset = 0
        while oldOffset < self.previousItems.count, newOffset < assignmentState.resolvedItems.count {
            if changedOffsets.removed.contains(oldOffset) {
                oldOffset += 1
                continue
            }
            if changedOffsets.inserted.contains(newOffset) {
                newOffset += 1
                continue
            }
            if assignmentState.assignedOldOffsets[newOffset] == nil {
                self.assignID(from: oldOffset, to: newOffset, assignmentState: &assignmentState)
            }
            
            oldOffset += 1
            newOffset += 1
        }
    }
    
    
    /// Applies IDs for unresolved items by matching keys in document order.
    ///
    /// - Parameters:
    ///   - assignmentState: The state that tracks assignments while resolving IDs.
    private func assignRemainingIDsByKey(assignmentState: inout AssignmentState) {
        
        var remainingOffsetsByKey: [IdentityKey: IndexSet] = [:]
        for (oldOffset, item) in self.previousItems.enumerated() where !assignmentState.usedOldOffsets.contains(oldOffset) {
            remainingOffsetsByKey[IdentityKey(item), default: IndexSet()].insert(oldOffset)
        }
        
        var lastUsedOldOffset = -1
        for newOffset in assignmentState.resolvedItems.indices where assignmentState.assignedOldOffsets[newOffset] == nil {
            let key = IdentityKey(assignmentState.resolvedItems[newOffset])
            
            guard
                var candidateOffsets = remainingOffsetsByKey[key],
                !candidateOffsets.isEmpty,
                let oldOffset = candidateOffsets.integerGreaterThan(lastUsedOldOffset) ?? candidateOffsets.first
            else { continue }
            
            candidateOffsets.remove(oldOffset)
            
            self.assignID(from: oldOffset, to: newOffset, assignmentState: &assignmentState)
            lastUsedOldOffset = oldOffset
            
            remainingOffsetsByKey[key] = candidateOffsets.isEmpty ? nil : candidateOffsets
        }
    }
}
