//
//  SyntaxController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2026 1024jp
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
import Combine
import AppKit.NSTextStorage
import OSLog
import StringUtils
import Syntax

extension NSAttributedString.Key {
    
    static let syntaxType = NSAttributedString.Key("CotEditor.SyntaxType")
}


@MainActor final class SyntaxController {
    
    // MARK: Public Properties
    
    private(set) var syntax: Syntax
    private(set) var syntaxName: String
    
    var theme: Theme?
    
    @Published private(set) var outlineItems: [OutlineItem]?
    
    
    // MARK: Private Properties
    
    private let textStorage: NSTextStorage
    private var highlightParser: (any HighlightParsing)?
    private var outlineParser: (any OutlineParsing)?
    
    private var highlightParseTask: Task<Void, any Error>?
    private var outlineParseTask: Task<Void, any Error>?
    private var invalidRanges: EditedRangeSet
    private var isReady = false
    
    
    // MARK: Lifecycle
    
    /// Creates a controller to manage syntax parsing for the given text storage and syntax.
    ///
    /// - Parameters:
    ///   - textStorage: The text storage to modify with highlight attributes.
    ///   - syntax: The syntax definition that provides parsers.
    ///   - name: The of the syntax.
    init(textStorage: NSTextStorage, syntax: Syntax, name: String) {
         
        self.textStorage = textStorage
        self.syntax = syntax
        self.syntaxName = name
        
        self.invalidRanges = EditedRangeSet(range: textStorage.range)
    }
    
    
    isolated deinit {
        self.cancel()
    }
    
    
    // MARK: Public Methods
    
    /// Sets up parsers and starts the initial parse.
    func setupParser() {
        
        self.cancel()
        
        self.highlightParser = try? LanguageRegistry.shared.highlightParser(name: self.syntaxName) ?? self.syntax.highlightParser
        self.outlineParser = self.syntax.outlineParser
        self.isReady = true
        
        Task {
            if let parser = self.highlightParser {
                let content = self.textStorage.string.immutable
                await parser.update(content: content)
            }
            self.parseAll()
        }
    }
    
    
    /// Cancels all remaining parsing tasks.
    func cancel() {
        
        self.highlightParseTask?.cancel()
        self.highlightParseTask = nil
        self.outlineParseTask?.cancel()
        self.outlineParseTask = nil
    }
    
    
    /// Updates the syntax definition and resets parsing state.
    ///
    /// - Parameters:
    ///   - syntax: The new syntax.
    ///   - name: The of the syntax.
    func update(syntax: Syntax, name: String) {
        
        self.cancel()
        
        self.syntax = syntax
        self.syntaxName = name
        
        guard self.isReady else { return }
        
        // clear current highlight
        if self.highlightParser != nil {
            self.textStorage.apply(highlights: [], theme: nil, in: self.textStorage.range)
        }
        
        self.setupParser()
    }
    
    
    /// Marks a range as needing re-highlighting, coalescing with prior edits.
    ///
    /// - Parameters:
    ///   - editedRange: The edited range.
    ///   - delta: The change in length.
    func invalidate(in editedRange: NSRange, changeInLength delta: Int) {
        
        assert(self.isReady)
        
        self.highlightParseTask?.cancel()
        self.highlightParseTask = nil
        
        self.invalidRanges.append(editedRange: editedRange, changeInLength: delta)
        
        guard let parser = self.highlightParser else { return }
        
        let insertedText = (self.textStorage.string as NSString).substring(with: editedRange)
        Task {
            do {
                try await parser.noteEdit(editedRange: editedRange, delta: delta, insertedText: insertedText)
            } catch {
                Logger.app.debug("failed noting edit: \(error.localizedDescription) in \(#function)")
                await parser.update(content: self.textStorage.string)
            }
        }
    }
    
    
    /// Triggers parsing for the minimal invalidated scope.
    ///
    /// Applies a short debounce before parsing to allow the text system to settle.
    func parseIfNeeded() {
        
        assert(self.isReady)
        
        self.updateOutline(withDelay: true)
        self.highlightIfNeeded(withDelay: true)
    }
    
    
    /// Re-parses the entire document immediately.
    func parseAll() {
        
        assert(self.isReady)
        
        self.invalidRanges.update(editedRange: self.textStorage.range)
        
        self.updateOutline(withDelay: false)
        self.highlightIfNeeded(withDelay: false)
    }

    
    // MARK: Private Methods
    
