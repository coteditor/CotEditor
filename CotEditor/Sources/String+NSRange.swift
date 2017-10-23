/*
 
 String+NSRange.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-25.
 
 ------------------------------------------------------------------------------
 
 © 2016-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

extension String {
    
    /// whole range in NSRange
    var nsRange: NSRange {
        
        return NSRange(self.startIndex..<self.endIndex, in: self)
    }
    
}



extension NSRange {
    
    static let notFound = NSRange(location: NSNotFound, length: 0)
}



extension NSString {
    
    var range: NSRange {
        
        return NSRange(location: 0, length: self.length)
    }
    
    
    /// line range containing a given location
    func lineRange(at location: Int) -> NSRange {
        
        return self.lineRange(for: NSRange(location: location, length: 0))
    }
    
    
    /// line range adding ability to exclude last line ending character if exists
    func lineRange(for range: NSRange, excludingLastLineEnding: Bool) -> NSRange {
        
        var lineRange = self.lineRange(for: range)
        
        guard excludingLastLineEnding else { return lineRange }
        
        // ignore last line ending
        if lineRange.length > 0, self.character(at: lineRange.upperBound - 1) == "\n".utf16.first! {
            lineRange.length -= 1
        }
        
        return lineRange
    }
}
