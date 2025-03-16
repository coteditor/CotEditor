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
    
    /// The remainder of string after last dot removed.
    var deletingPathExtension: String {
        
        self.replacing(/^(.+)\.[^ .]+$/, with: \.1)
    }
    
    
    /// The file extension part of the receiver by assuming the string is a filename.
    var pathExtension: String? {
        
        guard let match = self.firstMatch(of: /.\.([^ .]+)$/) else { return nil }
        
        return String(match.1)
    }
}


extension String {
    
    /// Splits the receiver into parts of filename for unique numbering.
    ///
    /// - Parameter suffix: The suffix for filename numbering, such as " copy".
    /// - Returns: The components.
    func numberingComponents(suffix: String? = nil) -> (base: String, count: Int) {
        
        assert(!self.isEmpty)
        
        let regex = if let suffix = suffix.map(NSRegularExpression.escapedPattern(for:)) {
            try! Regex("(?<base>.+?)(?:\(suffix)(?: (?<number>[0-9]+))?)?",
                       as: (Substring, base: Substring, number: Substring?).self)
        } else {
            /(?<base>.+?)(?: (?<number>[0-9]+))?/
        }
        let match = self.wholeMatch(of: regex)!
        let base = String(match.base)
        let count = match.number.flatMap { Int($0) } ?? 1
        
        return (base, count)
    }
}


public extension Collection<String> {
    
    /// Creates a unique name from the receiver's elements by adding the smallest unique number if needed.
    ///
    /// - Parameters:
    ///   - proposedName: The name candidate.
    /// - Returns: A unique name.
    func createAvailableName(for proposedName: String) -> String {
        
        let components = proposedName.numberingComponents()
        let baseName = components.base
        
        return (components.count...).lazy
            .map { $0 < 2 ? baseName : "\(baseName) \($0)" }
            .first { !self.contains($0) }!
    }
}