    /// Updates highlights around the invalid ranges if needed.
    ///
    /// - Parameters:
    ///   - withDelay: If `true`, applies a short debounce before parsing.
    private func highlightIfNeeded(withDelay: Bool = false) {
        
        self.highlightParseTask?.cancel()
        
        guard !self.invalidRanges.isEmpty else { return }
        
        self.highlightParseTask = Task { [unowned self] in
            if withDelay {
                // -> Perform not in the same run loop at least to give layoutManagers time to update their values.
                try await Task.sleep(for: .seconds(0.02))  // debounce
            }
            
            guard
                !self.textStorage.range.isEmpty,
                let parser = self.highlightParser,
                let invalidRange = self.invalidRanges.range
            else { return }
            
            // in case that wholeRange length becomes shorter than invalidRange
            guard invalidRange.upperBound <= self.textStorage.length else {
                Logger.app.debug("Invalid range \(invalidRange.description) for \(self.textStorage.length) length textStorage is passed to \(#function)")
                return
            }
            
            let highlightRange = parser.needsHighlightBuffer
                ? self.textStorage.expandHighlightRange(for: invalidRange, bufferLength: 2_000)
                : invalidRange
            
            // parse in background
            let string = self.textStorage.string.immutable
            let result = try await parser.parseHighlights(in: string, range: highlightRange)
           
            if let result {
                self.textStorage.apply(highlights: result.highlights, theme: self.theme, in: result.updateRange)
            }
            
            self.invalidRanges.clear()
        }
    }
    
    
    /// Parses the document outline and publishes the result.
    ///
    /// - Parameters:
    ///   - withDelay: If `true`, applies a short debounce before parsing.
    private func updateOutline(withDelay: Bool = false) {
        
        self.outlineParseTask?.cancel()
        
        guard
            !self.textStorage.range.isEmpty,
            let parser = self.outlineParser
        else {
            self.outlineItems = []
            return
        }
        
        self.outlineParseTask = Task {
            if withDelay {
                try await Task.sleep(for: .seconds(0.4))  // debounce
            }
            self.outlineItems = nil
            let string = self.textStorage.string.immutable
            self.outlineItems = try await parser.parseOutline(in: string)
        }
    }
}


// MARK: -

private extension NSTextStorage {
    
    /// Expands a dirty range to a safe highlighting range.
    ///
    /// - Parameters:
    ///   - invalidRange: The range that was edited or invalidated.
    ///   - bufferLength: The number of characters to extend on both sides.
    /// - Returns: A range expanded to include entire lines and adjacent tokens of the same syntax type.
    @MainActor func expandHighlightRange(for invalidRange: NSRange, bufferLength: Int = 0) -> NSRange {
        
        let lowerBound = max(invalidRange.lowerBound - bufferLength, 0)
        let upperBound = min(invalidRange.upperBound + bufferLength, self.length)
        var range = (self.string as NSString).lineRange(for: NSRange(lowerBound..<upperBound))
        
        guard
            range.length != self.length,
            let layoutManager = self.layoutManagers.first
        else { return range }
        
        // expand the range if the characters just before/after it is the same syntax type
        if range.lowerBound > 0,
           let effectiveRange = layoutManager.effectiveRange(of: .syntaxType, at: range.lowerBound)
        {
            range = NSRange(effectiveRange.lowerBound..<range.upperBound)
        }
        if range.upperBound < self.length,
           let effectiveRange = layoutManager.effectiveRange(of: .syntaxType, at: range.upperBound)
        {
            range = NSRange(range.lowerBound..<effectiveRange.upperBound)
        }
        
        return range
    }
}
