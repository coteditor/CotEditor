//
//  TreeSitterClient.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2025-2026 1024jp
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
import StringUtils
import ValueRange

import SwiftTreeSitter
import SwiftTreeSitterLayer

actor TreeSitterClient: IncrementalParsing, HighlightParsing, OutlineParsing {
    
    // MARK: Internal Properties
    
    nonisolated static let maximumParseLength = 100_000_000
    
    nonisolated let highlightBuffer = 0
    
    
    // MARK: Private Properties
    
    private var layer: LanguageLayer
    private let languageConfig: LanguageConfiguration
    private let layerConfiguration: LanguageLayer.Configuration
    private let syntax: TreeSitterSyntax
    private let maximumParseLength: Int
    
    /// The current mirrored document content.
    private var content: Content = .init()
    
    /// The ranges affected by pending edits, in UTF-16 units.
    private var pendingAffectedRanges: EditedRangeSet = .init()
    
    /// Resolves stable outline item identities across successive parses.
    private var outlineIdentityResolver: OutlineItem.IdentityResolver = .init()
    
    
    // MARK: Lifecycle
    
    init(languageConfig: LanguageConfiguration, languageProvider: @escaping LanguageLayer.LanguageProvider, syntax: TreeSitterSyntax, maximumParseLength: Int = TreeSitterClient.maximumParseLength) throws {
        
        precondition(maximumParseLength > 0)
        
        let configuration = LanguageLayer.Configuration(languageProvider: languageProvider)
        
        self.layer = try LanguageLayer(languageConfig: languageConfig, configuration: configuration)
        self.languageConfig = languageConfig
        self.layerConfiguration = configuration
        self.syntax = syntax
        self.maximumParseLength = maximumParseLength
    }
    
    
    // MARK: IncrementalParsing Methods
    
    func update(content: String) {
        
        guard content != self.content.string else { return }
        
        do {
            try self.noteEdit(editedRange: content.nsRange, delta: content.length - self.content.string.length, insertedText: content)
        } catch {
            assertionFailure()
            self.resetContent(content)
        }
    }
    
    
    func noteEdit(editedRange: NSRange, delta: Int, insertedText: String) throws {
        
        let oldParseRange = self.parseRange
        let wasCapped = self.content.string.length > self.maximumParseLength
        let edit = try self.content.applyEdit(editedRange: editedRange, delta: delta, insertedText: insertedText)
        
        if wasCapped || self.content.string.length > self.maximumParseLength {
            let parseRange = self.parseRange
            if editedRange.location >= oldParseRange.upperBound,
               editedRange.location >= parseRange.upperBound,
               oldParseRange.length == parseRange.length
            {
                return
            }
            
            self.resetLayer()
            return
        }
        
        self.layer.applyEdit(edit)
        self.pendingAffectedRanges.append(editedRange: editedRange, changeInLength: delta)
    }
    
    
    // MARK: HighlightParsing Methods
    
    func parseHighlights(in string: String, range: NSRange) async throws -> (highlights: [Highlight], updateRange: NSRange)? {
        
        if string != self.content.string {
            self.resetContent(string)
        }
        
        let parseRange = self.parseRange
        
        guard parseRange.length > 0 else { return nil }
        
        try Task.checkCancellation()
        
        let content = LanguageLayer.Content(string: string, limit: parseRange.length)
        let invalidations = !self.pendingAffectedRanges.isEmpty
            ? self.layer.parse(with: content, affecting: self.pendingAffectedRanges.indexSet, resolveSublayers: true)
            : []
        self.pendingAffectedRanges.clear()
        
        try Task.checkCancellation()
        
        guard
            let updateRange = (invalidations.unionRange()?.union(range) ?? range).intersection(parseRange)
        else { return nil }
        
        let highlights = try self.queryMatches(.highlights, in: updateRange, string: string as NSString)
            .flatMap(\.captures)
            .sorted()
            .resolvingCaptureConflicts()
            .compactMap(Highlight.init(capture:))
        
        return (highlights, updateRange)
    }
    
    
    // MARK: OutlineParsing Methods
    
    func parseOutline(in string: String) async throws -> [OutlineItem] {
        
        if string != self.content.string {
            self.resetContent(string)
        }
        
        let parseRange = self.parseRange
        
        guard parseRange.length > 0 else { return [] }
        
        try Task.checkCancellation()
        
        let content = LanguageLayer.Content(string: string, limit: parseRange.length)
        
        if !self.pendingAffectedRanges.isEmpty {
            // -> Outline parsing should preserve pending ranges when highlights are available,
            //    because highlight parsing uses them to compute the next update range.
            _ = self.layer.parse(with: content, affecting: self.pendingAffectedRanges.indexSet, resolveSublayers: true)
            
            if !self.syntax.features.contains(.highlight) {
                self.pendingAffectedRanges.clear()
            }
        }
        
        try Task.checkCancellation()
        
        let policy = self.syntax.outlinePolicy
        let formatter = self.syntax.outlineFormatter
        let source = string as NSString
        let items: [OutlineItem] = try self.queryMatches(.outline, in: parseRange, string: source).lazy
            .filter { $0.treeDepth == 0 }  // ignore injection
            .compactMap { formatter.item(for: $0, source: source, policy: policy) }
        let normalizedItems = policy.normalize(items)
        
        try Task.checkCancellation()
        
        return self.outlineIdentityResolver.resolve(normalizedItems)
            .removingDuplicateIDs
    }
    
    
    // MARK: Private Methods
    
    /// The current parse range capped by `maximumParseLength`.
    private var parseRange: NSRange {
        
        NSRange(0..<min(self.content.string.length, self.maximumParseLength))
    }
    
    
    /// Resets the stored content and the tree-sitter layer when incremental edits cannot be applied.
    ///
    /// - Parameters:
    ///   - content: The content to apply.
    private func resetContent(_ content: String) {
        
        self.content.reset(content)
        self.resetLayer()
    }
    
    
    /// Recreates the tree-sitter layer and marks the capped parse range as pending.
    private func resetLayer() {
        
        self.layer = try! LanguageLayer(languageConfig: self.languageConfig, configuration: self.layerConfiguration)
        self.pendingAffectedRanges.clear()
        
        let parseRange = self.parseRange
        if parseRange.length > 0 {
            self.pendingAffectedRanges.update(editedRange: parseRange)
        }
    }
    
    
    /// Executes a tree-sitter query and collects all resolved matches.
    ///
    /// - Parameters:
    ///   - definition: The query definition to execute.
    ///   - range: The UTF-16 range in which the query should run.
    ///   - string: The full source text used to resolve query predicates.
    /// - Returns: The resolved matches produced by the query in cursor order.
    private func queryMatches(_ definition: Query.Definition, in range: NSRange, string: NSString) throws -> [QueryMatch] {
        
        let cursor = try self.layer.executeQuery(definition, in: range)
        let context = Predicate.Context { nsRange, _ in string.substring(with: nsRange) }
        var matchSequence = cursor.resolve(with: context)
        
        var matches: [QueryMatch] = []
        while let match = matchSequence.next() {
            try Task.checkCancellation()
            matches.append(match)
        }
        
        return matches
    }
}


