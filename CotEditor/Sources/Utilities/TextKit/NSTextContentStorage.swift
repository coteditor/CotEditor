//
//  NSTextContentStorage.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-08-05.
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

import AppKit

extension NSTextContentManager {
    
    /// Converts the given text location to a character index.
    ///
    /// - Parameters:
    ///   - textLocation: The text location to convert.
    /// - Returns: A character position.
    func location(for textLocation: some NSTextLocation) -> Int {
        
        self.offset(from: self.documentRange.location, to: textLocation)
    }
    
    
    /// Converts the given character index into a text location.
    ///
    /// - Parameters:
    ///   - location: The character index to convert.
    /// - Returns: A text location.
    func textLocation(for location: Int) -> (any NSTextLocation)? {
        
        self.location(self.documentRange.location, offsetBy: location)
    }
    
    
    /// Converts the given text range to a character range.
    ///
    /// - Parameters:
    ///   - textRange: The text range to convert.
    /// - Returns: A character range.
    func range(for textRange: NSTextRange) -> NSRange {
        
        NSRange(location: self.offset(from: self.documentRange.location, to: textRange.location),
                length: self.offset(from: textRange.location, to: textRange.endLocation))
    }
    
    
    /// Converts the given character range to a text range.
    ///
    /// - Parameters:
    ///   - range: The character range to convert.
    /// - Returns: A text range, or `nil` if the given range is invalid for the content text.
    func textRange(for range: NSRange) -> NSTextRange? {
        
        guard
            let start = self.location(self.documentRange.location, offsetBy: range.location),
            let end = self.location(start, offsetBy: range.length)
        else { return nil }
        
        return NSTextRange(location: start, end: end)
    }
}
