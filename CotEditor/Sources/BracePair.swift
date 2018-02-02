/*
 
 BracePair.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-08-19.
 
 ------------------------------------------------------------------------------
 
 © 2016-2018 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

struct BracePair {
    
    let begin: Character
    let end: Character
    
    static let braces: [BracePair] = [BracePair(begin: "(", end: ")"),
                                      BracePair(begin: "{", end: "}"),
                                      BracePair(begin: "[", end: "]")]
    static let ltgt = BracePair(begin: "<", end: ">")
    static let doubleQuotes = BracePair(begin: "\"", end: "\"")
}



extension String {
    
    /// find character index of matched opening brace before a given index.
    func indexOfBeginBrace(for pair: BracePair, at index: Index) -> Index? {
        
        var nestDepth = 0
        let subsequence = self[..<index]
        
        for (index, character) in zip(subsequence.indices, subsequence).reversed() {
            switch character {
            case pair.begin where nestDepth == 0:
                return index
            case pair.begin:
                nestDepth -= 1
            case pair.end:
                nestDepth += 1
            default: break
            }
        }
        
        return nil
    }
    
    
    /// find character index of matched closing brace after a given index.
    func indexOfEndBrace(for pair: BracePair, at index: Index) -> Index? {
        
        var nestDepth = 0
        let subsequence = self[self.index(after: index)...]
        
        for (index, character) in zip(subsequence.indices, subsequence) {
            switch character {
            case pair.end where nestDepth == 0:
                return index
            case pair.end:
                nestDepth -= 1
            case pair.begin:
                nestDepth += 1
            default: break
            }
        }
        
        return nil
    }
    
}



extension BracePair: Hashable {
    
    static func == (lhs: BracePair, rhs: BracePair) -> Bool {
        
        return lhs.begin == rhs.begin && lhs.end == rhs.end
    }
    
    
    var hashValue: Int {
        
        return self.begin.hashValue + self.end.hashValue
    }
    
}
