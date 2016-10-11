/*
 
 BracePair.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-08-19.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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
        
        var skippedBraceCount = 0
        var index = index
        
        while index > self.startIndex {
            guard index != self.endIndex else { return nil }
            
            index = self.index(before: index)
            
            switch self.characters[index] {
            case pair.begin:
                if skippedBraceCount == 0 {
                    return index
                }
                skippedBraceCount -= 1
                
            case pair.end:
                skippedBraceCount += 1
                
            default: break
            }
        }
        
        return nil
    }
    
    
    /// find character index of matched closing brace after a given index.
    func indexOfEndBrace(for pair: BracePair, at index: Index) -> Index? {
        
        var skippedBraceCount = 0
        var index = index
        
        while index < self.endIndex {
            index = self.index(after: index)
            
            guard index != self.endIndex else { return nil }
            
            switch self.characters[index] {
            case pair.end:
                if skippedBraceCount == 0 {
                    return index
                }
                skippedBraceCount -= 1
                
            case pair.begin:
                skippedBraceCount += 1
                
            default: break
            }
        }
        
        return nil
    }
    
}



extension BracePair: Hashable {
    
    static func ==(lhs: BracePair, rhs: BracePair) -> Bool {
        
        return lhs.begin == rhs.begin && lhs.end == rhs.end
    }
    
    
    var hashValue: Int {
        
        return self.begin.hashValue + self.end.hashValue
    }
    
}
