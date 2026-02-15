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
    case pair(Pair<String>, isMultiline: Bool)
    
    
    init?(highlight: Syntax.Highlight) {
        
        guard
            !highlight.isRegularExpression,
            let pair = highlight.end.map({ Pair(highlight.begin, $0) }),
            pair.array.allSatisfy({ $0.rangeOfCharacter(from: .alphanumerics) == nil })  // symbol
        else { return nil }
        
        self = .pair(pair, isMultiline: highlight.isMultiline)
    }
}


private extension NestableToken {
    
    var allowsMultiline: Bool {
        
        switch self {
            case .inline: false
            case .pair(_, let isMultiline): isMultiline
        }
    }
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
        
        let positions: [NestableItem] = try self.flatMap { token, type -> [NestableItem] in
            try Task.checkCancellation()
            
            switch token {
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
                        .flatMap { range -> [NestableItem] in
                            let lineEnd = string.lineContentsEndIndex(at: range.upperBound)
                            let endRange = NSRange(location: lineEnd, length: 0)
                            
                            return [NestableItem(type: type, token: token, role: .begin, range: range),
                                    NestableItem(type: type, token: token, role: .end, range: endRange)]
                        }
                    
                case .pair(let pair, _):
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
            .filter { !string.isEscaped(at: $0.range.location) }
            .sorted(using: [KeyPathComparator(\.range.location),
                            KeyPathComparator(\.range.length, order: .reverse)])
        
        guard !positions.isEmpty else { return [:] }
        
        try Task.checkCancellation()
        
        // find pairs in the parse range
        var highlights: [SyntaxType: [NSRange]] = [:]
        var seekLocation = parseRange.location
        var index = 0
        
        while index < positions.endIndex {
            let beginPosition = positions[index]
            index += 1
            
            guard
                beginPosition.role.contains(.begin),
                beginPosition.range.location >= seekLocation
            else { continue }
            
            // search corresponding end delimiter
            let endIndex: Int? = {
                let searchUpperBound = beginPosition.token.allowsMultiline
                    ? parseRange.upperBound
                    : string.lineContentsEndIndex(at: beginPosition.range.upperBound)
                
                var nestDepth = 0
                for (offset, position) in positions[index...].enumerated() where position.token == beginPosition.token {
                    // stop searching at the end of the current line when multiline is disabled
                    if position.range.location > searchUpperBound {
                        return nil
                    }
                    
                    if position.role.contains(.end) {
                        if nestDepth == 0 { return index + offset }  // found
                        nestDepth -= 1
                    } else {
                        nestDepth += 1
                    }
                }
                return nil
            }()
            
            guard let endIndex else { continue }  // give up if no end delimiter found
            
            let endPosition = positions[endIndex]
            let range = NSRange(beginPosition.range.lowerBound..<endPosition.range.upperBound)
            
            highlights[beginPosition.type, default: []].append(range)
            
            seekLocation = range.upperBound
            index = endIndex
        }
        
        return highlights
    }
}
