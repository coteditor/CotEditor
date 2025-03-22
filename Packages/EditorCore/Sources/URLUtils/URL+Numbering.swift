//
//  URL+Numbering.swift
//  URLUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-03-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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

public struct NumberingFormat: Sendable {
    
    private var format: @Sendable (String) -> String
    private var numberedFormat: @Sendable (String, Int) -> String
    
    
    public init(_ format: @Sendable @escaping (_ base: String) -> String, numbered numberedFormat: @Sendable @escaping (_ base: String, _ count: Int) -> String) {
        
        self.format = format
        self.numberedFormat = numberedFormat
    }
}


public extension URL {
     
    /// Creates an URL with a unique filename at the same directory by appending a unique number.
    ///
    /// - Parameters:
    ///   - format: The naming format.
    /// - Returns: A unique file URL, or `self` if it is already unique.
    func appendingUniqueNumber(format: NumberingFormat? = nil) -> URL {
        
        let format = format ?? NumberingFormat({ $0 }, numbered: { "\($0) \($1)" })
        let (baseName, count) = format.components(self.deletingPathExtension().lastPathComponent)
        let baseURL = self.deletingLastPathComponent()
        let pathExtension = self.pathExtension
        
        return (count...).lazy
            .map { format.filename(baseName, count: $0) }
            .map { baseURL.appending(component: $0).appendingPathExtension(pathExtension) }
            .first { !$0.isReachable }!
    }
}


extension NumberingFormat {
    
    /// Creates the filename.
    ///
    /// - Parameters:
    ///   - base: The base name.
    ///   - count: The number to append.
    /// - Returns: A filename.
    func filename(_ base: String, count: Int) -> String {
        
        (count < 2) ? self.format(base) : self.numberedFormat(base, count)
    }
    
    
    /// Parses the given name into the base part of the name and the suffix number.
    ///
    /// - Parameter name: The name.
    /// - Returns: The base part of the name and the suffix number.
    func components(_ name: String) -> (base: String, count: Int) {
        
        if let match = try? self.multiRegex.wholeMatch(in: name), let count = Int(match.count) {
            (String(match.base), count)
        } else if let match = try? self.singleRegex.wholeMatch(in: name) {
            (String(match.base), 1)
        } else {
            (name, 1)
        }
    }
    
    
    /// The regular expression for parsing a numbered name.
    private var multiRegex: Regex<(Substring, base: Substring, count: Substring)> {
        
        let pattern = NSRegularExpression.escapedPattern(for: self.numberedFormat("%@", 0))
            .replacing("%@", with: "(?<base>.+)")
            .replacing("0", with: "(?<count>[0-9]+)")
        
        return try! Regex(pattern)
    }
    
    
    /// The regular expression for parsing name.
    private var singleRegex: Regex<(Substring, base: Substring)> {
        
        let pattern = NSRegularExpression.escapedPattern(for: self.format("%@"))
            .replacing("%@", with: "(?<base>.+)")
        
        return try! Regex(pattern)
    }
}
