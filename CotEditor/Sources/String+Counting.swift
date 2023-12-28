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
//  © 2014-2023 1024jp
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
        
        self.numberOfLines()
    }
    
    
    /// Calculates the line number at the given character index (1-based).
    ///
    /// - Parameter index: The character index.
    /// - Returns: The line number.
    func lineNumber(at index: Index) -> Int {
        
        guard !self.isEmpty, index > self.startIndex else { return 1 }
        
        return self.numberOfLines(in: self.startIndex..<index)
    }
    
    
    /// Counts the number of lines in the given range including the last blank line.
    ///
    /// - Parameter range: The character range to count lines, or when `nil`, the entire range.
    /// - Returns: The number of lines.
    func numberOfLines(in range: Range<String.Index>? = nil) -> Int {
        
        let range = range ?? self.startIndex..<self.endIndex
        
        if self.isEmpty || range.isEmpty { return 0 }
        
        var count = 0
        self.enumerateSubstrings(in: range, options: [.byLines, .substringNotRequired]) { (_, _, _, _) in
            count += 1
        }
        
        if self[range].last?.isNewline == true {
            count += 1
        }
        
        return count
    }
    
    
    /// Counts the number of lines in the given ranges including the last blank line.
    ///
    /// - Parameter ranges: The character ranges to count lines.
    /// - Returns: The number of lines.
    func numberOfLines(in ranges: [Range<String.Index>]) -> Int {
        
        assert(!ranges.isEmpty)
        
        if self.isEmpty || ranges.isEmpty { return 0 }
        
        // use simple count for efficiency
        if ranges.count == 1 {
            return self.numberOfLines(in: ranges[0])
        }
        
        // evaluate line ranges to avoid double-count lines holding multiple ranges
        var lineRanges: [Range<String.Index>] = []
        for range in ranges {
            let lineRange = self.lineRange(for: range)
            self.enumerateSubstrings(in: lineRange, options: [.byLines, .substringNotRequired]) { (_, substringRange, _, _) in
                lineRanges.append(substringRange)
            }
            
            if self[range].last?.isNewline == true {
                lineRanges.append(self.lineRange(at: range.upperBound))
            }
        }
        
        return lineRanges.unique.count
    }
    
    
    /// Calculates the number of characters from the beginning of the line where the given character index locates (0-based).
    ///
    /// - Parameter index: The character index.
    /// - Returns: The column number.
    func columnNumber(at index: Index) -> Int {
        
        self.distance(from: self.lineStartIndex(at: index), to: index)
    }
}



// MARK: NSRange based

extension String {
    
    /// Calculates the line number at the given character index (1-based).
    ///
    /// - Parameter location: The UTF16-based character index.
    /// - Returns: The line number.
    func lineNumber(at location: Int) -> Int {
        
        guard !self.isEmpty, location > 0 else { return 1 }
        
        return self.numberOfLines(in: NSRange(location: 0, length: location))
    }
    
    
    /// Counts the number of lines in the given range including the last blank line.
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
    
    enum CharacterUnit: String, CaseIterable {
        
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
    
    /// Counts string in the way described in the `option`.
    ///
    /// - Parameter options: The way to count.
    /// - Returns: Counted number, or nil if failed.
    func count(options: CharacterCountOptions) -> Int? {
        
        guard !self.isEmpty else { return 0 }
        
        var string = self
        
        if options.ignoresNewlines {
            string.replace(/\R/, with: "")
        }
        if options.ignoresWhitespaces {
            string.replace(/[\t\p{Zs}]/, with: "")
        }
        if options.treatsConsecutiveWhitespaceAsSingle, (!options.ignoresNewlines || !options.ignoresWhitespaces) {
            // \s = [\t\n\f\r\p{Z}]
            string.replace(/\s{2,}/, with: " ")
        }
        
        if let normalizationForm = options.normalizationForm {
            string = string.normalizing(in: normalizationForm)
        }
        
        switch options.unit {
            case .graphemeCluster:
                return string.count
            case .unicodeScalar:
                return string.unicodeScalars.count
            case .utf16:
                return string.utf16.count
            case .byte:
                guard string.canBeConverted(to: options.encoding) else { return nil }
                return string.lengthOfBytes(using: options.encoding)
        }
    }
}
