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
//  © 2015-2018 1024jp
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
        case foundCount(Int)
        case replacementProgress
    }
    
    
    enum `Error`: LocalizedError {
        
        case regularExpression(reason: String)
        case emptyFindString
        
        
        var errorDescription: String? {
            
            switch self {
            case .regularExpression:
                return "Invalid regular expression".localized
            case .emptyFindString:
                return "Empty find string".localized
            }
        }
        
        
        var recoverySuggestion: String? {
            
            switch self {
            case .regularExpression(let reason):
                return reason
            case .emptyFindString:
                return "Input text to find.".localized
            }
        }
        
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
        
        switch mode {
        case .textual(let options, _):
            assert(!options.contains(.backwards))
            
            self.regex = nil
            
        case .regularExpression(let options, _):
            let sanitizedFindString: String = {
                // replace `\v` with `\u000b`
                //   -> Because NSRegularExpression cannot handle `\v` correctly. (2017-07 on macOS 10.12)
                //   cf. https://github.com/coteditor/CotEditor/issues/713
                if findString.contains("\\v") {
                    return findString.replacingOccurrences(of: "(?<!\\\\)\\\\v", with: "\\\\u000b", options: .regularExpression)
                }
                return findString
            }()
            
            do {
                self.regex = try NSRegularExpression(pattern: sanitizedFindString, options: options)
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
    ///   - forward: Whether search forward from the insertion.
    ///   - isWrap: Whetehr search wrap search around.
    /// - Returns:
    ///   - range: The range of matched or nil if not found.
    ///   - count: The total number of matches in the scopes.
    ///   - wrapped: Whether the search was wrapped to find the result.
    func find(forward: Bool, isWrap: Bool) -> (range: NSRange?, count: Int, wrapped: Bool) {
        
        if self.inSelection {
            return self.findInSelection(forward: forward)
        }
        
        let selectedRange = self.selectedRanges.first!
        let startLocation = forward ? selectedRange.upperBound : selectedRange.location
        
        var forwardMatches = [NSRange]()  // matches after the start location
        let forwardRange = NSRange(startLocation..<string.utf16.count)
        self.enumerateMatchs(in: [forwardRange], using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            forwardMatches.append(matchedRange)
        })
        
        var wrappedMatches = [NSRange]()  // matches before the start location
        var intersectionMatches = [NSRange]()  // matches including the start location
        self.enumerateMatchs(in: [self.string.nsRange], using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            if matchedRange.location >= startLocation {
                stop = true
                return
            }
            if matchedRange.contains(startLocation) {
                intersectionMatches.append(matchedRange)
            } else {
                wrappedMatches.append(matchedRange)
            }
        })
        
        var foundRange: NSRange? = forward ? forwardMatches.first : wrappedMatches.last
        
        // wrap search
        let isWrapped = (foundRange == nil && isWrap)
        if isWrapped {
            foundRange = forward ? (wrappedMatches + intersectionMatches).first : (intersectionMatches + forwardMatches).last
        }
        
        let count = forwardMatches.count + wrappedMatches.count + intersectionMatches.count
        
        return (foundRange, count, isWrapped)
    }
    
    
    /// Return a match in selection ranges.
    ///
    /// - Parameters:
    ///   - forward: Whether search forward from the insertion.
    /// - Returns:
    ///   - range: The range of matched or nil if not found.
    ///   - count: The total number of matches in the scopes.
    ///   - wrapped: Whether the search was wrapped to find the result.
    func findInSelection(forward: Bool) -> (range: NSRange?, count: Int, wrapped: Bool) {
        
        var matches = [NSRange]()
        self.enumerateMatchs(in: self.selectedRanges, using: { (matchedRange, _, _) in
            matches.append(matchedRange)
        })
        
        let foundRange = forward ? matches.first : matches.last
        
        return (foundRange, matches.count, false)
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
    /// - Parameter
    ///   - block: The Block enumerates the matches.
    ///   - matches: The array of matches including group matches.
    ///   - stop: The Block can set the value to true to stop further processing of the array.
    func findAll(using block: (_ matches: [NSRange], _ stop: inout Bool) -> Void) {
        
        let numberOfGroups = self.numberOfCaptureGroups
        
        self.enumerateMatchs(in: self.scopeRanges, using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            
            var matches = [matchedRange]
            
            if let match = match, numberOfGroups > 0 {
                matches += (1...numberOfGroups).map { match.range(at: $0) }
            }
            
            block(matches, &stop)
        })
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
        var replacementItems = [ReplacementItem]()
        var selectedRanges = [NSRange]()
        var ioStop = false
        
        // temporal container collecting replacements to process string per selection in `scopeCompletionHandler` block
        var items = [ReplacementItem]()
        
        self.enumerateMatchs(in: self.scopeRanges, using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            
            let replacedString: String = {
                guard let match = match, let regex = match.regularExpression else { return replacementString }
                
                return regex.replacementString(for: match, in: self.string, offset: 0, template: replacementString)
            }()
            
            items.append(ReplacementItem(string: replacedString, range: matchedRange))
            
            block(.findProgress, &ioStop)
            stop = ioStop
            
        }, scopeCompletionHandler: { (scopeRange: NSRange) in
            block(.foundCount(items.count), &ioStop)
            
            let length: Int
            if items.isEmpty {
                length = scopeRange.length
            } else {
                // build replacementString
                var replacedString = (self.string as NSString).substring(with: scopeRange)
                for item in items.reversed() {
                    block(.replacementProgress, &ioStop)
                    if ioStop { return }
                    
                    let substringRange = NSRange(location: item.range.location - scopeRange.location, length: item.range.length)
                    guard let range = Range(substringRange, in: replacedString) else { assertionFailure(); continue }
                    replacedString.replaceSubrange(range, with: item.string)
                }
                replacementItems.append(ReplacementItem(string: replacedString, range: scopeRange))
                length = (replacedString as NSString).length
            }
            
            // build selectedRange
            let locationDelta = zip(selectedRanges, self.selectedRanges)
                .map { $0.0.length - $0.1.length }
                .reduce(scopeRange.location, +)
            let selectedRange = NSRange(location: locationDelta, length: length)
            selectedRanges.append(selectedRange)
            
            items.removeAll()
        })
        
        return (replacementItems, self.inSelection ? selectedRanges : nil)
    }
    
    
    
    // MARK: Private Methods
    
    private typealias EnumerationBlock = ((_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void)
    
    
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
    
    
    /// enumerate matchs in string using current settings
    private func enumerateMatchs(in ranges: [NSRange], using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        switch self.mode {
        case .textual:
            self.enumerateTextualMatchs(in: ranges, using: block, scopeCompletionHandler: scopeCompletionHandler)
            
        case .regularExpression:
            self.enumerateRegularExpressionMatchs(in: ranges, using: block, scopeCompletionHandler: scopeCompletionHandler)
        }
    }
    
    
    /// enumerate matchs in string using textual search
    private func enumerateTextualMatchs(in ranges: [NSRange], using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        guard !self.string.isEmpty else { return }
        
        guard case let .textual(options, fullWord) = self.mode else { return assertionFailure() }
        
        let string = self.string as NSString
        
        for scopeRange in ranges {
            var searchRange = scopeRange
            
            while searchRange.location != NSNotFound {
                searchRange.length = string.length - searchRange.location
                let foundRange = string.range(of: self.findString, options: options, range: searchRange)
                
                guard foundRange.upperBound <= scopeRange.upperBound else { break }
                
                searchRange.location = foundRange.upperBound
                
                guard !fullWord || self.isFullWord(range: foundRange) else { continue }
                
                var stop = false
                block(foundRange, nil, &stop)
                
                guard !stop else { return }
            }
            
            scopeCompletionHandler?(scopeRange)
        }
    }
    
    
    /// enumerate matchs in string using regular expression
    private func enumerateRegularExpressionMatchs(in ranges: [NSRange], using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        guard !self.string.isEmpty else { return }
        
        let string = self.string
        let regex = self.regex!
        let options: NSRegularExpression.MatchingOptions = [.withTransparentBounds, .withoutAnchoringBounds]
        var cancelled = false
        
        for scopeRange in ranges {
            guard !cancelled else { return }
            
            regex.enumerateMatches(in: string, options: options, range: scopeRange) { (result, flags, stop) in
                guard let result = result else { return }
                
                var ioStop = false
                block(result.range, result, &ioStop)
                if ioStop {
                    stop.pointee = ObjCBool(ioStop)
                    cancelled = true
                }
            }
            
            scopeCompletionHandler?(scopeRange)
        }
    }
    
}
