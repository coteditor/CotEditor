//
//  Nestable.swift
//  Syntax

//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2026 1024jp
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
import ValueRange
import StringUtils

enum NestableToken: Equatable, Hashable, Sendable {
    
    case inline(String, leadingOnly: Bool = false)
    case pair(Pair<String>, prefixes: [String] = [], isMultiline: Bool, isNestable: Bool, escapeCharacter: Character? = nil)
}


private struct NestableItem {
    
    var type: SyntaxType
    var token: NestableToken
    var role: Role
    var range: NSRange
    
    
    struct Role: OptionSet {
        
        var rawValue: Int
        
        static let begin = Self(rawValue: 1 << 0)
        static let end   = Self(rawValue: 1 << 1)
    }
}


extension [NestableToken: SyntaxType] {
    
    /// Extracts ranges of nestable items such as comments and quotes in the parse range.
    ///
    /// - Parameters:
    ///   - string: The string to parse.
    ///   - range: The range where to parse.
    /// - Throws: CancellationError.
    func parseHighlights(in string: String, range parseRange: NSRange) throws -> [SyntaxType: [NSRange]] {
        
        let positions: [NestableItem] = try self
            .flatMap { token, type in
                try Task.checkCancellation()
                return token.positions(in: string, type: type, range: parseRange)
            }
            .filter { item in
                switch item.token {
                    case .pair(let pair, _, _, _, let escapeCharacter?) where String(escapeCharacter) != pair.end:
                        // -> Double-delimiter style needs no positional escape check
                        !(string as NSString).isEscaped(at: item.range.location, by: escapeCharacter)
                    default:
                        true
                }
            }
            .sorted(using: [KeyPathComparator(\.range.location),
                            KeyPathComparator(\.range.length, order: .reverse)])
        
        guard !positions.isEmpty else { return [:] }
        
        try Task.checkCancellation()
        
        // find pairs in the parse range
        var highlights: [SyntaxType: [NSRange]] = [:]
        var seekLocation = parseRange.location
        var index = 0
        var lastLineEnd: Int?
        var failedUpperBounds: [NestableToken: Int] = [:]
        
        while index < positions.endIndex {
            let beginPosition = positions[index]
            index += 1
            
            guard
                beginPosition.role.contains(.begin),
                beginPosition.range.location >= seekLocation
            else { continue }
            
            // stop searching at the end of the current line when multiline is disabled
            // -> cache lastLineEnd to avoid high-cost .lineContentsEndIndex(at:) as much as possible
            let searchUpperBound: Int
            if beginPosition.token.allowsMultiline {
                searchUpperBound = parseRange.upperBound
            } else if let lastLineEnd, beginPosition.range.upperBound <= lastLineEnd {
                searchUpperBound = lastLineEnd
            } else {
                searchUpperBound = string.lineContentsEndIndex(at: beginPosition.range.upperBound)
                lastLineEnd = searchUpperBound
            }
            
            guard failedUpperBounds[beginPosition.token] != searchUpperBound else { continue }
            
            // use pre-found line end
            if case .inline = beginPosition.token {
                let range = NSRange(beginPosition.range.lowerBound..<searchUpperBound)
                highlights[beginPosition.type, default: []].append(range)
                
                seekLocation = range.upperBound
                index += positions[index...].prefix { $0.range.location < searchUpperBound }.count
                
                continue
            }
            
            guard let endIndex = beginPosition.token.matchingEndIndex(in: positions, from: index, upperBound: searchUpperBound) else {
                if !beginPosition.token.allowsMultiline {
                    failedUpperBounds[beginPosition.token] = searchUpperBound
                }
                continue
            }
            
            let endPosition = positions[endIndex]
            let range = NSRange(beginPosition.range.lowerBound..<endPosition.range.upperBound)
            
            highlights[beginPosition.type, default: []].append(range)
            
            seekLocation = range.upperBound
            index = endIndex
        }
        
        return highlights
    }
}


private extension NestableToken {
    
