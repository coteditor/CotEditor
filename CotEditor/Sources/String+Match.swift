//
//  String+Match.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-09-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2022 1024jp
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

extension String {
    
    struct AbbreviatedMatchResult {
        
        var ranges: [Range<String.Index>]
        var remaining: String
        var score: Int
    }
    
    
    /// Search ranges of the characters contains in the `searchString` in the `searchString` order.
    ///
    /// - Parameter searchString: The string to search.
    /// - Returns: The matched character ranges and score, or `nil` if not matched.
    func abbreviatedMatch(with searchString: String) -> AbbreviatedMatchResult? {
        
        guard !searchString.isEmpty, !self.isEmpty else { return nil }
        
        var ranges: [Range<String.Index>] = []
        for character in searchString {
            let index = ranges.last?.upperBound ?? self.startIndex
            
            guard let range = self.range(of: String(character), options: .caseInsensitive, range: index..<self.endIndex) else { break }
            
            ranges.append(range)
        }
        
        guard !ranges.isEmpty else { return nil }
        
        let remaining = String(searchString.suffix(searchString.count - ranges.count))
        
        // just simply calculate the length...
        let score = self.distance(from: ranges.first!.lowerBound, to: ranges.last!.upperBound)
        
        return AbbreviatedMatchResult(ranges: ranges, remaining: remaining, score: score)
    }
}
