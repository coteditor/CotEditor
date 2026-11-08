//
//  CSVSortPattern.swift
//  LineSort
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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
import StringUtils

public struct CSVSortPattern: SortPattern, Equatable, Sendable {
    
    public var delimiter: String
    public var column: Int
    
    
    public init(delimiter: String = ",", column: Int = 1) {
        
        self.delimiter = delimiter
        self.column = column
    }
    
    
    // MARK: Sort Pattern Methods
    
    public func sortKey(for line: String) -> String? {
        
        assert(self.column > 0)
        
        let delimiter = self.delimiter.isEmpty ? "," : self.delimiter.unescaped
        let index = self.column - 1  // column number is 1-based
        let components = line.split(separator: delimiter, omittingEmptySubsequences: false)
        
        guard components.indices.contains(index) else { return nil }
        
        return components[index].trimmingCharacters(in: .whitespaces)
    }
    
    
    public func range(for line: String) -> Range<String.Index>? {
        
        assert(self.column > 0)
        
        let delimiter = self.delimiter.isEmpty ? "," : self.delimiter.unescaped
        let index = self.column - 1  // column number is 1-based
        let components = line.split(separator: delimiter, omittingEmptySubsequences: false)
        
        guard components.indices.contains(index) else { return nil }
        
        let component = components[index]
        
        guard !component.isEmpty else { return component.startIndex..<component.endIndex }
        
        // trim whitespace in the same way as `sortKey(for:)`
        let scalars = component.unicodeScalars
        guard
            let lowerBound = scalars.firstIndex(where: { !CharacterSet.whitespaces.contains($0) }),
            let lastIndex = scalars.lastIndex(where: { !CharacterSet.whitespaces.contains($0) })
        else { return nil }  // component contains only whitespace
        
        return lowerBound..<scalars.index(after: lastIndex)
    }
    
    
    public func validate() throws(SortPatternError) { }
}
