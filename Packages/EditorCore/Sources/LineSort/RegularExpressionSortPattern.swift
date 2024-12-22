//
//  RegularExpressionSortPattern.swift
//  LineSort
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2024 1024jp
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

public struct RegularExpressionSortPattern: SortPattern, Equatable, Sendable {
    
    public var searchPattern: String
    public var ignoresCase: Bool
    public var usesCaptureGroup: Bool
    public var group: Int
    
    public var numberOfCaptureGroups: Int  { (try? self.regex)?.numberOfCaptureGroups ?? 0 }
    
    
    public init(searchPattern: String = "", ignoresCase: Bool = true, usesCaptureGroup: Bool = false, group: Int = 1) {
        
        self.searchPattern = searchPattern
        self.ignoresCase = ignoresCase
        self.usesCaptureGroup = usesCaptureGroup
        self.group = group
    }
    
    
    // MARK: Sort Pattern Methods
    
    public func sortKey(for line: String) -> String? {
        
        guard let range = self.range(for: line) else { return nil }
        
        return String(line[range])
    }
    
    
    public func range(for line: String) -> Range<String.Index>? {
        
        guard
            let regex = try? self.regex,
            let match = regex.firstMatch(in: line, range: line.nsRange)
        else { return nil }
        
        if self.usesCaptureGroup {
            guard match.numberOfRanges > self.group else { return nil }
            return Range(match.range(at: self.group), in: line)
        } else {
            return Range(match.range, in: line)
        }
    }
    
    
    /// Tests the regular expression pattern is valid.
    public func validate() throws(SortPatternError) {
        
        if self.searchPattern.isEmpty {
            throw .emptyPattern
        }
        
        do {
            _ = try self.regex
        } catch {
            throw .invalidRegularExpressionPattern
        }
    }
    
    
    // MARK: Private Methods
    
    private var regex: NSRegularExpression? {
        
        get throws {
            try NSRegularExpression(pattern: self.searchPattern, options: self.ignoresCase ? [.caseInsensitive] : [])
        }
    }
}
