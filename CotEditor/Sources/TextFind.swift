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
    
    enum Mode {
        
        case textual(options: String.CompareOptions, fullWord: Bool)  // don't include .backwards to options
        case regularExpression(options: NSRegularExpression.Options, unescapesReplacement: Bool)
    }
    
    
    enum ReplacingFlag {
        
        case findProgress
        case replacementProgress
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
                    return "The option “in selection” is enabled, although nothing is selected.".localized
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
        
        /// The range of matched or nil if not found.
        var range: NSRange?
        
        /// The ranges of all matches in the scopes.
        var ranges: [NSRange]
        
        /// Whether the search was wrapped to find the result.
        var wrapped: Bool
    }
    
    
    
    // MARK: Public Properties
    
    let mode: TextFind.Mode
    let findString: String
    let string: String
    let selectedRanges: [NSRange]
    let inSelection: Bool
    
    
    // MARK: Private Properties
    
    private let regex: NSRegularExpression?
    private let scopeRanges: [NSRange]
    
    private lazy var fullWordChecker = try! NSRegularExpression(pattern: "^\\b.+\\b$")
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Return an initialized TextFind instance with the specified options.
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
        
        guard !inSelection || selectedRanges.contains(where: { !$0.isEmpty }) else {
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
        
        return self.regex?.numberOfCaptureGroups ?? 0
    }
    
    
    /// Return the nearest match from the insertion point.
    ///
    /// - Parameters:
    ///   - forward: Whether searchs forward from the insertion.
    ///   - isWrap: Whether the search wraps  around.
    ///   - includingCurrentSelection: Whether includes the current selection to search.
    /// - Returns:An FindResult object.
    /// - Throws: `CancellationError`
    func find(forward: Bool, isWrap: Bool, includingSelection: Bool = false) throws -> FindResult {
        
        assert(forward || !includingSelection)
        
        if self.inSelection {
            return self.findInSelection(forward: forward)
        }
        
        let selectedRange = self.selectedRanges.first!
        let startLocation = forward
            ? (includingSelection ? selectedRange.lowerBound : selectedRange.upperBound)
            : (includingSelection ? selectedRange.upperBound : selectedRange.lowerBound)
        
        var forwardMatches: [NSRange] = []  // matches after the start location
        let forwardRange = NSRange(startLocation..<self.string.length)
        self.enumerateMatchs(in: forwardRange) { (matchedRange, _, stop) in
            if Task.isCancelled {
                stop = true
                return
            }
            forwardMatches.append(matchedRange)
        }
        
        try Task.checkCancellation()
        
        var wrappedMatches: [NSRange] = []  // matches before the start location
        var intersectionMatches: [NSRange] = []  // matches including the start location
        self.enumerateMatchs(in: self.string.range) { (matchedRange, _, stop) in
            if Task.isCancelled {
                stop = true
                return
            }
            if matchedRange.location >= startLocation {
                stop = true
                return
            }
            if matchedRange.contains(startLocation) {
                intersectionMatches.append(matchedRange)
            } else {
                wrappedMatches.append(matchedRange)
            }
        }
        
        try Task.checkCancellation()
        
        var foundRange = forward ? forwardMatches.first : wrappedMatches.last
        
        // wrap search
        let isWrapped = (foundRange == nil && isWrap)
        if isWrapped {
            foundRange = forward ? (wrappedMatches + intersectionMatches).first : (intersectionMatches + forwardMatches).last
        }
        
        let ranges = wrappedMatches + intersectionMatches + forwardMatches
        
        return .init(range: foundRange, ranges: ranges, wrapped: isWrapped)
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
    ///   - block: The Block enumerates the matches.
    ///   - matches: The array of matches including group matches.
    ///   - stop: The Block can set the value to true to stop further processing of the array.
    func findAll(using block: (_ matches: [NSRange], _ stop: inout Bool) -> Void) {
        
        let numberOfGroups = self.numberOfCaptureGroups
        
        for range in self.scopeRanges {
            self.enumerateMatchs(in: range) { (matchedRange, match, stop) in
                var matches = [matchedRange]
                
                if let match = match, numberOfGroups > 0 {
                    matches += (1...numberOfGroups).map { match.range(at: $0) }
                }
                
                block(matches, &stop)
            }
        }
    }
    
    
    /// Replace all matches in the scopes.
    ///
    /// - Parameters:
    ///   - replacementString: The string with which to replace.
    ///   - block: The Block enumerates the matches.
    ///   - flag: The current state of the replacing progress.
    ///   - stop: The Block can set the value to true to stop further processing of the array.
    /// - Returns:
    ///   - replacementItems: ReplacementItem per selectedRange.
    ///   - selectedRanges: New selections for textView only if the replacement is performed within selection. Otherwise, nil.
    func replaceAll(with replacementString: String, using block: @escaping (_ flag: ReplacingFlag, _ stop: inout Bool) -> Void) -> (replacementItems: [ReplacementItem], selectedRanges: [NSRange]?) {
        
        let replacementString = self.replacementString(from: replacementString)
        var replacementItems: [ReplacementItem] = []
        var selectedRanges: [NSRange] = []
        var ioStop = false
        
        for scopeRange in self.scopeRanges {
            var items: [ReplacementItem] = []
            
            self.enumerateMatchs(in: scopeRange) { (matchedRange, match, stop) in
                let replacedString: String = {
                    guard let match = match, let regex = match.regularExpression else { return replacementString }
                    
                    return regex.replacementString(for: match, in: self.string, offset: 0, template: replacementString)
                }()
                
                items.append(ReplacementItem(string: replacedString, range: matchedRange))
                
                block(.findProgress, &ioStop)
                stop = ioStop
            }
            
            if ioStop { break }
            
            let length: Int
            if items.isEmpty {
                length = scopeRange.length
            } else {
                // build replacementString
                let replacedString = NSMutableString(string: (self.string as NSString).substring(with: scopeRange))
                for item in items.reversed() {
                    var ioStop = false
                    block(.replacementProgress, &ioStop)
                    if ioStop { break }
                    
                    // -> Do not convert to Range<Index>. It can fail when the range is smaller than String.Character.
                    let substringRange = item.range.shifted(by: -scopeRange.location)
                    replacedString.replaceCharacters(in: substringRange, with: item.string)
                }
                replacementItems.append(ReplacementItem(string: replacedString.copy() as! String, range: scopeRange))
                length = replacedString.length
            }
            
            if ioStop { break }
            
            // build selectedRange
            let locationDelta = zip(selectedRanges, self.selectedRanges)
                .map { $0.0.length - $0.1.length }
                .reduce(scopeRange.location, +)
            let selectedRange = NSRange(location: locationDelta, length: length)
            selectedRanges.append(selectedRange)
        }
        
        return (replacementItems, self.inSelection ? selectedRanges : nil)
    }
    
    
    
    // MARK: Private Methods
    
    /// unescape given string for replacement string only if needed
    private func replacementString(from string: String) -> String {
        
        switch self.mode {
            case .regularExpression(_, let unescapes) where unescapes:
                return string.unescaped
            default:
                return string
        }
    }
    
    
    /// chack if the given range is a range of whole word
    private func isFullWord(range: NSRange) -> Bool {
        
        return self.fullWordChecker.firstMatch(in: self.string, options: .withTransparentBounds, range: range) != nil
    }
    
    
    /// Return a match in selection ranges.
    ///
    /// - Parameters:
    ///   - forward: Whether searchs forward from the insertion.
    /// - Returns:An FindResult object.
    private func findInSelection(forward: Bool) -> FindResult {
        
        assert(self.inSelection)
        
        var matches: [NSRange] = []
        for range in self.selectedRanges {
            self.enumerateMatchs(in: range) { (matchedRange, _, _) in
                matches.append(matchedRange)
            }
        }
        
        let foundRange = forward ? matches.first : matches.last
        
        return .init(range: foundRange, ranges: matches, wrapped: false)
    }
    
    
    /// enumerate matchs in string using current settings
    private func enumerateMatchs(in range: NSRange, using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void) {
        
        switch self.mode {
            case .textual:
                self.enumerateTextualMatchs(in: range, using: block)
            case .regularExpression:
                self.enumerateRegularExpressionMatchs(in: range, using: block)
        }
    }
    
    
    /// enumerate matchs in string using textual search
    private func enumerateTextualMatchs(in range: NSRange, using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void) {
        
        guard !self.string.isEmpty else { return }
        
        guard case let .textual(options, fullWord) = self.mode else { return assertionFailure() }
        
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
    
    
    /// enumerate matchs in string using regular expression
    private func enumerateRegularExpressionMatchs(in range: NSRange, using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void) {
        
        guard !self.string.isEmpty else { return }
        
        let string = self.string
        let regex = self.regex!
        let options: NSRegularExpression.MatchingOptions = [.withTransparentBounds, .withoutAnchoringBounds]
        
        regex.enumerateMatches(in: string, options: options, range: range) { (result, _, stop) in
            guard let result = result else { return }
            
            var ioStop = false
            block(result.range, result, &ioStop)
            if ioStop {
                stop.pointee = ObjCBool(ioStop)
            }
        }
    }
    
}
