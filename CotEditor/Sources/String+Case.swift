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
//  © 2018-2020 1024jp
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

import Foundation.NSRegularExpression

extension String {
    
    /// Transform all camel and pascal case words to snake case.
    var snakecased: String {
        
        return self.ranges(pattern: "(?<=\\w)(?=\\p{uppercase})")
            .reversed()
            .reduce(into: self.lowercased()) { (string, range) in
                string.replaceSubrange(range, with: "_")
            }
    }
    
    
    /// Transform all snake and pascal case words to camel case.
    var camelcased: String {
        
        return self.ranges(pattern: "(?<=\\w)(?:\\p{uppercase}|_\\w)")
            .reversed()
            .reduce(into: self.lowercased()) { (string, range) in
                let index = string.index(before: range.upperBound)
                
                string.replaceSubrange(range, with: string[workaround: index].uppercased())
            }
    }
    
    
    /// Transform all snake and pascal case words to pascal case.
    var pascalcased: String {
        
        return self.ranges(pattern: "(?:\\b|(?<=\\w)_)\\w")
            .reversed()
            .reduce(into: self) { (string, range) in
                let index = string.index(before: range.upperBound)
                
                string.replaceSubrange(range, with: string[workaround: index].uppercased())
            }
    }
    
    
    
    // MARK: Private Methods
    
    private func ranges(pattern: String) -> [Range<Index>] {
        
        return (try! NSRegularExpression(pattern: pattern))
            .matches(in: self, range: self.nsRange)
            .map { $0.range }
            .map { String.Index(utf16Offset: $0.lowerBound, in: self)..<String.Index(utf16Offset: $0.upperBound, in: self) }
    }
    
}
