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
//  © 2015-2022 1024jp
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

struct ReplacementItem {
    
    let string: String
    let range: NSRange
}



final class TextFind {
    
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
                    return "Invalid regular expression".localized
                case .emptyFindString:
                    return "Empty find string".localized
                case .emptyInSelectionSearch:
                    return "The option “in selection” is selected, although nothing is selected.".localized
            }
        }
        
        
        var recoverySuggestion: String? {
            
            switch self {
                case .regularExpression(let reason):
                    return reason
                case .emptyFindString:
                    return "Input text to find.".localized
                case .emptyInSelectionSearch:
                    return "Select the search scope in the document or turn off the “in selection” option.".localized
            }
        }
    }
    
    
    struct FindResult {
        
        var range: NSRange
        var wrapped: Bool
    }
    
    
    
    // MARK: Public Properties
    
    let findString: String
    let mode: TextFind.Mode
    let inSelection: Bool
    
    let string: String
    let selectedRanges: [NSRange]
    
    
    // MARK: Private Properties
    
    private let regex: NSRegularExpression?
    private let scopeRanges: [NSRange]
    
    private lazy var fullWordChecker = try! NSRegularExpression(pattern: "^\\b.+\\b$")
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Return a TextFind instance with the specified options.
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
            case .textual(let options, _):
                assert(!options.contains(.backwards))
                self.regex = nil
                
            case .regularExpression(let options, _):
                do {
                    self.regex = try NSRegularExpression(pattern: findString, options: options)
                } catch {
                    throw TextFind.Error.regularExpression(reason: error.localizedDescription)
                }
        }
        
        self.mode = mode
        self.string = string
        self.selectedRanges = selectedRanges
        self.findString = findString
        self.inSelection = inSelection
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
                self.enumerateMatchs(in: range) { (matchedRange, _, stop) in
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
    
    
    /// Return the nearest match in `matches` from the insertion point.
    ///
    /// - Parameters:
    ///   - matches: The matched ranges to find in.
    ///   - forward: Whether searchs forward.
    ///   - isWrap: Whether the search wraps around.
    ///   - includingCurrentSelection: Whether includes the current selection to search.
    /// - Returns: A FindResult object.
    func find(in ranges: [NSRange], forward: Bool, isWrap: Bool, includingSelection: Bool = false) -> FindResult? {
        
        assert(forward || !includingSelection)
        
        guard !ranges.isEmpty else { return nil }
        
        if self.inSelection {
            guard let foundRange = forward ? ranges.first : ranges.last else { return nil }
            
            return .init(range: foundRange, wrapped: false)
        }
        
        let selectedRange = self.selectedRanges.first!
        let startLocation = forward
            ? (includingSelection ? selectedRange.lowerBound : selectedRange.upperBound)
            : (includingSelection ? selectedRange.upperBound : selectedRange.lowerBound)
        
        let foundRange = forward
            ? ranges.first { $0.lowerBound >= startLocation }
            : ranges.last { $0.upperBound <= startLocation }
        
        if let foundRange {
            return .init(range: foundRange, wrapped: false)
        }
        
        guard isWrap,
              let foundRange = forward ? ranges.first : ranges.last
        else { return nil }
        
        return .init(range: foundRange, wrapped: true)
    }
    
    
    /// Return ReplacementItem replacing matched string in selection.
    ///
    /// - Parameters:
    ///   - replacementString: The string with which to replace.
    /// - Returns: The struct of a string to replace with and a range to replace if found. Otherwise, nil.
    func replace(with replacementString: String) -> ReplacementItem? {
        
        let string = self.string
        let selectedRange = self.selectedRanges.first!
        
        switch self.mode {
            case let .textual(options, fullWord):
                let matchedRange = (string as NSString).range(of: self.findString, options: options, range: selectedRange)
                guard matchedRange.location != NSNotFound else { return nil }
                guard !fullWord || self.isFullWord(range: matchedRange) else { return nil }
                
                return ReplacementItem(string: replacementString, range: matchedRange)
            
            case .regularExpression:
                let regex = self.regex!
                guard let match = regex.firstMatch(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: selectedRange) else { return nil }
                
                let template = self.replacementString(from: replacementString)
                let replacedString = regex.replacementString(for: match, in: string, offset: 0, template: template)
                
                return ReplacementItem(string: replacedString, range: match.range)
        }
    }
    
    
    /// Find all matches in the scopes.
    ///
    /// - Parameters:
    ///   - block: The block enumerates the matches.
    ///   - matches: The array of matches including group matches.
    ///   - stop: The `block` can set the value to true to stop further processing.
    func findAll(using block: (_ matches: [NSRange], _ stop: inout Bool) -> Void) {
        
        for range in self.scopeRanges {
            self.enumerateMatchs(in: range) { (matchedRange, match, stop) in
                let matches: [NSRange]
                if let match = match {
                    matches = (0..<match.numberOfRanges).map(match.range(at:))
                } else {
                    matches = [matchedRange]
                }
                
                block(matches, &stop)
            }
        }
    }
    
    
    /// Replace all matches in the scopes.
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
                case let .textual(options: options, fullWord: fullWord) where !fullWord:
                    // use .replaceOccurrences(of:with:range:) for performance
                    let count = scopeString.replaceOccurrences(of: self.findString, with: replacementString, options: options, range: scopeString.range)
                    block(scopeRange, count, &ioStop)
                    
                default:
                    var offset = 0
                    self.enumerateMatchs(in: scopeRange) { (matchedRange, match, stop) in
                        let replacedString: String = {
                            guard let match = match, let regex = match.regularExpression else { return replacementString }
                            
                            return regex.replacementString(for: match, in: self.string, offset: 0, template: replacementString)
                        }()
                        
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
                replacementItems.append(ReplacementItem(string: scopeString.copy() as! String, range: scopeRange))
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
    
    /// Unescape the given string for replacement string as needed.
    ///
    /// - Parameters:
    ///   - string: The string to use as the replacement template.
    /// - Returns: Unescaped replacement string.
    private func replacementString(from string: String) -> String {
        
        switch self.mode {
            case .regularExpression(_, let unescapes) where unescapes:
                return string.unescaped
            case .regularExpression, .textual:
                return string
        }
    }
    
    
    /// Chack if the given range is a range of whole word.
    ///
    /// - Parameters:
    ///   - range: The charater range to test.
    /// - Returns: Whether the substring of the given range is full word.
    private func isFullWord(range: NSRange) -> Bool {
        
        self.fullWordChecker.firstMatch(in: self.string, options: .withTransparentBounds, range: range) != nil
    }
    
    
    /// Enumerate matchs in string using current settings.
    ///
    /// - Parameters:
    ///   - range: The range of the string to search.
    ///   - block: The block that enumerates the matches.
    private func enumerateMatchs(in range: NSRange, using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void) {
        
        switch self.mode {
            case let .textual(options, fullWord):
                self.enumerateTextualMatchs(in: range, options: options, fullWord: fullWord, using: block)
            case .regularExpression:
                self.enumerateRegularExpressionMatchs(in: range, using: block)
        }
    }
    
    
    /// Enumerate matchs in string using textual search
    ///
    /// - Parameters:
    ///   - range: The range of the string to search.
    ///   - block: The block that enumerates the matches.
    private func enumerateTextualMatchs(in range: NSRange, options: String.CompareOptions, fullWord: Bool, using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void) {
        
        guard !self.string.isEmpty else { return }
        
        let string = self.string as NSString
        var searchRange = range
        
        while searchRange.location != NSNotFound {
            searchRange.length = string.length - searchRange.location
            let foundRange = string.range(of: self.findString, options: options, range: searchRange)
            
            guard foundRange.upperBound <= range.upperBound else { break }
            
            searchRange.location = foundRange.upperBound
            
            guard !fullWord || self.isFullWord(range: foundRange) else { continue }
            
            var stop = false
            block(foundRange, nil, &stop)
            
            guard !stop else { return }
        }
    }
    
    
    /// Enumerate matchs in string using regular expression.
    ///
    /// - Parameters:
    ///   - range: The range of the string to search.
    ///   - block: The block that enumerates the matches.
    private func enumerateRegularExpressionMatchs(in range: NSRange, using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void) {
        
        let string = self.string
        let options: NSRegularExpression.MatchingOptions = [.withTransparentBounds, .withoutAnchoringBounds]
        
        self.regex!.enumerateMatches(in: string, options: options, range: range) { (result, _, stop) in
            guard let result = result else { return }
            
            var ioStop = false
            block(result.range, result, &ioStop)
            
            if ioStop {
                stop.pointee = ObjCBool(ioStop)
            }
        }
    }
}
