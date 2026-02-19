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

actor TreeSitterClient: HighlightParsing, OutlineParsing {
    
    // MARK: Internal Properties
    
    nonisolated let highlightBuffer = 0
    
    
    // MARK: Private Properties
    
    private let layer: LanguageLayer
    private let syntax: TreeSitterSyntax
    
    /// The current mirrored document content.
    private var content: Content = .init()
    
    /// The ranges affected by pending edits, in UTF-16 units.
    private var pendingAffectedRanges: EditedRangeSet = .init()
    
    
    // MARK: Lifecycle
    
    init(languageConfig: LanguageConfiguration, languageProvider: @escaping LanguageLayer.LanguageProvider, syntax: TreeSitterSyntax) throws {
        
        self.layer = try LanguageLayer(languageConfig: languageConfig,
                                       configuration: .init(languageProvider: languageProvider))
        self.syntax = syntax
    }
    
    
    // MARK: HighlightParsing Methods
    
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
        
        let highlights = try self.layer.highlights(in: updateRange, provider: string.predicateNSStringProvider)
            .compactMap(\.highlight)
            .sorted(using: [KeyPathComparator(\.range.location),
                            KeyPathComparator(\.range.length)])
        
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
        
        let outlineRange = IndexSet(integersIn: Range(string.range)!)
        let cursor = try self.layer.executeQuery(.outline, in: outlineRange)
        let matches = cursor.resolve(with: SwiftTreeSitter.Predicate.Context(textProvider: string.predicateNSStringProvider))
        let formatter = self.syntax.outlineTitleFormatter
        
        return matches
            .flatMap(\.captures)
            .compactMap(OutlineCapture.init(capture:))
            .compactMap { capture -> OutlineItem? in
                if capture.kind == .separator {
                    return OutlineItem.separator(range: capture.range)
                }
                
                let trimmedTitle = (string as NSString).substring(with: capture.range)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard
                    !trimmedTitle.isEmpty,
                    let formattedTitle = formatter(capture.kind, trimmedTitle)
                else { return nil }
                
                let indent = (string as NSString).indentString(for: capture.range)
                
                return OutlineItem(title: formattedTitle, indent: indent, range: capture.range, kind: capture.kind, level: capture.depth)
            }
            .sorted(using: [KeyPathComparator(\.range.location),
                            KeyPathComparator(\.range.length)])
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
}


// MARK: -

private extension NamedRange {
    
    var highlight: Highlight? {
        
        guard
            let baseName = self.nameComponents.first,
            let type = SyntaxType(rawValue: baseName)
        else { return nil }
        
        return ValueRange(value: type, range: self.range)
    }
}


private struct OutlineCapture {
    
    var kind: Syntax.Outline.Kind
    var range: NSRange
    var depth: Int
    
    
    init?(capture: QueryCapture) {
        
        let components = capture.nameComponents
        
        guard
            components.first == "outline",
            components.count > 1,
            let kind = Syntax.Outline.Kind(rawValue: components[1])
        else { return nil }
        
        self.kind = kind
        self.range = capture.range
        self.depth = if components.count > 2, components[1] == "heading" {
            Self.headingLevel(from: components[2])
        } else {
            Array(sequence(first: capture.node, next: \.parent)).count
        }
    }
    
    
    private static func headingLevel(from component: String) -> Int {
        
        switch component {
            case "h1": 1
            case "h2": 2
            case "h3": 3
            case "h4": 4
            case "h5": 5
            case "h6": 6
            case "title": 1
            default: 1
        }
    }
}


private extension NSString {
    
    var predicateNSStringProvider: SwiftTreeSitter.Predicate.TextProvider {
        
        { nsRange, _ in self.substring(with: nsRange) }
    }
    
    
    func indentString(for range: NSRange) -> String {
        
        guard range.location < self.length else { return "" }
        
        let lineStart = self.lineStartIndex(at: range.location)
        let indentRange = self.range(of: "[ \\t]+", options: [.anchored, .regularExpression], range: NSRange(lineStart..<self.length))
        
        guard !indentRange.isNotFound else { return "" }
        
        return self.substring(with: indentRange)
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