    /// Whether this token can span multiple lines.
    var allowsMultiline: Bool {
        
        switch self {
            case .inline: false
            case .pair(_, _, let isMultiline, _, _): isMultiline
        }
    }
    
    
    /// Whether nested begin tokens are allowed before a matching end token.
    var allowsNesting: Bool {
        
        switch self {
            case .inline: false
            case .pair(_, _, _, let isNestable, _): isNestable
        }
    }
    
    
    /// Collects token positions for the nestable token in the given parse range.
    ///
    /// - Parameters:
    ///   - string: The source string to scan.
    ///   - type: The syntax type associated with the token.
    ///   - parseRange: The range in `string` where positions are searched.
    /// - Returns: `NestableItem`s that represent begin/end token positions used by nested-pair parsing.
    func positions(in string: String, type: SyntaxType, range parseRange: NSRange) -> [NestableItem] {
        
        switch self {
            case .inline(let delimiter, let leadingOnly):
                return (leadingOnly
                        ? try! NSRegularExpression(pattern: "^ *(\(NSRegularExpression.escapedPattern(for: delimiter)))", options: .anchorsMatchLines)
                            .matches(in: string, range: parseRange)
                            .map { $0.range(at: 1) }
                        : string.ranges(of: delimiter, range: parseRange))
                .filter { range in
                    // ignore single-character delimiter just after a non-whitespace character
                    range.length > 1 ||
                    range.lowerBound == 0 ||
                    Unicode.Scalar((string as NSString).character(at: range.lowerBound - 1))?.properties.isWhitespace == true
                }
                .map { NestableItem(type: type, token: self, role: .begin, range: $0) }
                
            case .pair(let pair, let prefixes, _, _, _):
                // -> `prefixes` is pre-sorted by descending length at NestableToken creation
                //    to ensure longest-match-first and stable Hashable identity.
                let nsString = string as NSString
                
                if pair.begin == pair.end {
                    let ranges = string.ranges(of: pair.begin, range: parseRange)
                    if prefixes.isEmpty {
                        return ranges
                            .map { NestableItem(type: type, token: self, role: [.begin, .end], range: $0) }
                    } else {
                        return ranges.map { range in
                            if let prefixLength = Self.matchingPrefixLength(at: range.location, in: nsString, prefixes: prefixes, parseRange: parseRange) {
                                NestableItem(type: type, token: self, role: .begin,
                                             range: NSRange(location: range.location - prefixLength, length: range.length + prefixLength))
                            } else {
                                NestableItem(type: type, token: self, role: .end, range: range)
                            }
                        }
                    }
                } else {
                    let beginItems: [NestableItem] = if prefixes.isEmpty {
                        string.ranges(of: pair.begin, range: parseRange)
                            .map { NestableItem(type: type, token: self, role: .begin, range: $0) }
                    } else {
                        string.ranges(of: pair.begin, range: parseRange)
                            .compactMap { range in
                                guard let prefixLength = Self.matchingPrefixLength(at: range.location, in: nsString, prefixes: prefixes, parseRange: parseRange) else { return nil }
                                return NestableItem(type: type, token: self, role: .begin,
                                                    range: NSRange(location: range.location - prefixLength, length: range.length + prefixLength))
                            }
                    }
                    let endItems = string.ranges(of: pair.end, range: parseRange)
                        .map { NestableItem(type: type, token: self, role: .end, range: $0) }
                    return beginItems + endItems
                }
        }
    }
    
    
    /// Returns the index of the first end token that matches the begin token within the search bound.
    ///
    /// - Parameters:
    ///   - positions: The ordered token positions in the parse range.
    ///   - startIndex: The index in `positions` where the search starts.
    ///   - searchUpperBound: The upper bound where the search should stop.
    /// - Returns: The index of the matching end token in `positions`, or `nil` if not found.
    func matchingEndIndex(in positions: [NestableItem], from startIndex: Int, upperBound searchUpperBound: Int) -> Int? {
        
        let isDoubleEscape: Bool = switch self {
            case .pair(let pair, _, _, _, let escapeCharacter?): String(escapeCharacter) == pair.end
            default: false
        }
        
        var nestDepth = 0
        var skipCount = 0
        for (offset, position) in positions[startIndex...].enumerated() where position.token == self {
            guard position.range.location <= searchUpperBound else { return nil }
            
            guard skipCount == 0 else {
                skipCount -= 1
                continue
            }
            
            if position.role.contains(.end) {
                // -> Single character pairs cannot be nested.
                if isDoubleEscape, startIndex < positions.count {
                    skipCount = positions[(startIndex + offset + 1)...].prefix { next in
                        next.token == position.token &&
                        next.role.contains(.end) &&
                        next.range.location <= searchUpperBound &&
                        next.range.location == position.range.location + 1 + skipCount
                    }.count
                    
                    if skipCount.isMultiple(of: 2) {
                        return startIndex + offset + skipCount  // found
                    } else {
                        continue
                    }
                }
                if nestDepth == 0 { return startIndex + offset }  // found
                nestDepth -= 1
                
            } else if self.allowsNesting {
                nestDepth += 1
            }
        }
        return nil
    }
    
    
    /// Returns the length of the matching prefix immediately before the given location, or `nil` if no prefix matches.
    ///
    /// - Parameters:
    ///   - location: The location of the delimiter in the string.
    ///   - nsString: The source string as NSString.
    ///   - prefixes: The prefix candidates sorted by descending length.
    ///   - parseRange: The range where parsing is performed.
    /// - Returns: The UTF-16 length of the matched prefix, or `nil`.
    private static func matchingPrefixLength(at location: Int, in nsString: NSString, prefixes: [String], parseRange: NSRange) -> Int? {
        
        for prefix in prefixes {
            let length = (prefix as NSString).length
            let start = location - length
            guard start >= parseRange.location else { continue }
            
            if nsString.substring(with: NSRange(location: start, length: length)) == prefix {
                return length
            }
        }
        return nil
    }
}
