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

typealias Highlight = ItemRange<SyntaxType>


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

struct HighlightParser {
    
    // MARK: Public Properties
    
    let extractors: [SyntaxType: [any HighlightExtractable]]
    let nestablePaires: [String: SyntaxType]  // such as quotes to extract with comment
    let inlineCommentDelimiter: String?
    let blockCommentDelimiters: Pair<String>?
    
    
    
    // MARK: -
    // MARK: Public Methods
    
    var isEmpty: Bool {
        
        self.extractors.isEmpty && self.nestablePaires.isEmpty && self.inlineCommentDelimiter == nil && self.blockCommentDelimiters == nil
    }
    
    
    /// Extract all highlight ranges in the parse range.
    ///
    /// - Parameters:
    ///   - string: The string to parse.
    ///   - range: The range where to parse.
    /// - Returns: A dictionary of ranges to highlight per syntax types.
    /// - Throws: CancellationError.
    func parse(string: String, range: NSRange) async throws -> [Highlight] {
        
        let highlightDictionary: [SyntaxType: [NSRange]] = try await withThrowingTaskGroup(of: [SyntaxType: [NSRange]].self) { group in
            // extract standard highlight ranges
            for (type, extractors) in self.extractors {
                for extractor in extractors {
                    _ = group.addTaskUnlessCancelled {
                        [type: try extractor.ranges(in: string, range: range)]
                    }
                }
            }
            
            // extract comments and nestable paires
            _ = group.addTaskUnlessCancelled {
                try self.extractCommentsWithNestablePaires(string: string, range: range)
            }
            
            return try await group.reduce(into: .init()) {
                $0.merge($1, uniquingKeysWith: +)
            }
        }
        
        return try Self.sanitize(highlightDictionary)
    }
    
    
    
    // MARK: Private Methods
    
    /// Extract ranges of comments and paired characters such as quotes in the parse range.
    ///
    /// - Throws: CancellationError.
    private func extractCommentsWithNestablePaires(string: String, range parseRange: NSRange) throws -> [SyntaxType: [NSRange]] {
        
        var positions: [NestableItem] = []
        
        if let delimiters = self.blockCommentDelimiters {
            positions += string.ranges(of: delimiters.begin, range: parseRange)
                .map { NestableItem(type: .comments, token: .blockComment, role: .begin, range: $0) }
            positions += string.ranges(of: delimiters.end, range: parseRange)
                .map { NestableItem(type: .comments, token: .blockComment, role: .end, range: $0) }
        }
        
        try Task.checkCancellation()
        
        if let delimiter = self.inlineCommentDelimiter {
            positions += string.ranges(of: delimiter, range: parseRange)
                .flatMap { range -> [NestableItem] in
                    let lineEnd = string.lineContentsEndIndex(at: range.upperBound)
                    let endRange = NSRange(location: lineEnd, length: 0)
                    
                    return [NestableItem(type: .comments, token: .inlineComment, role: .begin, range: range),
                            NestableItem(type: .comments, token: .inlineComment, role: .end, range: endRange)]
                }
        }
        
        try Task.checkCancellation()
        
        for (quote, type) in self.nestablePaires {
            positions += string.ranges(of: quote, range: parseRange)
                .map { NestableItem(type: type, token: .string(quote), role: [.begin, .end], range: $0) }
        }
        
        try Task.checkCancellation()
        
        // remove escaped ones
        positions.removeAll { string.isCharacterEscaped(at: $0.range.location) }
        
        guard !positions.isEmpty else { return [:] }
        
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
        
        // find paires in the parse range
        var highlights: [SyntaxType: [NSRange]] = [:]
        var seekLocation = parseRange.location
        var index = 0
        
        while index < positions.count {
            let beginPosition = positions[index]
            index += 1
            
            guard
                beginPosition.role.contains(.begin),
                beginPosition.range.location >= seekLocation
            else { continue }
                
            // search corresponding end delimiter
            guard let endIndex = positions[index...].firstIndex(where: {
                $0.role.contains(.end) && $0.token == beginPosition.token
            }) else { continue }  // give up if no end delimiter found
            
            let endPosition = positions[endIndex]
            let range = NSRange(beginPosition.range.lowerBound..<endPosition.range.upperBound)
            
            highlights[beginPosition.type, default: []].append(range)
            
            seekLocation = range.upperBound
            index = endIndex
        }
        
        return highlights
    }
    
    
    /// Remove overlapped ranges and convert to sorted Highlights.
    ///
    /// - Note:
    /// This sanitization reduces the performance time of `SyntaxParser.apply(highlights:range:)` significantly.
    ///
    /// - Parameter dictionary: The syntax highlight dictionary.
    /// - Returns: An array of sorted Highlight structs.
    /// - Throws: CancellationError
    private static func sanitize(_ dictionary: [SyntaxType: [NSRange]]) throws -> [Highlight] {
        
        try SyntaxType.allCases.reversed()
            .reduce(into: [SyntaxType: IndexSet]()) { (dict, type) in
                guard let ranges = dictionary[type] else { return }
                
                try Task.checkCancellation()
                
                let indexes = ranges
                    .compactMap(Range.init)
                    .reduce(into: IndexSet()) { $0.insert(integersIn: $1) }
                
                dict[type] = dict.values.reduce(into: indexes) { $0.subtract($1) }
            }
            .mapValues { $0.rangeView.map(NSRange.init) }
            .flatMap { (type, ranges) in ranges.map { ItemRange(item: type, range: $0) } }
            .sorted { $0.range.location < $1.range.location }
    }
    
}
