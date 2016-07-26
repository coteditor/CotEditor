/*
 
 String+NSRange.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-25.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

extension String {
    
    // convert NSRange to Range<Index>
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        
        guard let start16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let end16 = utf16.index(start16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let start = String.Index(start16, within: self),
            let end = String.Index(end16, within: self)
            else { return nil }
        
        return start ..< end
    }
    
    
    func nsRange(from range: Range<String.Index>) -> NSRange {
        
        let start = range.lowerBound.samePosition(in: self.utf16)
        let end = range.upperBound.samePosition(in: self.utf16)
        
        return NSRange(location: self.utf16.distance(from: self.utf16.startIndex, to: start),
                       length: self.utf16.distance(from: start, to: end))
    }
    
    
    /// whole range in NSRange
    var nsRange: NSRange {
        return NSRange(location: 0, length: self.utf16.count)
    }
    
}


extension NSRange: Equatable {
    
    /// syntax sugar of NSMaxRange
    var max: Int {
        return NSMaxRange(self)
    }
}

public func ==(lhs: NSRange, rhs: NSRange) -> Bool {
    
    return NSEqualRanges(lhs, rhs)
}


extension NSString {
    
    var range: NSRange {
        return NSRange(location: 0, length: self.length)
    }
    
    
    /// line range adding ability to exclude last line ending character if exists
    func lineRange(for range: NSRange, excludingLastLineEnding: Bool) -> NSRange {
        
        var lineRange = self.lineRange(for: range)
        
        guard excludingLastLineEnding else { return lineRange }
        
        // ignore last line ending
        if self.character(at: lineRange.max - 1) == "\n".utf16.first! {
            lineRange.length -= 1
        }
        
        return lineRange
    }
    
}


let NotFoundRange = NSRange(location: NSNotFound, length: 0)
