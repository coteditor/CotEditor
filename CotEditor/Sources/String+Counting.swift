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
//  © 2014-2022 1024jp
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

extension StringProtocol {
    
    /// The number of words in the whole string.
    var numberOfWords: Int {
        
        var count = 0
        self.enumerateSubstrings(in: self.startIndex..<self.endIndex, options: [.byWords, .localized, .substringNotRequired]) { (_, _, _, _) in
            count += 1
        }
        
        return count
    }
    
    
    /// The number of lines in the whole string including the last blank line.
    var numberOfLines: Int {
        
        return self.numberOfLines()
    }
    
    
    /// Calculate the line number at the given character index (1-based).
    ///
    /// - Parameter index: The character index.
    /// - Returns: The line number.
    func lineNumber(at index: Index) -> Int {
        
        guard !self.isEmpty, index > self.startIndex else { return 1 }
        
        return self.numberOfLines(in: self.startIndex..<index)
    }
    
    
    /// Count the number of lines in the given range including the last blank line.
    ///
    /// - Parameter range: The character range to count lines, or when `nil`, the entire range.
    /// - Returns: The number of lines.
    func numberOfLines(in range: Range<String.Index>? = nil) -> Int {
        
        let range = range ?? self.startIndex..<self.endIndex
        
        if self.isEmpty || range.isEmpty { return 0 }
        
        // workarond for a bug since Swift 5 that removes BOM at the beginning (2019-05 Swift 5.1).
        // cf. https://bugs.swift.org/browse/SR-10896
        guard !self.starts(with: "\u{FEFF}") || self.compareCount(with: 16) == .greater else {
            return self[range].count { $0.isNewline } + 1
        }
        
        var count = 0
        self.enumerateSubstrings(in: range, options: [.byLines, .substringNotRequired]) { (_, _, _, _) in
            count += 1
        }
        
        if self[range].last?.isNewline == true {
            count += 1
        }
        
        return count
    }
    
}



// MARK: NSRange based

extension String {
    
    /// Calculate the line number at the given character index (1-based).
    ///
    /// - Parameter location: The UTF16-baesd character index.
    /// - Returns: The line number.
    func lineNumber(at location: Int) -> Int {
        
        guard !self.isEmpty, location > 0 else { return 1 }
        
        return self.numberOfLines(in: NSRange(location: 0, length: location))
    }
    
    
    /// Count the number of lines in the given range including the last blank line.
    ///
    /// - Parameter range: The character range to count lines, or when `nil`, the entire range.
    /// - Returns: The number of lines.
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



// MARK: CharacterCountOptions

struct CharacterCountOptions {
    
    enum CharacterUnit: String {
        
        case graphemeCluster
        case unicodeScalar
        case utf16
        case byte
    }
    
    
    var unit: CharacterUnit = .graphemeCluster
    var normalizationForm: UnicodeNormalizationForm?
    var ignoresNewlines = false
    var ignoresWhitespaces = false
    var treatsConsecutiveWhitespaceAsSingle = false
    var encoding: String.Encoding = .utf8
}


extension String {
    
    func count(options: CharacterCountOptions) -> Int? {
        
        guard !self.isEmpty else { return 0 }
        
        var string = self
        
        if options.ignoresNewlines {
            string = string.replacingOccurrences(of: "\\R", with: "", options: .regularExpression)
        }
        if options.ignoresWhitespaces {
            string = string.replacingOccurrences(of: "[\\t\\p{Zs}]", with: "", options: .regularExpression)
        }
        if options.treatsConsecutiveWhitespaceAsSingle, (!options.ignoresNewlines || !options.ignoresWhitespaces) {
            // \s = [\t\n\f\r\p{Z}]
            string = string.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
        }
        
        if let normalizationForm = options.normalizationForm {
            string = string.normalize(in: normalizationForm)
        }
        
        switch options.unit {
            case .graphemeCluster:
                return string.count
            case .unicodeScalar:
                return string.unicodeScalars.count
            case .utf16:
                return string.utf16.count
            case .byte:
                return string.data(using: options.encoding)?.count
        }
    }
    
}
