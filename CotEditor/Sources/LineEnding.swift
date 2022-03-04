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
                return "Unicode Next Line (NEL)".localized
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


private extension BidirectionalCollection where Element == LineEnding {
    
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


extension StringProtocol where Self.Index == String.Index {
    
    /// The dominated line ending type.
    var detectedLineEnding: LineEnding? {
        
        self.countLineEndings(maximum: 3).firstMaxElement
    }
    
    
    /// Count characters in the receiver but except all kinds of line endings.
    var countExceptLineEnding: Int {
        
        // workarond for a bug since Swift 5 that removes BOM at the beginning (2019-05 Swift 5.1).
        // cf. https://bugs.swift.org/browse/SR-10896
        guard self.first != "\u{FEFF}" || self.compareCount(with: 16) == .greater else {
            let startIndex = self.index(after: self.startIndex)
            return self[startIndex...].replacingOccurrences(of: LineEnding.allCases.regexPattern, with: "", options: .regularExpression).count + 1
        }
        
        return self.replacingOccurrences(of: LineEnding.allCases.regexPattern, with: "", options: .regularExpression).count
    }
    
    
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
    
    
    /// Count the line endings in the receiver from the beginning.
    ///
    /// - Parameter maximum: If specified, the count stops when a count of any type of line endings first reaches the given value.
    /// - Returns: A counter object.
    private func countLineEndings(maximum: Int? = nil) -> OrderedCounter<LineEnding> {
        
        var counter = OrderedCounter<LineEnding>()
        
        guard !self.isEmpty else { return counter }
        
        self.enumerateSubstrings(in: self.startIndex..., options: [.byLines, .substringNotRequired]) { (_, substringRange, enclosingRange, stop) in
            guard
                !enclosingRange.isEmpty,
                let lastCharacter = self[safe: substringRange.upperBound],
                let lineEnding = LineEnding(rawValue: lastCharacter)
            else { return }
            
            counter.append(lineEnding)
            
            if let maximum = maximum, counter.count(lineEnding) >= maximum {
                stop = true
            }
        }
        
        return counter
    }
    
    
    /// Convert passed-in range as if line endings are changed from `fromLineEnding` to `toLineEnding`
    /// by assuming the receiver has `fromLineEnding` regardless of actual ones if specified.
    ///
    /// - Important: Consider to avoid using this method in a frequent loop as it's relatively heavy.
    func convert(range: NSRange, from fromLineEnding: LineEnding, to toLineEnding: LineEnding) -> NSRange {
        
        self.convert(ranges: [range], from: fromLineEnding, to: toLineEnding)[0]
    }
    
    
    /// Convert passed-in ranges as if line endings are changed from `fromLineEnding` to `toLineEnding`
    /// by assuming the receiver has `fromLineEnding` regardless of actual ones if specified.
    func convert(ranges: [NSRange], from fromLineEnding: LineEnding, to toLineEnding: LineEnding) -> [NSRange] {
        
        assert(!ranges.contains(.notFound))
        
        let delta = toLineEnding.length - fromLineEnding.length
        
        guard delta != 0, !ranges.isEmpty else { return ranges }
        
        let upperBound = ranges.map(\.upperBound).max()!
        let lineEndingRanges = (self.replacingLineEndings(with: fromLineEnding) as NSString)
            .ranges(of: fromLineEnding.string, range: NSRange(location: 0, length: upperBound))
        
        return ranges.map { range in
            let locationCount = lineEndingRanges.countPrefix { $0.lowerBound < range.lowerBound }
            let lengthCount = lineEndingRanges[locationCount...].countPrefix { $0.upperBound <= range.upperBound }
            
            return NSRange(location: range.location + locationCount * delta,
                           length: range.length + lengthCount * delta)
        }
    }
    
}
