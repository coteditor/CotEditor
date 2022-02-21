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
    
    static let regexPattern = "\\r\\n|[\\n\\r\\u0085\\u2028\\u2029]"
}


extension StringProtocol where Self.Index == String.Index {
    
    /// The first line ending type.
    var detectedLineEnding: LineEnding? {
        
        guard let range = self.range(of: LineEnding.regexPattern, options: .regularExpression) else { return nil }
        
        // -> Swift treats "\r\n" also as a single character.
        let character = self[range.lowerBound]
        
        return LineEnding(rawValue: character)
    }
    
    
    /// Count characters in the receiver but except all kinds of line endings.
    var countExceptLineEnding: Int {
        
        // workarond for a bug since Swift 5 that removes BOM at the beginning (2019-05 Swift 5.1).
        // cf. https://bugs.swift.org/browse/SR-10896
        guard self.first != "\u{FEFF}" || self.compareCount(with: 16) == .greater else {
            let startIndex = self.index(after: self.startIndex)
            return self[startIndex...].replacingOccurrences(of: LineEnding.regexPattern, with: "", options: .regularExpression).count + 1
        }
        
        return self.replacingOccurrences(of: LineEnding.regexPattern, with: "", options: .regularExpression).count
    }
    
    
    /// String replacing all kind of line ending characters in the the receiver with the desired line ending.
    ///
    /// - Parameter lineEnding: The line ending type to replace with.
    /// - Returns: String replacing line ending characers.
    func replacingLineEndings(with lineEnding: LineEnding) -> String {
        
        return self.replacingOccurrences(of: LineEnding.regexPattern, with: lineEnding.string, options: .regularExpression)
    }
    
    
    /// Convert passed-in range as if line endings are changed from `fromLineEnding` to `toLineEnding`
    /// by assuming the receiver has `fromLineEnding` regardless of actual ones if specified.
    ///
    /// - Important: Consider to avoid using this method in a frequent loop as it's relatively heavy.
    func convert(range: NSRange, from fromLineEnding: LineEnding? = nil, to toLineEnding: LineEnding) -> NSRange {
        
        guard let currentLineEnding = (fromLineEnding ?? self.detectedLineEnding) else { return range }
        
        let delta = toLineEnding.length - currentLineEnding.length
        
        guard delta != 0 else { return range }
        
        let string = self.replacingLineEndings(with: currentLineEnding)
        let regex = try! NSRegularExpression(pattern: currentLineEnding.string)
        let locationRange = NSRange(location: 0, length: range.location)
        
        let locationDelta = delta * regex.numberOfMatches(in: string, range: locationRange)
        let lengthDelta = delta * regex.numberOfMatches(in: string, range: range)
        
        return NSRange(location: range.location + locationDelta, length: range.length + lengthDelta)
    }
    
}
