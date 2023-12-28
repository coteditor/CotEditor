//
//  Pair.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-08-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

struct Pair<T> {
    
    var begin: T
    var end: T
    
    
    init(_ begin: T, _ end: T) {
        
        self.begin = begin
        self.end = end
    }
}


extension Pair: Equatable where T: Equatable { }
extension Pair: Hashable where T: Hashable { }



// MARK: BracePair

typealias BracePair = Pair<Character>

extension Pair where T == Character {
    
    static let braces: [BracePair] = [BracePair("(", ")"),
                                      BracePair("{", "}"),
                                      BracePair("[", "]")]
    static let ltgt = BracePair("<", ">")
    static let doubleQuotes = BracePair("\"", "\"")
    
    
    enum PairIndex {
        
        case begin(String.Index)
        case end(String.Index)
        case odd
    }
}



extension StringProtocol {
    
    /// Finds the mate of a brace pair.
    ///
    /// - Parameters:
    ///   - index: The character index of the brace character to find the mate.
    ///   - candidates: Brace pairs to find.
    ///   - range: The range of characters to find in.
    ///   - pairToIgnore: The brace pair in which brace characters should be ignored.
    /// - Returns: The character index of the matched pair.
    func indexOfBracePair(at index: Index, candidates: [BracePair], in range: Range<Index>? = nil, ignoring pairToIgnore: BracePair? = nil) -> BracePair.PairIndex? {
        
        guard !self.isCharacterEscaped(at: index) else { return nil }
        
        let character = self[index]
        
        guard let pair = candidates.first(where: { $0.begin == character || $0.end == character }) else { return nil }
        
        switch character {
            case pair.begin:
                guard let endIndex = self.indexOfBracePair(beginIndex: index, pair: pair, until: range?.upperBound, ignoring: pairToIgnore) else { return .odd }
                return .end(endIndex)
                
            case pair.end:
                guard let beginIndex = self.indexOfBracePair(endIndex: index, pair: pair, until: range?.lowerBound, ignoring: pairToIgnore) else { return .odd }
                return .begin(beginIndex)
                
            default: preconditionFailure()
        }
    }
    
    
    /// Finds character index of matched opening brace before a given index.
    ///
    /// This method ignores escaped characters.
    ///
    /// - Parameters:
    ///   - endIndex: The character index of the closing brace of the pair to find.
    ///   - pair: The brace pair to find.
    ///   - beginIndex: The lower boundary of the find range.
    ///   - pairToIgnore: The brace pair in which brace characters should be ignored.
    /// - Returns: The character index of the matched opening brace, or `nil` if not found.
    func indexOfBracePair(endIndex: Index, pair: BracePair, until beginIndex: Index? = nil, ignoring pairToIgnore: BracePair? = nil) -> Index? {
        
        assert(endIndex <= self.endIndex)
        
        let beginIndex = beginIndex ?? self.startIndex
        
        guard beginIndex < endIndex else { return nil }
        
        var index = endIndex
        var nestDepth = 0
        var ignoredNestDepth = 0
        
        while index > beginIndex {
            index = self.index(before: index)
            
            switch self[index] {
                case pair.begin where ignoredNestDepth == 0:
                    guard !self.isCharacterEscaped(at: index) else { continue }
                    if nestDepth == 0 { return index }  // found
                    nestDepth -= 1
                    
                case pair.end where ignoredNestDepth == 0:
                    guard !self.isCharacterEscaped(at: index) else { continue }
                    nestDepth += 1
                    
                case pairToIgnore?.begin:
                    guard !self.isCharacterEscaped(at: index) else { continue }
                    ignoredNestDepth -= 1
                    
                case pairToIgnore?.end:
                    guard !self.isCharacterEscaped(at: index) else { continue }
                    ignoredNestDepth += 1
                    
                default: break
            }
        }
        
        return nil
    }
    
    
    /// Finds character index of matched closing brace after a given index.
    ///
    /// This method ignores escaped characters.
    ///
    /// - Parameters:
    ///   - beginIndex: The character index of the opening brace of the pair to find.
    ///   - pair: The brace pair to find.
    ///   - endIndex: The upper boundary of the find range.
    ///   - pairToIgnore: The brace pair in which brace characters should be ignored.
    /// - Returns: The character index of the matched closing brace, or `nil` if not found.
    func indexOfBracePair(beginIndex: Index, pair: BracePair, until endIndex: Index? = nil, ignoring pairToIgnore: BracePair? = nil) -> Index? {
        
        assert(beginIndex >= self.startIndex)
        
        // avoid (endIndex == self.startIndex)
        guard !self.isEmpty, endIndex.flatMap({ $0 > self.startIndex }) != false else { return nil }
        
        let endIndex = self.index(before: endIndex ?? self.endIndex)
        
        guard beginIndex < endIndex else { return nil }
        
        var index = beginIndex
        var nestDepth = 0
        var ignoredNestDepth = 0
        
        while index < endIndex {
            index = self.index(after: index)
            
            switch self[index] {
                case pair.end where ignoredNestDepth == 0:
                    guard !self.isCharacterEscaped(at: index) else { continue }
                    if nestDepth == 0 { return index }  // found
                    nestDepth -= 1
                    
                case pair.begin where ignoredNestDepth == 0:
                    guard !self.isCharacterEscaped(at: index) else { continue }
                    nestDepth += 1
                    
                case pairToIgnore?.end:
                    guard !self.isCharacterEscaped(at: index) else { continue }
                    ignoredNestDepth -= 1
                    
                case pairToIgnore?.begin:
                    guard !self.isCharacterEscaped(at: index) else { continue }
                    ignoredNestDepth += 1
                    
                default: break
            }
        }
        
        return nil
    }
}
