//
//  HighlightParser.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2022 1024jp
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
    
    let type: SyntaxType
    let token: Token
    let role: Role
    let range: NSRange
    
    
    enum Token: Equatable {
        
        case inlineComment
        case blockComment
        case string(String)
    }
    
    
    struct Role: OptionSet {
        
        let rawValue: Int
        
        static let begin = Role(rawValue: 1 << 0)
        static let end   = Role(rawValue: 1 << 1)
    }
}



// MARK: -

final class HighlightParser {
    
    struct Definition {
        
        var extractors: [SyntaxType: [HighlightExtractable]]
        var pairedQuoteTypes: [String: SyntaxType]  // dict for quote pair to extract with comment
        var inlineCommentDelimiter: String?
        var blockCommentDelimiters: Pair<String>?
    }
    
    
    
    // MARK: Public Properties
    
    let progress: Progress  // can be updated from a background thread
    
    
    // MARK: Private Properties
    
    private let definition: Definition
    private let string: String
    private let parseRange: NSRange
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(definition: Definition, string: String, range parseRange: NSRange) {
        
        self.definition = definition
        self.string = string
        self.parseRange = parseRange
        
        // +2 for extractCommentsWithQuotes(), sanitizing
        self.progress = Progress(totalUnitCount: Int64(definition.extractors.count + 2))
    }
    
    
    // MARK: Public Methods
    
    /// extract all highlight ranges in the parse range
    func parse() async throws -> [SyntaxType: [NSRange]] {
        
        let string = self.string
        let parseRange = self.parseRange
        var highlights = [SyntaxType: [NSRange]]()
        
        // extract standard highlight rangess
        for syntaxType in SyntaxType.allCases {
            guard let extractors = self.definition.extractors[syntaxType] else { continue }
            
            self.progress.localizedDescription = String(format: "Extracting %@…".localized, syntaxType.localizedName)
            let childProgress = Progress(totalUnitCount: Int64(extractors.count), parent: self.progress, pendingUnitCount: 1)
            
            highlights[syntaxType] = try await withThrowingTaskGroup(of: [NSRange].self) { group in
                for extractor in extractors {
                    group.addTask { try extractor.ranges(in: string, range: parseRange) }
                }
                
                var ranges: [NSRange] = []
                for try await extractedRanges in group {
                    ranges += extractedRanges
                    childProgress.completedUnitCount += 1
                }
                return ranges
            }
        }
        
        guard !self.progress.isCancelled else { throw CancellationError() }
        
        // extract comments and quoted text
        self.progress.localizedDescription = String(format: "Extracting %@…".localized, "comments and quoted texts".localized)
        highlights.merge(self.extractCommentsWithQuotes()) { $0 + $1 }
        self.progress.completedUnitCount += 1
        
        guard !self.progress.isCancelled else { throw CancellationError() }
        
        // reduce complexity of highlights dictionary
        self.progress.localizedDescription = "Preparing to color…".localized
        highlights.sanitize(progress: self.progress)
        self.progress.completedUnitCount += 1
        
        return highlights
    }
    
    
    
    // MARK: Private Methods
    
    /// extract ranges of quoted texts as well as comments in the parse range
    private func extractCommentsWithQuotes() -> [SyntaxType: [NSRange]] {
        
        let string = self.string as NSString
        var positions = [QuoteCommentItem]()
        
        if let delimiters = self.definition.blockCommentDelimiters {
            positions += string.ranges(of: delimiters.begin, range: self.parseRange)
                .map { QuoteCommentItem(type: .comments, token: .blockComment, role: .begin, range: $0) }
            positions += string.ranges(of: delimiters.end, range: self.parseRange)
                .map { QuoteCommentItem(type: .comments, token: .blockComment, role: .end, range: $0) }
        }
        
        if let delimiter = self.definition.inlineCommentDelimiter {
            positions += string.ranges(of: delimiter, range: self.parseRange)
                .flatMap { range -> [QuoteCommentItem] in
                    var lineEnd = 0
                    string.getLineStart(nil, end: &lineEnd, contentsEnd: nil, for: range)
                    let endRange = NSRange(location: lineEnd, length: 0)
                    
                    return [QuoteCommentItem(type: .comments, token: .inlineComment, role: .begin, range: range),
                            QuoteCommentItem(type: .comments, token: .inlineComment, role: .end, range: endRange)]
                }
        }
        
        for (quote, type) in self.definition.pairedQuoteTypes {
            positions += string.ranges(of: quote, range: self.parseRange)
                .map { QuoteCommentItem(type: type, token: .string(quote), role: [.begin, .end], range: $0) }
        }
        
        // remove escaped ones
        positions.removeAll { self.string.isCharacterEscaped(at: $0.range.location) }
        
        // sort by location
        positions.sort {
            if $0.range.location < $1.range.location { return true }
            if $0.range.location > $1.range.location { return false }
            
            if $0.range.isEmpty { return true }
            if $1.range.isEmpty { return false }
            
            if $0.range.length != $1.range.length {
                return $0.range.length > $1.range.length
            }
            
            return $0.role.rawValue > $1.role.rawValue
        }
        
        // scan quoted strings and comments in the parse range
        var highlights = [SyntaxType: [NSRange]]()
        var seekLocation = self.parseRange.location
        var searchingItem: QuoteCommentItem?
        
        for position in positions {
            // search next begin delimiter
            guard let item = searchingItem else {
                if position.role.contains(.begin), position.range.location >= seekLocation {
                    searchingItem = position
                }
                continue
            }
            
            // search corresponding end delimiter
            if position.role.contains(.end), position.token == item.token {
                let range = NSRange(item.range.lowerBound..<position.range.upperBound)
                
                highlights[item.type, default: []].append(range)
                
                searchingItem = nil
                seekLocation = range.upperBound
            }
        }
        
        // highlight until the end if not closed
        if let item = searchingItem {
            let range = NSRange(item.range.lowerBound..<self.parseRange.upperBound)
            
            highlights[item.type, default: []].append(range)
        }
        
        return highlights
    }
    
}



// MARK: - Private Functions

private extension Dictionary where Key == SyntaxType, Value == [NSRange] {
    
    /// Remove overlapped ranges.
    ///
    /// - Note:
    /// This sanitization reduces the performance time of `SyntaxParser.apply(highlights:range:)` significantly.
    /// Adding temporary attribute to a layoutManager in the main thread is quite sluggish,
    /// so we want to remove useless highlighting ranges as many as possible beforehand.
    ///
    /// - Parameter progress: The progress instance to give a change to cancel
    mutating func sanitize(progress: Progress) {
        
        var registeredIndexes = IndexSet()
        
        self = SyntaxType.allCases.reversed()
            .reduce(into: [SyntaxType: IndexSet]()) { (dict, type) in
                guard let ranges = self[type], !progress.isCancelled else { return }
                
                let indexes = ranges
                    .compactMap { Range($0) }
                    .reduce(into: IndexSet()) { $0.insert(integersIn: $1) }
                    .subtracting(registeredIndexes)
                
                guard !indexes.isEmpty else { return }
                
                registeredIndexes.formUnion(indexes)
                dict[type] = indexes
            }
            .mapValues { $0.rangeView.map { NSRange($0) } }
    }
    
}
