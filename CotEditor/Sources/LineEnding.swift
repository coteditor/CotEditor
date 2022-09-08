//
//  LineEnding.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-11-30.
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

enum LineEnding: Character, CaseIterable {
    
    case lf = "\n"
    case cr = "\r"
    case crlf = "\r\n"
    case nel = "\u{0085}"
    case lineSeparator = "\u{2028}"
    case paragraphSeparator = "\u{2029}"
    
    static let basicCases: [LineEnding] = [.lf, .cr, .crlf]
    
    
    var string: String {
        
        String(self.rawValue)
    }
    
    
    var length: Int {
        
        self.rawValue.unicodeScalars.count
    }
    
    
    var index: Int {
        
        Self.allCases.firstIndex(of: self)!
    }
    
    
    var name: String {
        
        switch self {
            case .lf:
                return "LF"
            case .cr:
                return "CR"
            case .crlf:
                return "CRLF"
            case .nel:
                return "NEL"
            case .lineSeparator:
                return "LS"
            case .paragraphSeparator:
                return "PS"
        }
    }
    
    
    var localizedName: String {
        
        switch self {
            case .lf:
                return "macOS / Unix (LF)".localized
            case .cr:
                return "Classic Mac OS (CR)".localized
            case .crlf:
                return "Windows (CRLF)".localized
            case .nel:
                return "Next Line (NEL)".localized
            case .lineSeparator:
                return "Unicode Line Separator (LS)".localized
            case .paragraphSeparator:
                return "Unicode Paragraph Separator (PS)".localized
        }
    }
    
}



// MARK: -

private extension LineEnding {
    
    var regexPattern: String {
        
        switch self {
            case .lf:
                return "(?<!\r)\n"
            case .cr:
                return "\r(?!\n)"
            default:
                return self.string
        }
    }
    
}


private extension BidirectionalCollection<LineEnding> {
    
    var regexPattern: String {
        
        assert(!self.isEmpty)
        assert(self.count == self.unique.count)
        
        let multiples = self.filter { $0.length > 1 }
        let singles = self.filter { $0.length == 1 }
        
        return (multiples + singles)
            .map { multiples.isEmpty ? $0.regexPattern : $0.string }
            .joined(separator: "|")
    }
    
}


extension StringProtocol {
    
    /// Return a new string in which all specified line ending characters in the receiver are replaced by another given line endings.
    ///
    /// - Parameters:
    ///     - lineEndings: The line endings type to replace. If nil, all kind of line endings are replaced.
    ///     - lineEnding: The line ending type with which to replace target.
    /// - Returns: String replacing line ending characers.
    func replacingLineEndings(_ lineEndings: [LineEnding]? = nil, with lineEnding: LineEnding) -> String {
        
        let lineEndings = lineEndings ?? LineEnding.allCases
        
        return self.replacingOccurrences(of: lineEndings.regexPattern, with: lineEnding.string, options: .regularExpression)
    }
    
}



extension String {
    
    /// Collect ranges of all line endings per line ending type from the beginning.
    ///
    /// - Parameters:
    ///     - range: The range to parse.
    /// - Returns: Ranges of line endings.
    func lineEndingRanges(in range: NSRange? = nil) -> [ItemRange<LineEnding>] {
        
        guard !self.isEmpty else { return [] }
        
        var lineEndingRanges: [ItemRange<LineEnding>] = []
        let string = self as NSString
        
        string.enumerateSubstrings(in: range ?? string.range, options: [.byLines, .substringNotRequired]) { (_, substringRange, enclosingRange, _) in
            guard !enclosingRange.isEmpty else { return }
            
            let lineEndingRange = NSRange(substringRange.upperBound..<enclosingRange.upperBound)
            
            guard
                !lineEndingRange.isEmpty,
                let lastCharacter = string.substring(with: lineEndingRange).first,  // line ending must be a single character
                let lineEnding = LineEnding(rawValue: lastCharacter)
            else { return }
            
            lineEndingRanges.append(.init(item: lineEnding, range: lineEndingRange))
        }
        
        return lineEndingRanges
    }
    
}



extension NSMutableAttributedString {
    
    /// Replace all line ending characters in the receiver with another given line endings.
    ///
    /// - Parameters:
    ///     - lineEndings: The line endings type to replace. If nil, all kind of line endings are replaced.
    ///     - newLineEnding: The line ending type with which to replace target.
    func replaceLineEndings(_ lineEndings: [LineEnding]? = nil, with newLineEnding: LineEnding) {
        
        let lineEndings = lineEndings ?? LineEnding.allCases
        
        self.mutableString.replaceOccurrences(of: lineEndings.regexPattern, with: newLineEnding.string, options: .regularExpression, range: self.range)
    }
    
}
