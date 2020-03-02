//
//  String+Counting.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-05-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
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

extension StringProtocol where Self.Index == String.Index {
    
    /// number of words in the whole string
    var numberOfWords: Int {
        
        var count = 0
        self.enumerateSubstrings(in: self.startIndex..<self.endIndex, options: [.byWords, .localized, .substringNotRequired]) { (_, _, _, _) in
            count += 1
        }
        
        return count
    }
    
    
    /// number of lines in the whole string including the last new line character
    var numberOfLines: Int {
        
        return self.numberOfLines()
    }
    
    
    /// count the number of lines at the character index (1-based).
    func lineNumber(at index: Self.Index) -> Int {
        
        guard !self.isEmpty, index > self.startIndex else { return 1 }
        
        return self.numberOfLines(in: self.startIndex..<index)
    }
    
    
    /// count the number of lines in the range
    func numberOfLines(in range: Range<String.Index>? = nil) -> Int {
        
        let range = range ?? self.startIndex..<self.endIndex
        
        if self.isEmpty || range.isEmpty { return 0 }
        
        // workarond for the Swift 5 issue that removes BOM at the beginning (2019-05 Swift 5.0).
        // cf. https://bugs.swift.org/browse/SR-10896
        guard self.first != "\u{FEFF}" || self.compareCount(with: 16) == .greater else {
            let substring = self[workaround: range]
            let count = substring.count { $0.isNewline } + 1
            
            return count
        }
        
        var count = 0
        self.enumerateSubstrings(in: range, options: [.byLines, .substringNotRequired]) { (_, _, _, _) in
            count += 1
        }
        
        if self[workaround: range].last?.isNewline == true {
            count += 1
        }
        
        return count
    }
    
}



// MARK: NSRange based

extension String {
    
    /// count the number of lines at the character index (1-based).
    func lineNumber(at location: Int) -> Int {
        
        guard !self.isEmpty, location > 0 else { return 1 }
        
        return self.numberOfLines(in: NSRange(location: 0, length: location))
    }
    
    
    /// count the number of lines in the range
    func numberOfLines(in range: NSRange? = nil) -> Int {
        
        let range = range ?? self.nsRange
        
        if self.isEmpty || range.isEmpty { return 0 }
        
        var count = 0
        (self as NSString).enumerateSubstrings(in: range, options: [.byLines, .substringNotRequired]) { (_, _, _, _) in
            count += 1
        }
        
        if (self as NSString).character(at: range.upperBound - 1).isNewline == true {
            count += 1
        }
        
        return count
    }
    
}
