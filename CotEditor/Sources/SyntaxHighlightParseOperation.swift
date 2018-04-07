//
//  SyntaxHighlightParseOperation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2018 1024jp
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

struct BlockDelimiters: Equatable {
    
    let begin: String
    let end: String
    
    
    static func == (lhs: BlockDelimiters, rhs: BlockDelimiters) -> Bool {
        
        return lhs.begin == rhs.begin && lhs.end == rhs.end
    }
    
}



struct HighlightDefinition: Equatable {
    
    let beginString: String
    let endString: String?
    
    let isRegularExpression: Bool
    let ignoreCase: Bool
    
    
    // MARK: Lifecycle
    
    init?(definition: [String: Any]) {
        
        guard let beginString = definition[SyntaxDefinitionKey.beginString.rawValue] as? String else { return nil }
        
        self.beginString = beginString
        if let endString = definition[SyntaxDefinitionKey.endString.rawValue] as? String, !endString.isEmpty {
            self.endString = endString
        } else {
            self.endString = nil
        }
        self.isRegularExpression = (definition[SyntaxDefinitionKey.regularExpression.rawValue] as? Bool) ?? false
        self.ignoreCase = (definition[SyntaxDefinitionKey.ignoreCase.rawValue] as? Bool) ?? false
    }
    
    
    static func == (lhs: HighlightDefinition, rhs: HighlightDefinition) -> Bool {
        
        return lhs.beginString == rhs.beginString &&
            lhs.endString == rhs.endString &&
            lhs.isRegularExpression == rhs.isRegularExpression &&
            lhs.ignoreCase == rhs.ignoreCase
    }
    
}


extension HighlightDefinition {
    
    /// create a regex type definition from simple words by considering non-word characters around words
    init(words: [String], ignoreCase: Bool) {
        
        let escapedWords = words.sorted().reversed().map { NSRegularExpression.escapedPattern(for: $0) }  // reverse to precede longer word
        let rawBoundary = (words.joined() + "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_").unique
            .replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        let boundary = NSRegularExpression.escapedPattern(for: rawBoundary)
        let pattern = "(?<![" + boundary + "])" + "(?:" + escapedWords.joined(separator: "|") + ")" + "(?![" + boundary + "])"
        
        self.beginString = pattern
        self.endString = nil
        self.isRegularExpression = true
        self.ignoreCase = ignoreCase
    }
    
}



private struct QuoteCommentItem {
    
    let kind: String
    let role: Role
    let range: NSRange
    
    
    enum Kind {
        static let inlineComment = "inlineComment"
        static let blockComment = "blockComment"
    }
    
    
    struct Role: OptionSet {
        
        let rawValue: Int
        
        static let begin = Role(rawValue: 1 << 0)
        static let end   = Role(rawValue: 1 << 1)
    }
}



// MARK: -

final class SyntaxHighlightParseOperation: AsynchronousOperation, ProgressReporting {
    
    // MARK: Public Properties
    
    var string: String?
    var parseRange: NSRange = .notFound
    
    let progress: Progress
    var highlightBlock: (([SyntaxType: [NSRange]]) -> Void)?
    
    
    // MARK: Private Properties
    
    private let definitions: [SyntaxType: [HighlightDefinition]]
    private let pairedQuoteTypes: [String: SyntaxType]  // dict for quote pair to extract with comment
    private let inlineCommentDelimiter: String?
    private let blockCommentDelimiters: BlockDelimiters?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(definitions: [SyntaxType: [HighlightDefinition]], pairedQuoteTypes: [String: SyntaxType], inlineCommentDelimiter: String?, blockCommentDelimiters: BlockDelimiters?) {
        
        self.definitions = definitions
        self.pairedQuoteTypes = pairedQuoteTypes
        self.inlineCommentDelimiter = inlineCommentDelimiter
        self.blockCommentDelimiters = blockCommentDelimiters
        
        // +1 for extractCommentsWithQuotes()
        // +1 for highlighting
        self.progress = Progress(totalUnitCount: Int64(definitions.count + 2))
        
        super.init()
        
        self.progress.cancellationHandler = { [weak self] in
            self?.cancel()
        }
        
        self.queuePriority = .high
    }
    
    
    
    // MARK: Operation Methods
    
