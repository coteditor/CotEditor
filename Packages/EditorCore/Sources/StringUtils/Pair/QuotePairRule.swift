//
//  QuotePairRule.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

public struct QuotePairRule: Equatable, Sendable {
    
    public var pair: SymbolPair
    public var escapeCharacter: Character?
    public var prefixes: [String]
    
    
    public init(pair: SymbolPair, escapeCharacter: Character? = nil, prefixes: [String] = []) {
        
        self.pair = pair
        self.escapeCharacter = escapeCharacter
        self.prefixes = prefixes
    }
}


public extension Sequence where Element == QuotePairRule {
    
    /// An array of distinct rules for quote matching by keeping ordering.
    ///
    /// Matching distinguishes rules by symbol pair and escape behavior.
    var distinctForMatching: [QuotePairRule] {
        
        self.reduce(into: []) { result, rule in
            if !result.contains(where: { $0.pair == rule.pair && $0.escapeCharacter == rule.escapeCharacter }) {
                result.append(rule)
            }
        }
    }
}


public extension String {
    
    /// Finds a quote-pair range at the given index that matches one of the given candidates.
    ///
    /// If multiple rules match, the shortest range is returned.
    ///
    /// - Parameters:
    ///   - index: The character index of the quote character to find the mate.
    ///   - candidates: Quote pair rules to find.
    /// - Returns: A matching quote-pair range, or `nil` if not found.
    func rangeOfQuotePair(at index: Index, candidates: [QuotePairRule]) -> ClosedRange<Index>? {
        
        guard !candidates.isEmpty else { return nil }
        
        let character = self[index]
        
        return candidates
            .filter { $0.pair.begin == character || $0.pair.end == character }
            .compactMap { candidate -> (range: ClosedRange<Index>, distance: Int)? in
                guard
                    let range = self.rangeOfSymbolPair(at: index, candidates: [candidate.pair], escapeCharacter: candidate.escapeCharacter),
                    candidate.prefixes.isEmpty || candidate.prefixes.contains(where: self[..<range.lowerBound].hasSuffix)
                else { return nil }
                
                return (range, self.distance(from: range.lowerBound, to: range.upperBound))
            }
            .min { $0.distance < $1.distance }?
            .range
    }
}
