//
//  String+Filename.swift
//  URLUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2025 1024jp
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

public extension String {
    
    /// The remainder of the string after the last dot removed.
    var deletingPathExtension: String {
        
        self.replacing(/^(.+)\.[^ .]+$/, with: \.1)
    }
    
    
    /// The file extension part of the receiver by assuming the string is a filename.
    var pathExtension: String? {
        
        guard let match = self.firstMatch(of: /.\.([^ .]+)$/) else { return nil }
        
        return String(match.1)
    }
    
    
    /// Creates a unique name from the given names by adding the smallest unique number if needed.
    ///
    /// - Parameters:
    ///   - names: The names already taken.
    /// - Returns: A unique name.
    func appendingUniqueNumber(in names: [String]) -> String {
        
        let (base, count) = self.numberingComponents
        
        return (count...).lazy
            .map { ($0 < 2) ? base : "\(base) \($0)" }
            .first { !names.contains($0) }!
    }
}


extension String {
    
    /// Splits the receiver into parts of filename for unique numbering..
    var numberingComponents: (base: String, count: Int) {
        
        assert(!self.isEmpty)
        
        let match = self.wholeMatch(of: /(?<base>.+?)(?: (?<number>[0-9]+))?/)!
        let base = String(match.base)
        let count = match.number.flatMap { Int($0) } ?? 1
        
        return (base, count)
    }
}
