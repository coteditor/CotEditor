/*
 
 TextFind.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-02.
 
 ------------------------------------------------------------------------------
 
 © 2015-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

struct ReplacementItem {
    
    let string: String
    let range: NSRange
}



final class TextFind {
    
    struct Settings {
        
        let usesRegularExpression: Bool
        let isWrap: Bool
        let inSelection: Bool
        let textualOptions: NSString.CompareOptions  // don't include .backwards
        let regexOptions: NSRegularExpression.Options
        let unescapesReplacementString: Bool
    }
    
    
    
    // MARK: Public Properties
    
    let settings: TextFind.Settings
    let findString: String
    let string: String
    let selectedRanges: [NSRange]
    
    
    // MARK: Private Properties
    
    private let regex: NSRegularExpression?
    private let scopeRanges: [NSRange]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Return an initialized TextFind instance with the specified options.
    ///
    /// - Parameters:
    ///   - string: The string to search.
    ///   - findString: The string for which to search.
    ///   - settings: The settable options for the text search.
    ///   - selectedRanges: selected ranges in the text view.
    /// - Throws: TextFindError
    init(for string: String, findString: String, settings: TextFind.Settings, selectedRanges: [NSRange] = [NSRange()]) throws {
        
        assert(!selectedRanges.isEmpty)
        assert(!settings.textualOptions.contains(.backwards))
        
        guard !findString.isEmpty else {
            throw TextFindError.emptyFindString
        }
        
        if settings.usesRegularExpression {
            do {
                self.regex = try NSRegularExpression(pattern: findString, options: settings.regexOptions)
            } catch {
                let failureReason: String? = (error as? LocalizedError)?.failureReason
                throw TextFindError.regularExpression(reason: failureReason)
            }
        } else {
            self.regex = nil
        }
        
        self.settings = settings
        self.string = string
        self.selectedRanges = selectedRanges
        self.findString = findString
        self.scopeRanges = settings.inSelection ? selectedRanges : [string.nsRange]
    }
    
    
    
    // MARK: Public Methods
    
    /// the number of capture groups in the regular expression.
    var numberOfCaptureGroups: Int {
        
        return self.regex?.numberOfCaptureGroups ?? 0
    }
    
    
    /// find single match from the first selection.
    func find(forward: Bool) -> (range: NSRange?, count: Int, wrapped: Bool) {
        
        let selectedRange = self.selectedRanges.first!
        let startLocation = forward ? selectedRange.max : selectedRange.location
        
        var forwardMatches = [NSRange]()  // matches after the start location
        let forwardRange = NSRange(location: startLocation, length: string.utf16.count - startLocation)
        self.enumerateMatchs(in: [forwardRange], using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            forwardMatches.append(matchedRange)
        })
        
        var wrappedMatches = [NSRange]()  // matches before the start location
        var intersectionMatches = [NSRange]()  // matches including the start location
        self.enumerateMatchs(in: [string.nsRange], using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            if matchedRange.location >= startLocation {
                stop = true
                return
            }
            if matchedRange.contains(location: startLocation) {
                intersectionMatches.append(matchedRange)
            } else {
                wrappedMatches.append(matchedRange)
            }
        })
        
        var foundRange: NSRange? = forward ? forwardMatches.first : wrappedMatches.last
        
        // wrap search
        let isWrapped = (foundRange == nil && self.settings.isWrap)
        if isWrapped {
            foundRange = forward ? (wrappedMatches + intersectionMatches).first : (intersectionMatches + forwardMatches).last
        }
        
        let count = forwardMatches.count + wrappedMatches.count + intersectionMatches.count
        
        return (foundRange, count, isWrapped)
    }
    
    
    /// replace matched string in selection with replacementStirng
    func replace(with replacementString: String) -> ReplacementItem? {
        
        let string = self.string
        let selectedRange = self.selectedRanges.first!
        
        if self.settings.usesRegularExpression {
            let regex = self.regex!
            guard let match = regex.firstMatch(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: selectedRange) else { return nil }
            
            let template = self.replacementString(from: replacementString)
            
            let replacedString = regex.replacementString(for: match, in: string, offset: 0, template: template)
            
            return ReplacementItem(string: replacedString, range: match.range)
            
        } else {
            let matchedRange = (string as NSString).range(of: self.findString, options: self.settings.textualOptions, range: selectedRange)
            guard matchedRange.location != NSNotFound else { return nil }
            
            return ReplacementItem(string: replacementString, range: matchedRange)
        }
    }
    
    
    ///
    func findAll(using block: (_ matches: [NSRange], _ stop: inout Bool) -> Void) {
        
        let numberOfGroups = self.numberOfCaptureGroups
        
        self.enumerateMatchs(in: self.scopeRanges, using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            
            var matches = [NSRange]()
            
            matches.append(matchedRange)
            
            if numberOfGroups > 0, let regexMatch = match {
                for index in 1...numberOfGroups {
                    matches.append(regexMatch.rangeAt(index))
                }
            }
            
            block(matches, &stop)
        })
    }
    
    
    ///
    func replaceAll(with replacementString: String, using block: (_ stop: inout Bool) -> Void) -> (replacementItems: [ReplacementItem], selectedRanges: [NSRange]?) {
        
        let replacementString = self.replacementString(from: replacementString)
        var replacementItems = [ReplacementItem]()
        var selectedRanges = [NSRange]()
        
        // variables to calculate new selection ranges
        var locationDelta = 1
        var lengthDelta = 0
        
        self.enumerateMatchs(in: self.scopeRanges, using: { (matchedRange: NSRange, match: NSTextCheckingResult?, stop) in
            
            let replacedString: String = {
                guard let match = match, let regex = match.regularExpression else { return replacementString }
                
                return regex.replacementString(for: match, in: self.string, offset: 0, template: replacementString)
            }()
            
            replacementItems.append(ReplacementItem(string: replacedString, range: matchedRange))
            
            lengthDelta -= matchedRange.length - replacementString.utf16.count
            
            block(&stop)
            
        }, scopeCompletionHandler: { (scopeRange: NSRange) in
            let selectedRange = NSRange(location: scopeRange.location + locationDelta,
                                        length: scopeRange.length + lengthDelta)
            locationDelta += selectedRange.length - scopeRange.length
            lengthDelta = 0
            selectedRanges.append(selectedRange)
        })
        
        return (replacementItems, self.settings.inSelection ? selectedRanges : nil)
    }
    
    
    
    // MARK: Private Methods
    
    private typealias EnumerationBlock = ((_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void)
    
    
    /// unescape given string for replacement string only if needed
    private func replacementString(from string: String) -> String {
        
        guard self.settings.usesRegularExpression && self.settings.unescapesReplacementString else {
            return string
        }
        
        return string.unescaped
    }
    
    
    /// enumerate matchs in string using current settings
    private func enumerateMatchs(in ranges: [NSRange], using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        if self.settings.usesRegularExpression {
            self.enumerateRegularExpressionMatchs(in: ranges, using: block, scopeCompletionHandler: scopeCompletionHandler)
        } else {
            self.enumerateTextualMatchs(in: ranges, using: block, scopeCompletionHandler: scopeCompletionHandler)
        }
    }
    
    
    /// enumerate matchs in string using textual search
    private func enumerateTextualMatchs(in ranges: [NSRange], using block: (_ matchedRange: NSRange, _ match: NSTextCheckingResult?, _ stop: inout Bool) -> Void, scopeCompletionHandler: ((NSRange) -> Void)? = nil) {
        
        guard !self.string.isEmpty else { return }
        
        let string = self.string as NSString
        
        for scopeRange in ranges {
            var searchRange = scopeRange
            
            while searchRange.location != NSNotFound {
                searchRange.length = string.length - searchRange.location
                let foundRange = string.range(of: self.findString, options: self.settings.textualOptions, range: searchRange)
                
                guard foundRange.max <= scopeRange.max else { break }
                
                var stop = false
                block(foundRange, nil, &stop)
                
                guard !stop else { return }
                
                searchRange.location = foundRange.max
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



// MARK: - Error

enum TextFindError: LocalizedError {
    
    case regularExpression(reason: String?)
    case emptyFindString
    
    
    var errorDescription: String? {
        
        switch self {
        case .regularExpression:
            return NSLocalizedString("Invalid regular expression", comment: "")
        case .emptyFindString:
            return nil
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self {
        case .regularExpression(let reason):
            return reason
        case .emptyFindString:
            return nil
        }
    }
    
}
