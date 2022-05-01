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

private struct NestableItem {
    
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
        
        static let begin = Self(rawValue: 1 << 0)
        static let end   = Self(rawValue: 1 << 1)
    }
}



// MARK: -

final class HighlightParser {
    
    struct Definition {
        
        var extractors: [SyntaxType: [any HighlightExtractable]]
        var nestablePaires: [String: SyntaxType]  // such as quotes to extract with comment
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
        
        // +1 for extractCommentsWithNestablePaires() and +10 for sanitizing
        let extractorCount = definition.extractors.values.map(\.count).reduce(0, +)
        self.progress = Progress(totalUnitCount: Int64(extractorCount) + 1 + 10)
    }
    
    
    // MARK: Public Methods
    
    /// Extract all highlight ranges in the parse range.
    ///
    /// - Returns: A dictionary of ranges to highlight per syntax types.
    /// - Throws: CancellationError.
    func parse() async throws -> [SyntaxType: [NSRange]] {
        
        var highlights: [SyntaxType: [NSRange]] = try await withThrowingTaskGroup(of: [SyntaxType: [NSRange]].self) { [unowned self] group in
            // extract standard highlight ranges
            for (type, extractors) in self.definition.extractors {
                for extractor in extractors {
                    _ = group.addTaskUnlessCancelled {
                        [type: try await extractor.ranges(in: self.string, range: self.parseRange)]
                    }
                }
            }
            
            // extract comments and nestable paires
            _ = group.addTaskUnlessCancelled {
                try self.extractCommentsWithNestablePaires()
            }
            
            return try await group.reduce(into: .init()) {
                $0.merge($1) { $0 + $1 }
                self.progress.completedUnitCount += 1
            }
        }
        
        try Task.checkCancellation()
        
        // reduce complexity of highlights dictionary
        try highlights.sanitize()
        self.progress.completedUnitCount += 10
        
        return highlights
    }
    
    
    
    // MARK: Private Methods
    
    /// Extract ranges of comments and paired characters such as quotes in the parse range.
    ///
    /// - Throws: CancellationError.
    private func extractCommentsWithNestablePaires() throws -> [SyntaxType: [NSRange]] {
        
        let string = self.string as NSString
        var positions: [NestableItem] = []
        
        if let delimiters = self.definition.blockCommentDelimiters {
            positions += string.ranges(of: delimiters.begin, range: self.parseRange)
                .map { NestableItem(type: .comments, token: .blockComment, role: .begin, range: $0) }
            positions += string.ranges(of: delimiters.end, range: self.parseRange)
                .map { NestableItem(type: .comments, token: .blockComment, role: .end, range: $0) }
        }
        
        try Task.checkCancellation()
        
        if let delimiter = self.definition.inlineCommentDelimiter {
            positions += string.ranges(of: delimiter, range: self.parseRange)
                .flatMap { range -> [NestableItem] in
                    var lineEnd = 0
                    string.getLineStart(nil, end: &lineEnd, contentsEnd: nil, for: range)
                    let endRange = NSRange(location: lineEnd, length: 0)
                    
                    return [NestableItem(type: .comments, token: .inlineComment, role: .begin, range: range),
                            NestableItem(type: .comments, token: .inlineComment, role: .end, range: endRange)]
                }
        }
        
        try Task.checkCancellation()
        
        for (quote, type) in self.definition.nestablePaires {
            positions += string.ranges(of: quote, range: self.parseRange)
                .map { NestableItem(type: type, token: .string(quote), role: [.begin, .end], range: $0) }
        }
        
        try Task.checkCancellation()
        
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
        
        try Task.checkCancellation()
        
        // scan quoted strings and comments in the parse range
        var highlights: [SyntaxType: [NSRange]] = [:]
        var seekLocation = self.parseRange.location
        var searchingItem: NestableItem?
        
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
    /// - Throws: CancellationError
    mutating func sanitize() throws {
        
        self = try SyntaxType.allCases.reversed()
            .reduce(into: [SyntaxType: IndexSet]()) { (dict, type) in
                guard let ranges = self[type] else { return }
                
                try Task.checkCancellation()
                
                let indexes = ranges
                    .compactMap(Range.init)
                    .reduce(into: IndexSet()) { $0.insert(integersIn: $1) }
                
                dict[type] = dict.values.reduce(into: indexes) { $0.subtract($1) }
            }
            .filter { !$0.value.isEmpty }
            .mapValues { $0.rangeView.map(NSRange.init) }
    }
    
}
