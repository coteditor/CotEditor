//
//  TextFind.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2023 1024jp
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

struct TextFind {
    
    typealias ReplacementItem = ValueRange<String>
    
    
    enum Mode: Equatable {
        
        case textual(options: String.CompareOptions, fullWord: Bool)  // don't include .backwards to options
        case regularExpression(options: NSRegularExpression.Options, unescapesReplacement: Bool)
    }
    
    
    enum `Error`: LocalizedError {
        
        case regularExpression(reason: String)
        case emptyFindString
        case emptyInSelectionSearch
        
        
        var errorDescription: String? {
            
            switch self {
                case .regularExpression:
                    String(localized: "Invalid regular expression")
                case .emptyFindString:
                    String(localized: "Empty find string")
                case .emptyInSelectionSearch:
                    String(localized: "The option “in selection” is selected, although nothing is selected.")
            }
        }
        
        
        var recoverySuggestion: String? {
            
            switch self {
                case .regularExpression(let reason):
                    reason
                case .emptyFindString:
                    String(localized: "Input text to find.")
                case .emptyInSelectionSearch:
                    String(localized: "Select the search scope in the document or turn off the “in selection” option.")
            }
        }
    }
    
    
    
    // MARK: Public Properties
    
    let findString: String
    let mode: TextFind.Mode
    let inSelection: Bool
    
    let string: String
    let selectedRanges: [NSRange]
    
    
    // MARK: Private Properties
    
    private let regex: NSRegularExpression?
    private let fullWordChecker: NSRegularExpression?
    private let scopeRanges: [NSRange]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Returns a TextFind instance with the specified options.
    ///
    /// - Parameters:
    ///   - string: The string to search.
    ///   - findString: The string for which to search.
    ///   - mode: The settable options for the text search.
    ///   - inSelection: Whether find string only in selectedRanges.
    ///   - selectedRanges: The selected ranges in the text view.
    /// - Throws: `TextFind.Error`
    init(for string: String, findString: String, mode: TextFind.Mode, inSelection: Bool = false, selectedRanges: [NSRange] = [NSRange()]) throws {
        
        assert(!selectedRanges.isEmpty)
        
        guard !findString.isEmpty else {
            throw TextFind.Error.emptyFindString
        }
        
        guard !inSelection || !selectedRanges.allSatisfy(\.isEmpty) else {
            throw TextFind.Error.emptyInSelectionSearch
        }
        
        switch mode {
            case .textual(let options, let isFullWord):
                assert(!options.contains(.backwards))
                self.regex = nil
                self.fullWordChecker = isFullWord ? try! NSRegularExpression(pattern: "^\\b.+\\b$") : nil
                
            case .regularExpression(let options, _):
                do {
                    self.regex = try NSRegularExpression(pattern: findString, options: options)
                } catch {
                    throw TextFind.Error.regularExpression(reason: error.localizedDescription)
                }
                self.fullWordChecker = nil
        }
        
        self.findString = findString
        self.mode = mode
        self.inSelection = inSelection
        self.string = string
        self.selectedRanges = selectedRanges
        self.scopeRanges = inSelection ? selectedRanges : [string.nsRange]
    }
    
    
    // MARK: Public Methods
    
