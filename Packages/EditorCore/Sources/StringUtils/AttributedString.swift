//
//  AttributedString.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

public import Foundation

public extension AttributedString {
    
    /// Truncates the head with an ellipsis until the specified `index` if the length before `index` exceeds `offset`.
    ///
    /// - Parameters:
    ///   - index: The character index at which truncation should start.
    ///   - offset: The maximum number of characters to leave to the left of `index`.
    /// - Returns: The truncated attributed string.
    func truncatedHead(until index: Index, offset: Int) -> AttributedString {
        
        var string = self
        string.truncateHead(until: index, offset: offset)
        
        return string
    }
    
    
    /// Truncates the head with an ellipsis until the specified `index` if the length before `index` exceeds `offset`.
    ///
    /// - Parameters:
    ///   - index: The character index at which truncation should start.
    ///   - offset: The maximum number of characters to leave to the left of `index`.
    mutating func truncateHead(until index: Index, offset: Int) {
        
        precondition(offset >= 0)
        
        let length = self.characters.distance(from: self.startIndex, to: index)
        
        guard length > offset else { return }
        
        let truncationIndex = self.characters.index(index, offsetBy: -offset)
        
        self.removeSubrange(..<truncationIndex)
        self.insert(AttributedString("…"), at: self.startIndex)
    }
}


public extension String {
    
    /// Truncates the head with an ellipsis until the specified `index` if the length before `index` exceeds `offset`.
    ///
    /// - Parameters:
    ///   - index: The character index at which truncation should start.
    ///   - offset: The maximum number of characters to leave to the left of `index`.
    /// - Returns: The truncated string.
    func truncatedHead(until index: Index, offset: Int) -> String {
        
        var string = self
        string.truncateHead(until: index, offset: offset)
        
        return string
    }
    
    
    /// Truncates the head with an ellipsis until the specified `index` if the length before `index` exceeds `offset`.
    ///
    /// - Parameters:
    ///   - index: The character index at which truncation should start.
    ///   - offset: The maximum number of characters to leave to the left of `index`.
    mutating func truncateHead(until index: Index, offset: Int) {
        
        precondition(offset >= 0)
        
        let length = self.distance(from: self.startIndex, to: index)
        
        guard length > offset else { return }
        
        let truncationIndex = self.index(index, offsetBy: -offset)
        
        self.removeSubrange(..<truncationIndex)
        self.insert("…", at: self.startIndex)
    }
}
