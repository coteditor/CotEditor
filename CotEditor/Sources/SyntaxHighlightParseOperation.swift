/*
 
 SyntaxHighlightParseOperation.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-06.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

struct BlockDelimiters: Equatable, CustomDebugStringConvertible {
    
    let begin: String
    let end: String
    
    
    var debugDescription: String {
        
        return "<\(BlockDelimiters.self) begin: \(self.begin)  end: \(self.end)>"
    }
    

    static func ==(lhs: BlockDelimiters, rhs: BlockDelimiters) -> Bool {
        
        return lhs.begin == rhs.begin && lhs.end == rhs.end
    }
    
}



struct HighlightDefinition: Equatable, CustomDebugStringConvertible {
    
    let beginString: String
    let endString: String?
    
    let isRegularExpression: Bool
    let ignoreCase: Bool
    
    
    // MARK: Lifecycle
    
    init?(definition: [String: AnyObject]) {
        
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
    
    
    var debugDescription: String {
        
        return "<\(HighlightDefinition.self) begin: \(self.beginString)  end: \(self.endString)>"
    }
    
    
    static func ==(lhs: HighlightDefinition, rhs: HighlightDefinition) -> Bool {
        
        return lhs.beginString == rhs.beginString &&
            lhs.endString == rhs.endString &&
            lhs.isRegularExpression == rhs.isRegularExpression &&
            lhs.ignoreCase == rhs.ignoreCase
    }
    
}



private struct QuoteCommentItem {
    
    let location: Int
    let length: Int
    let kind: String
    let role: Role
    
    
    enum Kind {
        static let inlineComment = "inlineComment"
        static let blockComment = "blockComment"
    }
    
    
    enum Role: Int {
        case end
        case both
        case start
    }
}



// MARK:

final class SyntaxHighlightParseOperation: Operation {
    
    // MARK: Public Properties
    
    var string: String?
    var parseRange: NSRange = .notFound
    
    let progress: Progress
    private(set) var results = [SyntaxType: [NSRange]]()
    
    
    // MARK: Private Properties
    
    private let definitions: [SyntaxType: [HighlightDefinition]]
    private let simpleWordsCharacterSets: [SyntaxType: CharacterSet]?
    private let pairedQuoteTypes: [String: SyntaxType]?  // dict for quote pair to extract with comment
    private let inlineCommentDelimiter: String?
    private let blockCommentDelimiters: BlockDelimiters?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init(definitions: [SyntaxType: [HighlightDefinition]], simpleWordsCharacterSets: [SyntaxType: CharacterSet]?, pairedQuoteTypes: [String: SyntaxType]?, inlineCommentDelimiter: String?, blockCommentDelimiters: BlockDelimiters?) {
        
        self.definitions = definitions
        self.simpleWordsCharacterSets = simpleWordsCharacterSets
        self.pairedQuoteTypes = pairedQuoteTypes
        self.inlineCommentDelimiter = inlineCommentDelimiter
        self.blockCommentDelimiters = blockCommentDelimiters
        
        self.progress = Progress(totalUnitCount: Int64(definitions.count))
        
        super.init()
        
        self.progress.cancellationHandler = { [weak self] in
            self?.cancel()
        }
        
        self.queuePriority = .high
    }
    
    
    
    // MARK: Operation Methods
    
    /// runs asynchronous
    override var isAsynchronous: Bool {
        
        return true
    }
    
    
    /// is ready to run
    override var isReady: Bool {
        
        return self.string != nil && self.parseRange.location != NSNotFound
    }
    
    
    /// parse string in background and return extracted highlight ranges per syntax types
    override func main() {
        
        self.results = self.extractHighlights()
    }
    
    
    
    // MARK: Private Methods
    
    /// extract ranges of passed-in words with Scanner by considering non-word characters around words
    private func ranges(simpleWords wordsDict: [Int: [String]], ignoreCaseWords: [Int: [String]], charSet: CharacterSet) -> [NSRange] {
        
        var ranges = [NSRange]()
        
        let scanner = Scanner(string: self.string!)
        scanner.caseSensitive = true
        scanner.scanLocation = self.parseRange.location
        
        while !scanner.isAtEnd && scanner.scanLocation < self.parseRange.max {
            guard !self.isCancelled else { return [] }
            
            var scanningString: NSString?
            scanner.scanUpToCharacters(from: charSet, into: nil)
            guard
                scanner.scanCharacters(from: charSet, into: &scanningString),
                let scannedString = scanningString as? String else { break }
            
            let length = scannedString.utf16.count
            var words: [String] = wordsDict[length] ?? []
            var isFound = words.contains(scannedString)
            
            if !isFound {
                words = ignoreCaseWords[length] ?? []
                isFound = words.contains(scannedString.lowercased())
            }
            
            if isFound {
                let location = scanner.scanLocation
                let range = NSRange(location: location - length, length: length)
                ranges.append(range)
            }
        }
        
        return ranges
    }
    
    
    /// simply extract ranges of passed-in string
    private func ranges(string searchString: String) -> [NSRange] {
        
        guard !searchString.isEmpty else { return [] }
        
        var ranges = [NSRange]()
        let string = self.string!
        
        var location = self.parseRange.location
        while location != NSNotFound {
            let range = (string as NSString).range(of: searchString,
                                                   options: .literal,
                                                   range: NSRange(location: location,
                                                                  length: self.parseRange.max - location))
            location = range.max
            
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
        
        while !scanner.isAtEnd && (scanner.scanLocation < self.parseRange.max) {
            guard !self.isCancelled else { return [] }
            
            scanner.scanUpTo(beginString, into: nil)
            let startLocation = scanner.scanLocation
            
            guard scanner.scanString(beginString, into: nil) else { break }
            guard !self.string!.isCharacterEscaped(at: startLocation) else { continue }
            
            // find end string
            while !scanner.isAtEnd && (scanner.scanLocation < self.parseRange.max) {
                
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
        } catch let error {
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
        } catch let error {
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
                                                      range: NSRange(location: beginRange.max,
                                                                     length: parseRange.max - beginRange.max))
            
            if endRange.location != NSNotFound {
                ranges.append(NSUnionRange(beginRange, endRange))
            }
        }
        
        return ranges
    }
    
    
    /// extract ranges of quoted texts as well as comments in the parse range
    private func extractCommentsWithQuotes() -> [SyntaxType: [NSRange]] {
        
        var positions = [QuoteCommentItem]()
        
        if let delimiters = self.blockCommentDelimiters {
            let beginRanges = self.ranges(string: delimiters.begin)
            let beginLength = delimiters.begin.utf16.count
            for range in beginRanges {
                positions.append(QuoteCommentItem(location: range.location,
                                                  length: beginLength,
                                                  kind: QuoteCommentItem.Kind.blockComment,
                                                  role: .start))
            }
            
            let endRanges = self.ranges(string: delimiters.end)
            let endLength = delimiters.end.utf16.count
            for range in endRanges {
                positions.append(QuoteCommentItem(location: range.location,
                                                  length: endLength,
                                                  kind: QuoteCommentItem.Kind.blockComment,
                                                  role: .end))
            }
        }
        
        if let delimiter = self.inlineCommentDelimiter {
            let string = self.string!
            let ranges = self.ranges(string: delimiter)
            let length = delimiter.utf16.count
            for range in ranges {
                let lineRange = (string as NSString).lineRange(for: range)
                
                positions.append(QuoteCommentItem(location: range.location,
                                                  length: length,
                                                  kind: QuoteCommentItem.Kind.inlineComment,
                                                  role: .start))
                positions.append(QuoteCommentItem(location: lineRange.max - length,
                                                  length: length,
                                                  kind: QuoteCommentItem.Kind.inlineComment,
                                                  role: .end))
            }
        }
        
        // create quote definitions if exists
        if let quoteTypes = self.pairedQuoteTypes {
            for quote in quoteTypes.keys {
                let ranges = self.ranges(string: quote)
                let length = quote.utf16.count
                for range in ranges {
                    positions.append(QuoteCommentItem(location: range.location,
                                                      length: length,
                                                      kind: quote,
                                                      role: .both))
                }
            }
        }
        
        guard !positions.isEmpty else { return [:] }
        
        // sort by location  // ???: performance critial
        positions.sort {
            if $0.location == $1.location {
                return $0.role.rawValue < $1.role.rawValue
            }
            return $0.location < $1.location
        }
        
        // scan quoted strings and comments in the parse range
        var highlights = [SyntaxType: [NSRange]]()
        var startLocation = 0
        var seekLocation = parseRange.location
        var searchingPairKind: String?
        var isContinued = false
        
        for position in positions {
            // search next begin delimiter
            guard let kind = searchingPairKind else {
                if position.role != .end && position.location >= seekLocation {
                    searchingPairKind = position.kind
                    startLocation = position.location
                }
                continue
            }
            
            // search corresponding end delimiter
            if position.kind == kind && (position.role == .both || position.role == .end) {
                let endLocation = position.location + position.length
                let syntaxType = self.pairedQuoteTypes?[kind] ?? SyntaxType.comments
                let range = NSRange(location: startLocation, length: endLocation - startLocation)
                
                if highlights[syntaxType] != nil {
                    highlights[syntaxType]!.append(range)
                } else {
                    highlights[syntaxType] = [range]
                }
                
                searchingPairKind = nil
                seekLocation = endLocation
                continue
            }
            
            if startLocation < parseRange.max {
                isContinued = true
            }
        }
        
        // highlight until the end if not closed
        if let searchingPairKind = searchingPairKind, isContinued {
            let syntaxType = self.pairedQuoteTypes?[searchingPairKind] ?? SyntaxType.comments
            let range = NSRange(location: startLocation, length: parseRange.max - startLocation)
            
            if highlights[syntaxType] != nil {
                highlights[syntaxType]!.append(range)
            } else {
                highlights[syntaxType] = [range]
            }
        }
        
        return highlights
    }
    
    
    /// extract all highlight ranges in the parse range
    private func extractHighlights() -> [SyntaxType: [NSRange]] {
        
        var highlights = [SyntaxType: [NSRange]]()
        let totalProgress = self.progress
        
        for syntaxType in SyntaxType.all {
            // update indicator sheet message
            totalProgress.becomeCurrent(withPendingUnitCount: 1)
            DispatchQueue.main.async {
                totalProgress.localizedDescription = String(format: NSLocalizedString("Extracting %@…", comment: ""), syntaxType.localizedName)
            }
            
            guard let definitions = self.definitions[syntaxType] else {
                totalProgress.resignCurrent()
                continue
            }
            
            let childProgress = Progress(totalUnitCount: definitions.count + 10)  // + 10 for simple words
            
            var simpleWordsDict = [Int: [String]]()
            var simpleICWordsDict = [Int: [String]]()
            let wordsQueue = DispatchQueue(label: "com.coteditor.CotEdiotor.syntax.words")
            
            var ranges = [NSRange]()
            let rangesQueue = DispatchQueue(label: "com.coteditor.CotEdiotor.syntax.ranges")
            
            DispatchQueue.concurrentPerform(iterations: definitions.count, execute: { (i: Int) in
                guard !self.isCancelled else { return }
                
                let definition = definitions[i]
                var extractedRanges: [NSRange]?
                
                autoreleasepool {
                    if definition.isRegularExpression {
                        if let endString = definition.endString, !endString.isEmpty {
                            extractedRanges = self.ranges(regularExpressionBeginString: definition.beginString,
                                                          endString: endString,
                                                          ignoreCase: definition.ignoreCase)
                        } else {
                            extractedRanges = self.ranges(regularExpressionString: definition.beginString,
                                                          ignoreCase: definition.ignoreCase)
                        }
                        
                    } else {
                        if let endString = definition.endString, !endString.isEmpty {
                            extractedRanges = self.ranges(beginString: definition.beginString,
                                                          endString: endString,
                                                          ignoreCase: definition.ignoreCase)
                        } else {
                            let len = definition.beginString.utf16.count
                            let word = definition.ignoreCase ? definition.beginString.lowercased() : definition.beginString
                            
                            wordsQueue.sync {
                                if definition.ignoreCase {
                                    if simpleICWordsDict[len] != nil {
                                        simpleICWordsDict[len]!.append(word)
                                    } else {
                                        simpleICWordsDict[len] = [word]
                                    }
                                    
                                } else {
                                    if simpleWordsDict[len] != nil {
                                        simpleWordsDict[len]!.append(word)
                                    } else {
                                        simpleWordsDict[len] = [word]
                                    }
                                }
                            }
                        }
                    }
                    
                    if let extractedRanges = extractedRanges {
                        rangesQueue.sync {
                            ranges.append(contentsOf: extractedRanges)
                        }
                    }
                }
                
                // progress indicator
                DispatchQueue.main.async {
                    childProgress.completedUnitCount += 1
                }
                })
            
            guard !self.isCancelled else { return [:] }
            
            // extract simple words
            if !simpleWordsDict.isEmpty || !simpleICWordsDict.isEmpty {
                let extractedRanges = self.ranges(simpleWords: simpleWordsDict,
                                                  ignoreCaseWords: simpleICWordsDict,
                                                  charSet: self.simpleWordsCharacterSets![syntaxType]!)
                ranges.append(contentsOf: extractedRanges)
            }
            
            // store range array
            highlights[syntaxType] = ranges
            
            // progress indicator
            childProgress.completedUnitCount = childProgress.totalUnitCount
            totalProgress.resignCurrent()
        }  // end-for (syntaxType)
        
        guard !self.isCancelled else { return [:] }
        
        // comments and quoted text
        DispatchQueue.main.async {
            totalProgress.localizedDescription = String(format: NSLocalizedString("Extracting %@…", comment: ""),
                                                        NSLocalizedString("comments and quoted texts", comment: ""))
        }
        let commentAndQuoteRanges = self.extractCommentsWithQuotes()
        for (key, value) in commentAndQuoteRanges {
            if highlights[key] != nil {
                highlights[key]!.append(contentsOf: value)
            } else {
                highlights[key] = value
            }
        }
        
        guard !self.isCancelled else { return [:] }
        
        let sanitized = sanitize(highlights: highlights)
        
        totalProgress.completedUnitCount += 1  // = total - 1
        
        return sanitized
    }
    
}



// MARK: Private Functions

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
