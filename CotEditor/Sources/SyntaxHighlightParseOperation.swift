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
    
    private let extractors: [SyntaxType: [HighlightExtractable]]
    private let pairedQuoteTypes: [String: SyntaxType]  // dict for quote pair to extract with comment
    private let inlineCommentDelimiter: String?
    private let blockCommentDelimiters: Pair<String>?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(extractors: [SyntaxType: [HighlightExtractable]], pairedQuoteTypes: [String: SyntaxType], inlineCommentDelimiter: String?, blockCommentDelimiters: Pair<String>?) {
        
        self.extractors = extractors
        self.pairedQuoteTypes = pairedQuoteTypes
        self.inlineCommentDelimiter = inlineCommentDelimiter
        self.blockCommentDelimiters = blockCommentDelimiters
        
        // +1 for extractCommentsWithQuotes()
        // +1 for highlighting
        self.progress = Progress(totalUnitCount: Int64(extractors.count + 2))
        
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
                                                   range: NSRange(location..<self.parseRange.upperBound))
            location = range.upperBound
            
            guard range.location != NSNotFound else { break }
            guard !string.isCharacterEscaped(at: range.location) else { continue }
            
            ranges.append(range)
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
                let range = NSRange(startLocation..<endLocation)
                
                highlights[syntaxType, default: []].append(range)
                
                searchingKind = nil
                seekLocation = endLocation
            }
        }
        
        // highlight until the end if not closed
        if let searchingKind = searchingKind, startLocation < self.parseRange.upperBound {
            let syntaxType = self.pairedQuoteTypes[searchingKind] ?? SyntaxType.comments
            let range = NSRange(startLocation..<self.parseRange.upperBound)
            
            highlights[syntaxType, default: []].append(range)
        }
        
        return highlights
    }
    
    
    /// extract all highlight ranges in the parse range
    private func extractHighlights() -> [SyntaxType: [NSRange]] {
        
        var highlights = [SyntaxType: [NSRange]]()
        
        for syntaxType in SyntaxType.all {
            guard let extractors = self.extractors[syntaxType] else { continue }
            
            // update indicator sheet message
            DispatchQueue.main.async { [weak progress = self.progress] in
                progress?.localizedDescription = String(format: NSLocalizedString("Extracting %@…", comment: ""), syntaxType.localizedName)
            }
            
            let childProgress = Progress(totalUnitCount: Int64(extractors.count), parent: self.progress, pendingUnitCount: 1)
            
            var ranges = [NSRange]()
            let rangesQueue = DispatchQueue(label: "com.coteditor.CotEdiotor.syntax.ranges." + syntaxType.rawValue)
            
            DispatchQueue.concurrentPerform(iterations: extractors.count) { (index: Int) in
                guard !self.isCancelled else { return }
                
                let extractedRanges = extractors[index].ranges(in: self.string!, range: self.parseRange)
                
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
