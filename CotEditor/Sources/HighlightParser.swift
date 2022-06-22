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


enum NestableToken: Equatable, Hashable {
    
    case inline(String)
    case pair(Pair<String>)
}


private struct NestableItem {
    
    var type: SyntaxType
    var token: NestableToken
    var role: Role
    var range: NSRange
    
    
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
    let nestables: [NestableToken: SyntaxType]
    
    
    
    // MARK: -
    // MARK: Public Methods
    
    var isEmpty: Bool {
        
        self.extractors.isEmpty && self.nestables.isEmpty
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
            
            // extract nestables
            _ = group.addTaskUnlessCancelled {
                try self.extractNestables(string: string, range: range)
            }
            
            return try await group.reduce(into: .init()) {
                $0.merge($1, uniquingKeysWith: +)
            }
        }
        
        return try Self.sanitize(highlightDictionary)
    }
    
    
    
    // MARK: Private Methods
    
    /// Extract ranges of nestable items such as comments and quotes in the parse range.
    ///
    /// - Parameters:
    ///   - string: The string to parse.
    ///   - range: The range where to parse.
    /// - Throws: CancellationError.
    private func extractNestables(string: String, range parseRange: NSRange) throws -> [SyntaxType: [NSRange]] {
        
        let positions: [NestableItem] = try self.nestables.flatMap { (token, type) -> [NestableItem] in
            try Task.checkCancellation()
            
            switch token {
                case .inline(let delimiter):
                    return string.ranges(of: delimiter, range: parseRange)
                        .flatMap { range -> [NestableItem] in
                            let lineEnd = string.lineContentsEndIndex(at: range.upperBound)
                            let endRange = NSRange(location: lineEnd, length: 0)
                            
                            return [NestableItem(type: .comments, token: token, role: .begin, range: range),
                                    NestableItem(type: .comments, token: token, role: .end, range: endRange)]
                        }
                    
                case .pair(let pair):
                    if pair.begin == pair.end {
                        return string.ranges(of: pair.begin, range: parseRange)
                            .map { NestableItem(type: type, token: token, role: [.begin, .end], range: $0) }
                    } else {
                        return string.ranges(of: pair.begin, range: parseRange)
                            .map { NestableItem(type: type, token: token, role: .begin, range: $0) }
                        + string.ranges(of: pair.end, range: parseRange)
                            .map { NestableItem(type: type, token: token, role: .end, range: $0) }
                    }
            }
        }
            .filter { !string.isCharacterEscaped(at: $0.range.location) }  // remove escaped ones
            .sorted {  // sort by location
                if $0.range.location < $1.range.location { return true }
                if $0.range.location > $1.range.location { return false }
                
                if $0.range.isEmpty { return true }
                if $1.range.isEmpty { return false }
                
                if $0.range.length != $1.range.length {
                    return $0.range.length > $1.range.length
                }
                
                return $0.role.rawValue > $1.role.rawValue
            }
        
        guard !positions.isEmpty else { return [:] }
        
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