    /// The number of capture groups in the regular expression.
    var numberOfCaptureGroups: Int {
        
        self.regex?.numberOfCaptureGroups ?? 0
    }
    
    
    /// The range large enough to contain all scope ranges.
    var scopeRange: Range<Int> {
        
        self.scopeRanges.map(\.lowerBound).min()!..<self.scopeRanges.map(\.upperBound).max()!
    }
    
    
    /// All matched ranges.
    ///
    /// - Throws: `CancellationError`
    var matches: [NSRange] {
        
        get throws {
            var ranges: [NSRange] = []
            for range in self.scopeRanges {
                self.enumerateMatches(in: range) { (matchedRange, _, stop) in
                    if Task.isCancelled {
                        stop = true
                        return
                    }
                    ranges.append(matchedRange)
                }
            }
            return ranges
        }
    }
    
    
    /// Returns the nearest match in `matches` from the insertion point.
    ///
    /// - Parameters:
    ///   - matches: The matched ranges to find in.
    ///   - forward: Whether searches forward.
    ///   - includingCurrentSelection: Whether includes the current selection to search.
    ///   - wraps: Whether the search wraps around.
    /// - Returns: A character range and flag whether the search wrapped; or `nil` when not found.
    func find(in matches: [NSRange], forward: Bool, includingSelection: Bool = false, wraps: Bool) -> (range: NSRange, wrapped: Bool)? {
        
        assert(forward || !includingSelection)
        
        guard !matches.isEmpty else { return nil }
        
        if self.inSelection {
            guard let foundRange = forward ? matches.first : matches.last else { return nil }
            
            return (range: foundRange, wrapped: false)
        }
        
        let selectedRange = self.selectedRanges.first!
        let startLocation = forward
            ? (includingSelection ? selectedRange.lowerBound : selectedRange.upperBound)
            : (includingSelection ? selectedRange.upperBound : selectedRange.lowerBound)
        
        let foundRange = forward
            ? matches.first { $0.lowerBound >= startLocation }
            : matches.last { $0.upperBound <= startLocation }
        
        if let foundRange {
            return (range: foundRange, wrapped: false)
        }
        
        guard wraps,
              let foundRange = forward ? matches.first : matches.last
        else { return nil }
        
        return (range: foundRange, wrapped: true)
    }
    
    
    /// Returns ReplacementItem replacing matched string in selection.
    ///
    /// - Parameters:
    ///   - replacementString: The string with which to replace.
    /// - Returns: The struct of a string to replace with and a range to replace if found. Otherwise, nil.
    func replace(with replacementString: String) -> ReplacementItem? {
        
        let string = self.string
        let selectedRange = self.selectedRanges.first!
        
        switch self.mode {
            case .textual(let options, _):
                let matchedRange = (string as NSString).range(of: self.findString, options: options, range: selectedRange)
                guard matchedRange.location != NSNotFound else { return nil }
                guard self.checkFullWord(in: matchedRange) else { return nil }
                
                return ReplacementItem(value: replacementString, range: matchedRange)
                
            case .regularExpression:
                let regex = self.regex!
                guard let match = regex.firstMatch(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: selectedRange) else { return nil }
                
                let template = self.replacementString(from: replacementString)
                let replacedString = regex.replacementString(for: match, in: string, offset: 0, template: template)
                
                return ReplacementItem(value: replacedString, range: match.range)
        }
    }
    
    
    /// Finds all matches in the scopes.
    ///
    /// - Parameters:
    ///   - block: The block enumerates the matches.
    ///   - matches: The array of matches including group matches.
    ///   - stop: The `block` can set the value to true to stop further processing.
    func findAll(using block: (_ matches: [NSRange], _ stop: inout Bool) -> Void) {
        
        for range in self.scopeRanges {
            self.enumerateMatches(in: range) { (matchedRange, match, stop) in
                let matches: [NSRange] = if let match {
                    (0..<match.numberOfRanges).map(match.range(at:))
                } else {
                    [matchedRange]
                }
                
                block(matches, &stop)
            }
        }
    }
    
    
    /// Replaces all matches in the scopes.
    ///
    /// - Parameters:
    ///   - replacementString: The string with which to replace.
    ///   - block: The block notifying the replacement progress.
    ///   - range: The matched range.
    ///   - stop: The `block` can set the value to true to stop further processing.
    /// - Returns:
    ///   - replacementItems: ReplacementItem per selectedRange.
    ///   - selectedRanges: New selections for textView only if the replacement is performed within selection. Otherwise, `nil`.
    func replaceAll(with replacementString: String, using block: @escaping (_ range: NSRange, _ count: Int, _ stop: inout Bool) -> Void) -> (replacementItems: [ReplacementItem], selectedRanges: [NSRange]?) {
        
        let replacementString = self.replacementString(from: replacementString)
        var replacementItems: [ReplacementItem] = []
        var selectedRanges: [NSRange] = []
        
        for scopeRange in self.scopeRanges {
            let scopeString = NSMutableString(string: (self.string as NSString).substring(with: scopeRange))
            var ioStop = false
            
            // replace string
            switch self.mode {
                case .textual(options: let options, fullWord: let fullWord) where !fullWord:
                    // replace at once for performance
                    let count = scopeString.replaceOccurrences(of: self.findString, with: replacementString, options: options, range: scopeString.range)
                    block(scopeRange, count, &ioStop)
                    
                default:
                    var offset = 0
                    self.enumerateMatches(in: scopeRange) { (matchedRange, match, stop) in
                        let replacedString: String = if let match, let regex = match.regularExpression {
                            regex.replacementString(for: match, in: self.string, offset: 0, template: replacementString)
                        } else {
                            replacementString
                        }
                        
                        let localRange = matchedRange.shifted(by: -scopeRange.location - offset)
                        scopeString.replaceCharacters(in: localRange, with: replacedString)
                        offset += matchedRange.length - replacedString.length
                        
                        block(matchedRange, 1, &ioStop)
                        stop = ioStop
                    }
            }
            
            guard !ioStop else { break }
            
            // append only when actually modified
            if (self.string as NSString).substring(with: scopeRange) != scopeString as String {
                replacementItems.append(ReplacementItem(value: scopeString.copy() as! String, range: scopeRange))
            }
            
            // build selectedRange
            if self.inSelection {
                let location = zip(selectedRanges, self.selectedRanges)
                    .map { $0.0.length - $0.1.length }
                    .reduce(scopeRange.location, +)
                selectedRanges.append(NSRange(location: location, length: scopeString.length))
            }
        }
        
        selectedRanges.formUnique()
        
        return (replacementItems, self.inSelection ? selectedRanges : nil)
    }
    
    
    
