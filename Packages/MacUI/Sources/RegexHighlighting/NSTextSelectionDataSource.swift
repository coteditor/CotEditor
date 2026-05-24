//
//  NSTextSelectionDataSource.swift
//  RegexHighlighting
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-06-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2026 1024jp
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

extension NSTextSelectionDataSource {
    
    /// Converts the given text range to a character range.
    ///
    /// - Parameters:
    ///   - textRange: The text range to convert.
    /// - Returns: A character range, or `nil` if the given range is invalid for the content text.
    func range(for textRange: NSTextRange) -> NSRange? {
        
        let location = self.offset(from: self.documentRange.location, to: textRange.location)
        let length = self.offset(from: textRange.location, to: textRange.endLocation)
        
        guard location != NSNotFound, length != NSNotFound else { return nil }
        
        return NSRange(location: location, length: length)
    }
    
    
    /// Converts the given character range to a text range.
    ///
    /// - Parameters:
    ///   - range: The character range to convert.
    /// - Returns: A text range, or `nil` if the given range is invalid for the content text.
    func textRange(for range: NSRange) -> NSTextRange? {
        
        guard
            let location = self.location(self.documentRange.location, offsetBy: range.location),
            let end = self.location(location, offsetBy: range.length)
        else { return nil }
        
        return NSTextRange(location: location, end: end)
    }
}