// MARK: -

private extension [QueryCapture] {
    
    /// A key identifying a unique tree-sitter node for capture conflict resolution.
    private struct CaptureNodeKey: Hashable {
        
        var depth: Int
        var location: Int
        var length: Int
    }
    
    
    /// Resolves multiple captures on the same node by keeping only the one with the highest pattern index,
    /// implementing tree-sitter's standard "last pattern wins" precedence.
    ///
    /// This enables query authors to write a broad default rule first (e.g. `(identifier) @variables`)
    /// and override it with more specific patterns later. A later pattern whose capture name does not map
    /// to any `SyntaxType` (e.g. `@_skip`) effectively cancels the highlight for that node.
    ///
    /// - Returns: A filtered array retaining the original sort order.
    func resolvingCaptureConflicts() -> [QueryCapture] {
        
        // find the winning (highest patternIndex) array index for each node
        var bestForNode: [CaptureNodeKey: (arrayIndex: Int, patternIndex: Int)] = [:]
        for (index, capture) in self.enumerated() {
            let key = CaptureNodeKey(depth: capture.depth, location: capture.range.location, length: capture.range.length)
            if let existing = bestForNode[key] {
                if capture.patternIndex > existing.patternIndex {
                    bestForNode[key] = (index, capture.patternIndex)
                }
            } else {
                bestForNode[key] = (index, capture.patternIndex)
            }
        }
        
        let winningIndices = Set(bestForNode.values.lazy.map(\.arrayIndex))
        
        return self.enumerated()
            .filter { winningIndices.contains($0.offset) }
            .map(\.element)
    }
}


private extension Highlight {
    
    init?(capture: QueryCapture) {
        
        guard
            let baseName = capture.nameComponents.first,
            let type = SyntaxType(rawValue: baseName)
        else { return nil }
        
        self.init(value: type, range: capture.range)
    }
}


private extension IndexSet {
    
    func unionRange() -> NSRange? {
        
        guard
            let lower = self.rangeView.first?.lowerBound,
            let upper = self.rangeView.last?.upperBound
        else { return nil }
        
        return NSRange(location: lower, length: upper - lower)
    }
}
