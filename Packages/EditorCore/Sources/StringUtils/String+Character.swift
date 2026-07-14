//
//  String+Character.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-07-13.
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

public extension String {
    
    /// Returns the character just before the given range.
    ///
    /// - Parameter range: The range to inspect.
    /// - Returns: The character just before `range`, or `nil` if the range starts at the beginning.
    func character(before range: NSRange) -> Unicode.Scalar? {
        
        guard range.lowerBound > 0 else { return nil }
        
        let index = String.UnicodeScalarIndex(utf16Offset: range.lowerBound - 1, in: self)
        
        return index < self.unicodeScalars.endIndex ? self.unicodeScalars[index] : nil
    }
    
    
    /// Returns the character just after the given range.
    ///
    /// - Parameter range: The range to inspect.
    /// - Returns: The character just after `range`, or `nil` if no character follows it.
    func character(after range: NSRange) -> Unicode.Scalar? {
        
        let index = String.UnicodeScalarIndex(utf16Offset: range.upperBound, in: self)
        
        return index < self.unicodeScalars.endIndex ? self.unicodeScalars[index] : nil
    }
}
