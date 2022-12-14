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
    
    typealias AbbreviatedMatchResult = (ranges: [Range<String.Index>], score: Int)
    
    
    /// Search ranges of the characters contains in the `searchString` in the `searchString` order.
    ///
    /// - Parameter searchString: The string to search.
    /// - Returns: The array of matched character ranges or `nil` if not matched.
    func abbreviatedMatch(with searchString: String) -> AbbreviatedMatchResult? {
        
        guard !searchString.isEmpty, !self.isEmpty else { return nil }
        
        let ranges: [Range<String.Index>] = searchString.reduce(into: []) { (ranges, character) in
            let index = ranges.last?.upperBound ?? self.startIndex
            
            guard let range = self.range(of: String(character), options: .caseInsensitive, range: index..<self.endIndex) else { return }
            
            ranges.append(range)
        }
        
        guard ranges.count == searchString.count else { return nil }
        
        // just simply calculate the length...
        let score = self.distance(from: ranges.first!.lowerBound, to: ranges.last!.upperBound)
        
        return (ranges, score)
    }
}