    /// is ready to run
    override var isReady: Bool {
        
        return self.string != nil && self.parseRange.location != NSNotFound
    }
    
    
    /// parse string in background and return extracted highlight ranges per syntax types
    override func main() {
        
        defer {
            self.finish()
        }
        
        let results = self.extractHighlights()
        
        guard !self.isCancelled else { return }
        
        DispatchQueue.main.async { [weak progress = self.progress] in
            progress?.localizedDescription = NSLocalizedString("Applying colors to text", comment: "")
        }
        
        self.highlightBlock?(results)
        
        DispatchQueue.main.async { [weak progress = self.progress] in
            progress?.completedUnitCount += 1
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// simply extract ranges of passed-in string
    private func ranges(string searchString: String, ignoreCase: Bool = false) -> [NSRange] {
        
        guard !searchString.isEmpty else { return [] }
        
        var ranges = [NSRange]()
        let string = self.string!
        let options: NSString.CompareOptions = ignoreCase ? [.literal, .caseInsensitive] : .literal
        
        var location = self.parseRange.location
        while location != NSNotFound {
            let range = (string as NSString).range(of: searchString, options: options,
                                                   range: NSRange(location: location,
                                                                  length: self.parseRange.upperBound - location))
            location = range.upperBound
            
            guard range.location != NSNotFound else { break }
            guard !string.isCharacterEscaped(at: range.location) else { continue }
            
            ranges.append(range)
        }
        
        return ranges
    }
    
    
    /// extract ranges with a begin/end string pair
    private func ranges(beginString: String, endString: String, ignoreCase: Bool) -> [NSRange] {
        
        guard !beginString.isEmpty else { return [] }
        
        var ranges = [NSRange]()
        let endLength = endString.utf16.count
        
        let scanner = Scanner(string: self.string!)
        scanner.charactersToBeSkipped = nil
        scanner.caseSensitive = !ignoreCase
        scanner.scanLocation = self.parseRange.location
        
        while !scanner.isAtEnd && (scanner.scanLocation < self.parseRange.upperBound) {
            guard !self.isCancelled else { return [] }
            
            scanner.scanUpTo(beginString, into: nil)
            let startLocation = scanner.scanLocation
            
            guard scanner.scanString(beginString, into: nil) else { break }
            guard !self.string!.isCharacterEscaped(at: startLocation) else { continue }
            
            // find end string
            while !scanner.isAtEnd && (scanner.scanLocation < self.parseRange.upperBound) {
                
                scanner.scanUpTo(endString, into: nil)
                guard scanner.scanString(endString, into: nil) else { break }
                
                let endLocation = scanner.scanLocation
                
                guard !self.string!.isCharacterEscaped(at: endLocation - endLength) else { continue }
                
                let range = NSRange(location: startLocation, length: endLocation - startLocation)
                ranges.append(range)
                
                break
            }
        }
        
        return ranges
    }
    
    
    /// extract ranges with regular expression
    private func ranges(regularExpressionString regexString: String, ignoreCase: Bool) -> [NSRange] {
        
        guard !regexString.isEmpty else { return [] }
        
        var options: NSRegularExpression.Options = .anchorsMatchLines
        if ignoreCase {
            options.update(with: .caseInsensitive)
        }
        
        let regex: NSRegularExpression
        do {
            try regex = NSRegularExpression(pattern: regexString, options: options)
        } catch {
            print("Regex Syntax Error in " + #function + ": ", error)
            return []
        }
        
        var ranges = [NSRange]()
        
        regex.enumerateMatches(in: self.string!, options: [.withTransparentBounds, .withoutAnchoringBounds], range: parseRange)
        { (result: NSTextCheckingResult?, flags, stop) in
            guard !self.isCancelled else {
                stop.pointee = true
                return
            }
            
            guard let range = result?.range else { return }
            
            ranges.append(range)
        }
        
        return ranges
    }
    
    
    /// extract ranges with pair of begin/end regular expressions
    private func ranges(regularExpressionBeginString beginString: String, endString: String, ignoreCase: Bool) -> [NSRange] {
        
        guard !beginString.isEmpty else { return [] }
        
        var options: NSRegularExpression.Options = .anchorsMatchLines
        if ignoreCase {
            options.update(with: .caseInsensitive)
        }
        
        let beginRegex: NSRegularExpression
        let endRegex: NSRegularExpression
        do {
            try beginRegex = NSRegularExpression(pattern: beginString, options: options)
            try endRegex = NSRegularExpression(pattern: endString, options: options)
        } catch {
            print("Regex Syntax Error in " + #function + ": ", error)
            return []
        }
        
        var ranges = [NSRange]()
        let string = self.string!
        let parseRange = self.parseRange
        
        beginRegex.enumerateMatches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: parseRange)
        { (result: NSTextCheckingResult?, flags, stop) in
            guard !self.isCancelled else {
                stop.pointee = true
                return
            }
            
            guard let beginRange = result?.range else { return }
            
            let endRange = endRegex.rangeOfFirstMatch(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds],
                                                      range: NSRange(location: beginRange.upperBound,
                                                                     length: parseRange.upperBound - beginRange.upperBound))
            
            if endRange.location != NSNotFound {
                ranges.append(beginRange.union(endRange))
            }
        }
        
        return ranges
    }
    
    
    /// extract ranges of quoted texts as well as comments in the parse range
    private func extractCommentsWithQuotes() -> [SyntaxType: [NSRange]] {
        
        var positions = [QuoteCommentItem]()
        
        if let delimiters = self.blockCommentDelimiters {
            for range in self.ranges(string: delimiters.begin) {
                positions.append(QuoteCommentItem(kind: QuoteCommentItem.Kind.blockComment, role: .begin, range: range))
            }
            for range in self.ranges(string: delimiters.end) {
                positions.append(QuoteCommentItem(kind: QuoteCommentItem.Kind.blockComment, role: .end, range: range))
            }
        }
        
        if let delimiter = self.inlineCommentDelimiter {
            for range in self.ranges(string: delimiter) {
                let lineRange = (self.string! as NSString).lineRange(for: range)
                let endRange = NSRange(location: lineRange.upperBound, length: 0)
                
                positions.append(QuoteCommentItem(kind: QuoteCommentItem.Kind.inlineComment, role: .begin, range: range))
                positions.append(QuoteCommentItem(kind: QuoteCommentItem.Kind.inlineComment, role: .end, range: endRange))
            }
        }
        
        for quote in self.pairedQuoteTypes.keys {
            for range in self.ranges(string: quote) {
                positions.append(QuoteCommentItem(kind: quote, role: [.begin, .end], range: range))
            }
        }
        
        guard !positions.isEmpty else { return [:] }
        
        // sort by location
        positions.sort {
            if $0.range.location < $1.range.location { return true }
            if $0.range.location > $1.range.location { return false }
            
            if $0.range.length == 0 { return true }
            if $1.range.length == 0 { return false }
            
            if $0.role.rawValue == $1.role.rawValue {
                return $0.range.length > $1.range.length
            }
            return $0.role.rawValue > $1.role.rawValue
        }
        
        // scan quoted strings and comments in the parse range
        var highlights = [SyntaxType: [NSRange]]()
        var seekLocation = self.parseRange.location
        var startLocation = 0
        var searchingKind: String?
        
        for position in positions {
            // search next begin delimiter
            guard let kind = searchingKind else {
                if position.role.contains(.begin), position.range.location >= seekLocation {
                    searchingKind = position.kind
                    startLocation = position.range.location
                }
                continue
            }
            
            // search corresponding end delimiter
            if position.role.contains(.end), position.kind == kind {
                let endLocation = position.range.upperBound
                let syntaxType = self.pairedQuoteTypes[kind] ?? SyntaxType.comments
                let range = NSRange(location: startLocation, length: endLocation - startLocation)
                
                highlights[syntaxType, default: []].append(range)
                
                searchingKind = nil
                seekLocation = endLocation
            }
        }
        
        // highlight until the end if not closed
        if let searchingKind = searchingKind, startLocation < self.parseRange.upperBound {
            let syntaxType = self.pairedQuoteTypes[searchingKind] ?? SyntaxType.comments
            let range = NSRange(location: startLocation, length: self.parseRange.upperBound - startLocation)
            
            highlights[syntaxType, default: []].append(range)
        }
        
        return highlights
    }
    
    
    /// extract all highlight ranges in the parse range
    private func extractHighlights() -> [SyntaxType: [NSRange]] {
        
        var highlights = [SyntaxType: [NSRange]]()
        
        for syntaxType in SyntaxType.all {
            guard let definitions = self.definitions[syntaxType] else { continue }
            
            // update indicator sheet message
            DispatchQueue.main.async { [weak progress = self.progress] in
                progress?.localizedDescription = String(format: NSLocalizedString("Extracting %@…", comment: ""), syntaxType.localizedName)
            }
            
            let childProgress = Progress(totalUnitCount: Int64(definitions.count), parent: self.progress, pendingUnitCount: 1)
            
            var ranges = [NSRange]()
            let rangesQueue = DispatchQueue(label: "com.coteditor.CotEdiotor.syntax.ranges." + syntaxType.rawValue)
            
            DispatchQueue.concurrentPerform(iterations: definitions.count) { (index: Int) in
                guard !self.isCancelled else { return }
                
                let extractedRanges: [NSRange] = {
                    let definition = definitions[index]
                    
                    if definition.isRegularExpression {
                        if let endString = definition.endString {
                            return self.ranges(regularExpressionBeginString: definition.beginString,
                                               endString: endString,
                                               ignoreCase: definition.ignoreCase)
                        } else {
                            return self.ranges(regularExpressionString: definition.beginString,
                                               ignoreCase: definition.ignoreCase)
                        }
                        
                    } else {
                        if let endString = definition.endString {
                            return self.ranges(beginString: definition.beginString,
                                               endString: endString,
                                               ignoreCase: definition.ignoreCase)
                        } else {
                            assertionFailure("non-regex words should be preprocessed at SyntaxStyle.init()")
                            return self.ranges(string: definition.beginString,
                                               ignoreCase: definition.ignoreCase)
                        }
                    }
                }()
                
                if !extractedRanges.isEmpty {
                    rangesQueue.sync {
                        ranges += extractedRanges
                    }
                }
                
                // progress indicator
                DispatchQueue.main.async { [weak childProgress] in
                    childProgress?.completedUnitCount += 1
                }
            }
            
            guard !self.isCancelled else { return [:] }
            
            // store range array
            highlights[syntaxType] = ranges
            
            // progress indicator
            DispatchQueue.main.async { [weak childProgress] in
                guard let childProgress = childProgress else { return }
                childProgress.completedUnitCount = childProgress.totalUnitCount
            }
        }
        
        guard !self.isCancelled else { return [:] }
        
        // comments and quoted text
        DispatchQueue.main.async { [weak progress = self.progress] in
            progress?.localizedDescription = String(format: NSLocalizedString("Extracting %@…", comment: ""),
                                                    NSLocalizedString("comments and quoted texts", comment: ""))
        }
        let commentAndQuoteRanges = self.extractCommentsWithQuotes()
        for (key, value) in commentAndQuoteRanges {
            highlights[key, default: []].append(contentsOf: value)
        }
        
        guard !self.isCancelled else { return [:] }
        
        let sanitized = sanitize(highlights: highlights)
        
        DispatchQueue.main.async { [weak progress = self.progress] in
            progress?.completedUnitCount += 1
        }
        
        return sanitized
    }
    
}



// MARK: Private Functions

private extension String {
    
    /// String consists with unique characters in the receiver.
    var unique: String {
        
        return String(Set(self).sorted())
    }
    
}


/** Remove duplicated coloring ranges.
 
 This sanitization will reduce performance time of `applyHighlights:highlights:layoutManager:` significantly.
 Adding temporary attribute to a layoutManager is quite sluggish,
 so we want to remove useless highlighting ranges as many as possible beforehand.
 */
private func sanitize(highlights: [SyntaxType: [NSRange]]) -> [SyntaxType: [NSRange]] {
    
    var sanitizedHighlights = [SyntaxType: [NSRange]]()
    let highlightedIndexes = NSMutableIndexSet()
    
    for type in SyntaxType.all.reversed() {
        guard let ranges = highlights[type] else { continue }
        var sanitizedRanges = [NSRange]()
        
        for range in ranges {
            if !highlightedIndexes.contains(in: range) {
                sanitizedRanges.append(range)
                highlightedIndexes.add(in: range)
            }
        }
        
        if !sanitizedRanges.isEmpty {
            sanitizedHighlights[type] = sanitizedRanges
        }
    }
    
    return sanitizedHighlights
}