    // MARK: Private Methods
    
    /// Unescapes the given string for replacement string as needed.
    ///
    /// - Parameters:
    ///   - string: The string to use as the replacement template.
    /// - Returns: Unescaped replacement string.
    private func replacementString(from string: String) -> String {
        
        switch self.mode {
            case .regularExpression(_, let unescapes) where unescapes:
                string.unescaped
            case .regularExpression, .textual:
                string
        }
    }
    
    
    /// Checks if the given range is a range of whole word.
    ///
    /// - Parameters:
    ///   - range: The character range to test.
    /// - Returns: Whether the substring of the given range is full word.
    private func checkFullWord(in range: NSRange) -> Bool {
        
        guard let fullWordChecker else { return true }
        
        return fullWordChecker.firstMatch(in: self.string, options: .withTransparentBounds, range: range) != nil
    }
    
    
    /// Enumerates matches in string using current settings.
    ///
    /// - Parameters:
    ///   - range: The range of the string to search.
    ///   - block: The block that enumerates the matches.
    private func enumerateMatches(in range: NSRange, using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void) {
        
        switch self.mode {
            case let .textual(options, fullWord):
                self.enumerateTextualMatches(in: range, options: options, fullWord: fullWord, using: block)
            case .regularExpression:
                self.enumerateRegularExpressionMatches(in: range, using: block)
        }
    }
    
    
    /// Enumerates matches in string using textual search.
    ///
    /// - Parameters:
    ///   - range: The range of the string to search.
    ///   - options: The search options.
    ///   - fullWord: When `true`, only full words are matched.
    ///   - block: The block that enumerates the matches.
    private func enumerateTextualMatches(in range: NSRange, options: String.CompareOptions, fullWord: Bool, using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void) {
        
        guard !self.string.isEmpty else { return }
        
        let string = self.string as NSString
        var searchRange = range
        
        while searchRange.location != NSNotFound {
            searchRange.length = string.length - searchRange.location
            let foundRange = string.range(of: self.findString, options: options, range: searchRange)
            
            guard foundRange.upperBound <= range.upperBound else { break }
            
            searchRange.location = foundRange.upperBound
            
            guard self.checkFullWord(in: foundRange) else { continue }
            
            var stop = false
            block(foundRange, nil, &stop)
            
            guard !stop else { return }
        }
    }
    
    
    /// Enumerates matches in string using regular expression.
    ///
    /// - Parameters:
    ///   - range: The range of the string to search.
    ///   - block: The block that enumerates the matches.
    private func enumerateRegularExpressionMatches(in range: NSRange, using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void) {
        
        let string = self.string
        let options: NSRegularExpression.MatchingOptions = [.withTransparentBounds, .withoutAnchoringBounds]
        
        self.regex!.enumerateMatches(in: string, options: options, range: range) { (result, _, stop) in
            guard let result else { return }
            
            var ioStop = false
            block(result.range, result, &ioStop)
            
            if ioStop {
                stop.pointee = ObjCBool(ioStop)
            }
        }
    }
}
