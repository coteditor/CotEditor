//
//  SymbolPair.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2026 1024jp
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

public typealias SymbolPair = Pair<Character>

public extension Pair where T == Character {
    
    static let braces: [SymbolPair] = [SymbolPair("(", ")"),
                                       SymbolPair("{", "}"),
                                       SymbolPair("[", "]")]
    static let quotes: [SymbolPair] = [SymbolPair("\"", "\""),
                                       SymbolPair("'", "'"),
                                       SymbolPair("`", "`")]
    static let ltgt = SymbolPair("<", ">")
    
    
    enum PairIndex: Equatable, Sendable {
        
        case begin(String.Index)
        case end(String.Index)
    }
}


public extension Pair.PairIndex {
    
    /// The representing string index.
    var index: String.Index {
        
        switch self {
            case .begin(let index), .end(let index): index
        }
    }
}


public enum DelimiterEscapeStyle: String, Sendable, CaseIterable, Codable {
    
    case backslash
    case doubleDelimiter
    case none
}


public extension StringProtocol {
    
    /// Finds the range enclosed by one of given symbol pairs.
    ///
    /// - Parameters:
    ///   - range: The character range on which to base the search.
    ///   - candidates: The pairs of symbols to search.
    ///   - escapeStyle: The delimiter escape style.
    /// - Returns: The range of the enclosing symbol pair, or `nil` if not found.
    func rangeOfEnclosingSymbolPair(at range: Range<Index>, candidates: [SymbolPair], escapeStyle: DelimiterEscapeStyle = .backslash) -> Range<Index>? {
        
        SymbolPairScanner(string: String(self), candidates: candidates, baseRange: range, escapeStyle: escapeStyle)
            .scan()
    }
    
    
    /// Finds the range enclosed by the symbol pair, one of which locates at the given index.
    ///
    /// - Parameters:
    ///   - index: The character index of the symbol character to find the mate.
    ///   - candidates: Symbol pairs to find.
    ///   - pairToIgnore: The symbol pair in which symbol characters should be ignored.
    ///   - escapeStyle: The delimiter escape style.
    func rangeOfSymbolPair(at index: Index, candidates: [SymbolPair], ignoring pairToIgnore: SymbolPair? = nil, escapeStyle: DelimiterEscapeStyle = .none) -> ClosedRange<Index>? {
        
        guard let pairIndex = self.indexOfSymbolPair(at: index, candidates: candidates, ignoring: pairToIgnore, escapeStyle: escapeStyle) else { return nil }
        
        return switch pairIndex {
            case .begin(let beginIndex): beginIndex...index
            case .end(let endIndex): index...endIndex
        }
    }
    
    
    /// Finds the mate of a symbol pair.
    ///
    /// - Parameters:
    ///   - index: The character index of the symbol character to find the mate.
    ///   - candidates: Symbol pairs to find.
    ///   - range: The range of characters to find in.
    ///   - pairToIgnore: The symbol pair in which symbol characters should be ignored.
    ///   - escapeStyle: The delimiter escape style.
    /// - Returns: The character index of the matched pair.
    func indexOfSymbolPair(at index: Index, candidates: [SymbolPair], in range: Range<Index>? = nil, ignoring pairToIgnore: SymbolPair? = nil, escapeStyle: DelimiterEscapeStyle = .backslash) -> SymbolPair.PairIndex? {
        
        guard escapeStyle != .backslash || !self.isEscaped(at: index) else { return nil }
        
        let character = self[index]
        
        guard let pair = candidates.first(where: { $0.begin == character || $0.end == character }) else { return nil }
        
        if pair.begin == pair.end {
            let beginIndex = self.indexOfSymbolPair(endIndex: index, pair: pair, until: range?.lowerBound, ignoring: pairToIgnore, escapeStyle: escapeStyle)
            let endIndex = self.indexOfSymbolPair(beginIndex: index, pair: pair, until: range?.upperBound, ignoring: pairToIgnore, escapeStyle: escapeStyle)
            
            return switch (beginIndex, endIndex) {
                case let (beginIndex?, nil): .begin(beginIndex)
                case let (nil, endIndex?): .end(endIndex)
                default: nil
            }
        }
        
        switch character {
            case pair.begin:
                guard let endIndex = self.indexOfSymbolPair(beginIndex: index, pair: pair, until: range?.upperBound, ignoring: pairToIgnore, escapeStyle: escapeStyle) else { return nil }
                return .end(endIndex)
                
            case pair.end:
                guard let beginIndex = self.indexOfSymbolPair(endIndex: index, pair: pair, until: range?.lowerBound, ignoring: pairToIgnore, escapeStyle: escapeStyle) else { return nil }
                return .begin(beginIndex)
                
            default: preconditionFailure()
        }
    }
    
    
    /// Finds character index of matched opening symbol before a given index.
    ///
    /// This method ignores escaped characters.
    ///
    /// - Parameters:
    ///   - endIndex: The character index of the closing symbol of the pair to find.
    ///   - pair: The symbol pair to find.
    ///   - beginIndex: The lower boundary of the find range.
    ///   - pairToIgnore: The symbol pair in which symbol characters should be ignored.
    ///   - escapeStyle: The delimiter escape style.
    /// - Returns: The character index of the matched opening symbol, or `nil` if not found.
    func indexOfSymbolPair(endIndex: Index, pair: SymbolPair, until beginIndex: Index? = nil, ignoring pairToIgnore: SymbolPair? = nil, escapeStyle: DelimiterEscapeStyle = .backslash) -> Index? {
        
        assert(endIndex <= self.endIndex)
        
        let beginIndex = beginIndex ?? self.startIndex
        
        guard beginIndex < endIndex else { return nil }
        
        if escapeStyle == .doubleDelimiter, pair.begin == pair.end {
            var index = endIndex
            
            while index > beginIndex {
                index = self.index(before: index)
                
                guard self[index] == pair.begin else { continue }
                
                if index > beginIndex {
                    let previousIndex = self.index(before: index)
                    if self[previousIndex] == pair.begin {
                        index = previousIndex
                        continue
                    }
                }
                
                return index
            }
            
            return nil
        }
        
        var index = endIndex
        var nestDepth = 0
        var ignoredNestDepth = 0
        
        while index > beginIndex {
            index = self.index(before: index)
            
            switch self[index] {
                case pair.begin where ignoredNestDepth == 0:
                    guard escapeStyle != .backslash || !self.isEscaped(at: index) else { continue }
                    if nestDepth == 0 { return index }  // found
                    nestDepth -= 1
                    
                case pair.end where ignoredNestDepth == 0:
                    guard escapeStyle != .backslash || !self.isEscaped(at: index) else { continue }
                    nestDepth += 1
                    
                case pairToIgnore?.begin:
                    guard escapeStyle != .backslash || !self.isEscaped(at: index) else { continue }
                    ignoredNestDepth -= 1
                    
                case pairToIgnore?.end:
                    guard escapeStyle != .backslash || !self.isEscaped(at: index) else { continue }
                    ignoredNestDepth += 1
                    
                default: break
            }
        }
        
        return nil
    }
    
    
    /// Finds character index of matched closing symbol after a given index.
    ///
    /// This method ignores escaped characters.
    ///
    /// - Parameters:
    ///   - beginIndex: The character index of the opening symbol of the pair to find.
    ///   - pair: The symbol pair to find.
    ///   - endIndex: The upper boundary of the find range.
    ///   - pairToIgnore: The symbol pair in which symbol characters should be ignored.
    ///   - escapeStyle: The delimiter escape style.
    /// - Returns: The character index of the matched closing symbol, or `nil` if not found.
    func indexOfSymbolPair(beginIndex: Index, pair: SymbolPair, until endIndex: Index? = nil, ignoring pairToIgnore: SymbolPair? = nil, escapeStyle: DelimiterEscapeStyle = .backslash) -> Index? {
        
        assert(beginIndex >= self.startIndex)
        
        // avoid (endIndex == self.startIndex)
        guard !self.isEmpty, endIndex.map({ $0 > self.startIndex }) != false else { return nil }
        
        let endIndex = self.index(before: endIndex ?? self.endIndex)
        
        guard beginIndex < endIndex else { return nil }
        
        if escapeStyle == .doubleDelimiter, pair.begin == pair.end {
            var index = beginIndex
            
            while index < endIndex {
                index = self.index(after: index)
                
                guard self[index] == pair.end else { continue }
                
                if index < endIndex {
                    let nextIndex = self.index(after: index)
                    if self[nextIndex] == pair.end {
                        index = nextIndex
                        continue
                    }
                }
                
                return index
            }
            
            return nil
        }
        
        var index = beginIndex
        var nestDepth = 0
        var ignoredNestDepth = 0
        
        while index < endIndex {
            index = self.index(after: index)
            
            switch self[index] {
                case pair.end where ignoredNestDepth == 0:
                    guard escapeStyle != .backslash || !self.isEscaped(at: index) else { continue }
                    if nestDepth == 0 { return index }  // found
                    nestDepth -= 1
                    
                case pair.begin where ignoredNestDepth == 0:
                    guard escapeStyle != .backslash || !self.isEscaped(at: index) else { continue }
                    nestDepth += 1
                    
                case pairToIgnore?.end:
                    guard escapeStyle != .backslash || !self.isEscaped(at: index) else { continue }
                    ignoredNestDepth -= 1
                    
                case pairToIgnore?.begin:
                    guard escapeStyle != .backslash || !self.isEscaped(at: index) else { continue }
                    ignoredNestDepth += 1
                    
                default: break
            }
        }
        
        return nil
    }
}


