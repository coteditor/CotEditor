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
//  © 2017-2024 1024jp
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
    /// - Parameter suffix: The suffix for filename numbering, such as "copy".
    /// - Returns: The components.
    func numberingComponents(suffix: String? = nil) -> (base: Substring, count: Int?) {
        
        assert(!self.isEmpty)
        assert(suffix?.isEmpty != true)
        
        let base: Substring
        let number: Substring?
        let hasSuffix: Bool
        if let suffix {
            let regex = try! Regex("(?<base>.+?)(?<suffix> \(suffix)(?: (?<number>[0-9]+))?)?",
                                   as: (Substring, base: Substring, suffix: Substring?, number: Substring?).self)
            let match = self.wholeMatch(of: regex)!
            base = match.base
            number = match.number
            hasSuffix = match.suffix != nil
        } else {
            let match = self.wholeMatch(of: /(?<base>.+?)(?: (?<number>[0-9]+))?/)!
            base = match.base
            number = match.number
            hasSuffix = false
        }
        
        let count: Int? = if let number {
            Int(number)
        } else if hasSuffix {
            1
        } else {
            nil
        }
        
        return (base, count)
    }
}


public extension Collection<String> {
    
    /// Creates a unique name from the receiver's elements by adding the suffix and also a number if needed.
    ///
    /// - Parameters:
    ///   - proposedName: The name candidate.
    ///   - suffix: The name suffix to be appended before the number.
    /// - Returns: A unique name.
    func createAvailableName(for proposedName: String, suffix: String? = nil) -> String {
        
        let components = proposedName.numberingComponents(suffix: suffix)
        let baseName = String(components.base) + (suffix.map { " " + $0 } ?? "")
        
        guard components.count != nil || self.contains(baseName) else { return baseName }
        
        return ((components.count ?? 2)...).lazy
            .map { "\(baseName) \($0)" }
            .first { !self.contains($0) }!
    }
}
