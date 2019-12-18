//
//  String+Case.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-05-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2019 1024jp
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

extension String {
    
    /// Transform all camel and pascal case words to snake case.
    var snakecased: String {
        
        return self.ranges(pattern: "(?<=\\w)(?=[A-Z])")
            .reversed()
            .reduce(self.lowercased()) { (string, range) in
                string.replacingCharacters(in: range, with: "_")
            }
    }
    
    
    /// Transform all snake and pascal case words to camel case.
    var camelcased: String {
        
        return self.ranges(pattern: "(?<=\\w)(?:[A-Z]|_\\w)")
            .reversed()
            .reduce(self.lowercased()) { (string, range) in
                let index = string.index(before: range.upperBound)
                
                return string.replacingCharacters(in: range, with: string[index].uppercased())
            }
    }
    
    
    /// Transform all snake and pascal case words to pascal case.
    var pascalcased: String {
        
        return self.ranges(pattern: "(?:\\b|(?<=\\w)_)\\w")
            .reversed()
            .reduce(self) { (string, range) in
                let index = string.index(before: range.upperBound)
                
                return string.replacingCharacters(in: range, with: string[index].uppercased())
            }
    }
    
    
    
    // MARK: Private Methods
    
    private func ranges(pattern: String) -> [Range<Index>] {
        
        return (try! NSRegularExpression(pattern: pattern))
            .matches(in: self, range: self.nsRange)
            .map { $0.range }
            .compactMap { String.Index(utf16Offset: $0.lowerBound, in: self)..<String.Index(utf16Offset: $0.upperBound, in: self) }
    }
    
}
