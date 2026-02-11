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

actor TreeSitterClient: HighlightParsing {
    
    private enum InputEditError: Error {
        
        case invalidRange
        case pointCalculationFailed
    }
    
    
    // MARK: Internal Properties
    
    nonisolated let needsHighlightBuffer: Bool = false
    
    
    // MARK: Private Properties
    
    private let layer: LanguageLayer
    
    /// The current mirrored document content.
    private var content: String = ""
    
    /// The ranges affected by pending edits, in UTF-16 units.
    private var pendingAffectedRanges: EditedRangeSet = .init()
    
    
    // MARK: Lifecycle
    
    init(languageConfig: LanguageConfiguration, languageProvider: @escaping LanguageLayer.LanguageProvider) throws {
        
        self.layer = try LanguageLayer(languageConfig: languageConfig,
                                       configuration: .init(languageProvider: languageProvider))
    }
    
    
    // MARK: HighlightParsing Methods
    
    func update(content: String) {
        
        guard content != self.content else { return }
        
        do {
            try self.noteEdit(editedRange: content.nsRange, delta: content.length - self.content.length, insertedText: content)
        } catch {
            assertionFailure()
            self.resetContent(content)
        }
    }
    
    
    func noteEdit(editedRange: NSRange, delta: Int, insertedText: String) throws {
        
        guard insertedText.length == editedRange.length else {
            throw InputEditError.invalidRange
        }
        
        let oldLength = editedRange.length - delta
        
        guard oldLength >= 0 else { throw InputEditError.invalidRange }
        
        let preEditRange = NSRange(location: editedRange.location, length: oldLength)
        let preEditString = self.content as NSString
        
        guard preEditRange.upperBound <= preEditString.length else {
            throw InputEditError.invalidRange
        }
        
        let postEditContent = preEditString.replacingCharacters(in: preEditRange, with: insertedText)
        let postEditString = postEditContent as NSString
        
        guard
            let startPoint = preEditString.point(at: preEditRange.location),
            let oldEndPoint = preEditString.point(at: preEditRange.upperBound),
            let newEndPoint = postEditString.point(at: editedRange.upperBound)
        else { throw InputEditError.pointCalculationFailed }
        
        self.content = postEditContent
        
        
        let edit = InputEdit(startByte: preEditRange.location * 2,
                             oldEndByte: preEditRange.upperBound * 2,
                             newEndByte: editedRange.upperBound * 2,
                             startPoint: startPoint,
                             oldEndPoint: oldEndPoint,
                             newEndPoint: newEndPoint)
        
        self.layer.applyEdit(edit)
        self.pendingAffectedRanges.append(editedRange: editedRange, changeInLength: delta)
    }
    
    
    func parseHighlights(in string: String, range: NSRange) async throws -> (highlights: [Highlight], updateRange: NSRange)? {
        
        if string != self.content {
            self.resetContent(string)
        }
        
        try Task.checkCancellation()
        
        let content = LanguageLayer.Content(string: string)
        let affectedSet = self.pendingAffectedRanges.indexSet
        let invalidations = self.layer.parse(with: content, affecting: affectedSet, resolveSublayers: true)
        self.pendingAffectedRanges.clear()
        
        try Task.checkCancellation()

        let updateRange = invalidations.unionRange()?.union(range) ?? range
        
        let highlights = try self.layer.highlights(in: updateRange, provider: string.predicateNSStringProvider)
            .compactMap(\.highlight)
            .sorted(using: [KeyPathComparator(\.range.location),
                            KeyPathComparator(\.range.length)])

        return (highlights, updateRange)
    }
    
    
    // MARK: Private Methods
    
    /// Resets the stored content and the tree-sitter layer when incremental edits cannot be applied.
    ///
    /// - Parameters:
    ///   - content: The content to apply.
    private func resetContent(_ content: String) {
        
        self.content = content
        self.layer.replaceContent(with: content)
        self.pendingAffectedRanges.clear()
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


private extension NSString {
    
    /// Returns the tree-sitter point (row/column) at the given UTF-16 location.
    ///
    /// - Parameter location: The UTF-16 offset in the string.
    /// - Returns: The corresponding point, or `nil` if the location is out of bounds.
    func point(at location: Int) -> Point? {
        
        guard (0...self.length).contains(location) else { return nil }
        
        let lineNumber = self.lineNumber(at: location)
        let lineStart = self.lineStartIndex(at: location)
        let column = location - lineStart
        
        return Point(row: lineNumber - 1, column: column)
    }
    
    
    var predicateNSStringProvider: SwiftTreeSitter.Predicate.TextProvider {
        
        { nsRange, _ in self.substring(with: nsRange) }
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
