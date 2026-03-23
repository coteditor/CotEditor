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
import StringUtils
import ValueRange

import SwiftTreeSitter
import SwiftTreeSitterLayer

actor TreeSitterClient: IncrementalParsing, HighlightParsing, OutlineParsing {
    
    // MARK: Internal Properties
    
    nonisolated let highlightBuffer = 0
    
    
    // MARK: Private Properties
    
    private let layer: LanguageLayer
    private let syntax: TreeSitterSyntax
    
    /// The current mirrored document content.
    private var content: Content = .init()
    
    /// The ranges affected by pending edits, in UTF-16 units.
    private var pendingAffectedRanges: EditedRangeSet = .init()
    
    /// Resolves stable outline item identities across successive parses.
    private var outlineIdentityResolver: OutlineItem.IdentityResolver = .init()
    
    
    // MARK: Lifecycle
    
    init(languageConfig: LanguageConfiguration, languageProvider: @escaping LanguageLayer.LanguageProvider, syntax: TreeSitterSyntax) throws {
        
        self.layer = try LanguageLayer(languageConfig: languageConfig,
                                       configuration: .init(languageProvider: languageProvider))
        self.syntax = syntax
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
        
        let edit = try self.content.applyEdit(editedRange: editedRange, delta: delta, insertedText: insertedText)
        
        self.layer.applyEdit(edit)
        self.pendingAffectedRanges.append(editedRange: editedRange, changeInLength: delta)
    }
    
    
    // MARK: HighlightParsing Methods
    
    func parseHighlights(in string: String, range: NSRange) async throws -> (highlights: [Highlight], updateRange: NSRange)? {
        
        if string != self.content.string {
            self.resetContent(string)
        }
        
        try Task.checkCancellation()
        
        let content = LanguageLayer.Content(string: string)
        let invalidations = !self.pendingAffectedRanges.isEmpty
            ? self.layer.parse(with: content, affecting: self.pendingAffectedRanges.indexSet, resolveSublayers: true)
            : []
        self.pendingAffectedRanges.clear()
        
        try Task.checkCancellation()
        
        let updateRange = invalidations.unionRange()?.union(range) ?? range
        let highlights = try self.queryMatches(.highlights, in: updateRange, string: string as NSString)
            .flatMap(\.captures)
            .sorted()
            .compactMap(Highlight.init(capture:))
        
        return (highlights, updateRange)
    }
    
    
    // MARK: OutlineParsing Methods
    
    func parseOutline(in string: String) async throws -> [OutlineItem] {
        
        if string != self.content.string {
            self.resetContent(string)
        }
        
        try Task.checkCancellation()
        
        let content = LanguageLayer.Content(string: string)
        if !self.pendingAffectedRanges.isEmpty {
            // -> Outline parsing should not consume pending ranges; highlights are expected to run first.
            _ = self.layer.parse(with: content, affecting: self.pendingAffectedRanges.indexSet, resolveSublayers: true)
        }
        
        try Task.checkCancellation()
        
        let policy = self.syntax.outlinePolicy
        let formatter = self.syntax.outlineFormatter
        let source = string as NSString
        let items: [OutlineItem] = try self.queryMatches(.outline, in: string.range, string: source).lazy
            .filter { $0.treeDepth == 0 }  // ignore injection
            .compactMap { formatter.item(for: $0, source: source, policy: policy) }
        let normalizedItems = policy.normalize(items)
        
        try Task.checkCancellation()
        
        return self.outlineIdentityResolver.resolve(normalizedItems)
            .removingDuplicateIDs
    }
    
    
    // MARK: Private Methods
    
    /// Resets the stored content and the tree-sitter layer when incremental edits cannot be applied.
    ///
    /// - Parameters:
    ///   - content: The content to apply.
    private func resetContent(_ content: String) {
        
        self.content.reset(content)
        self.layer.replaceContent(with: content)
        self.pendingAffectedRanges.update(editedRange: content.nsRange)
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
