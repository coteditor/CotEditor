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
//  © 2016-2019 1024jp
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



extension StringProtocol where Self.Index == String.Index {
    
    ///
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
    
    
    /// find character index of matched opening brace before a given index.
    func indexOfBracePair(endIndex: Index, pair: BracePair, until beginIndex: Index? = nil, ignoring pairToIgnore: BracePair? = nil) -> Index? {
        
        let beginIndex = beginIndex ?? self.startIndex
        
        guard beginIndex < endIndex else { return nil }
        
        var nestDepth = 0
        var ignoredNestDepth = 0
        let subsequence = self[beginIndex..<endIndex]
        
        for (index, character) in zip(subsequence.indices, subsequence).reversed() {
            switch character {
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
    
    
    /// find character index of matched closing brace after a given index.
    func indexOfBracePair(beginIndex: Index, pair: BracePair, until endIndex: Index? = nil, ignoring pairToIgnore: BracePair? = nil) -> Index? {
        
        let endIndex = endIndex ?? self.endIndex
        
        guard beginIndex < endIndex else { return nil }
        
        var nestDepth = 0
        var ignoredNestDepth = 0
        let subsequence = self[self.index(after: beginIndex)..<endIndex]
        
        for (index, character) in zip(subsequence.indices, subsequence) {
            switch character {
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