// MARK: -

private final class SymbolPairScanner {
    
    let string: String
    let candidates: [SymbolPair]
    
    private var scanningRange: Range<String.Index>
    private var scanningPair: SymbolPair?
    private let escapeStyle: DelimiterEscapeStyle
    private var finished: Bool = false
    private var found: Bool = false
    
    
    init(string: String, candidates: [SymbolPair], baseRange: Range<String.Index>, escapeStyle: DelimiterEscapeStyle) {
        
        assert(candidates.allSatisfy({ $0.begin != $0.end }))
        
        self.string = string
        self.candidates = candidates
        self.scanningRange = baseRange
        self.escapeStyle = escapeStyle
    }
    
    
    // MARK: Public Methods
    
    /// Finds the nearest range enclosed by one of the candidate symbol pairs.
    ///
    /// - Returns: The range of characters.
    func scan() -> Range<String.Index>? {
        
        while !self.finished {
            self.scanForward()
            
            guard !self.finished else { return nil }
            
            self.scanBackward()
        }
        
        return self.found ? self.scanningRange : nil
    }
    
    
    // MARK: Private Methods
    
    /// Scans the next symbol from the current scanning range.
    private func scanForward() {
        
        var index = self.scanningRange.upperBound
        var nestDepths: [SymbolPair: Int] = [:]
        var isEscaped = self.escapeStyle == .backslash &&
            (index != self.string.startIndex) &&
            self.string[self.string.index(before: index)] == "\\"
        
        for character in self.string[index...] {
            index = self.string.index(after: index)
            
            if isEscaped {
                isEscaped = false
                continue
            }
            
            if let pair = self.candidates.first(where: { $0.begin == character }) {
                nestDepths[pair, default: 0] += 1
                
            } else if let pair = self.candidates.first(where: { $0.end == character }) {
                if nestDepths[pair, default: 0] > 0 {
                    nestDepths[pair, default: 0] -= 1
                } else {
                    self.scanningRange = self.scanningRange.lowerBound..<index
                    self.scanningPair = pair
                    return
                }
            }
            
            if self.escapeStyle == .backslash, character == "\\" {
                isEscaped = true
            } else {
                isEscaped = false
            }
        }
        
        self.finished = true
    }
    
    
    /// Scans the previous symbol from the current scanning range.
    private func scanBackward() {
        
        var index = self.scanningRange.lowerBound
        var nestDepths: [SymbolPair: Int] = [:]
        
        for character in self.string[..<index].reversed() {
            index = self.string.index(before: index)
            
            if let pair = self.candidates.first(where: { $0.begin == character }) {
                guard self.escapeStyle != .backslash || !self.string.isEscaped(at: index) else { continue }
                
                if nestDepths[pair, default: 0] > 0 {
                    nestDepths[pair, default: 0] -= 1
                } else {
                    self.finished = true
                    self.found = true
                    self.scanningRange = index..<self.scanningRange.upperBound
                    return
                }
                
            } else if let pair = self.candidates.first(where: { $0.end == character }) {
                guard self.escapeStyle != .backslash || !self.string.isEscaped(at: index) else { continue }
                
                nestDepths[pair, default: 0] += 1
            }
        }
        
        self.finished = true
    }
}
