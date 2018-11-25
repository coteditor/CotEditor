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
//  © 2014-2018 1024jp
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

enum LineEnding: Character {
    
    case lf = "\n"
    case cr = "\r"
    case crlf = "\r\n"
    case lineSeparator = "\u{2028}"
    case paragraphSeparator = "\u{2029}"
    
    static let basic: [LineEnding] = [.cr, .cr, .crlf]
    
    static let characterSet = CharacterSet(charactersIn: "\n\r\u{2028}\u{2029}")
    
    
    var string: String {
        
        return String(self.rawValue)
    }
    
    
    var name: String {
        
        switch self {
        case .lf:
            return "LF"
        case .cr:
            return "CR"
        case .crlf:
            return "CRLF"
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
        case .lineSeparator:
            return "Unix Line Separator".localized
        case .paragraphSeparator:
            return "Unix Paragraph Separator".localized
        }
    }
    
    
    var length: Int {
        
        return self.string.unicodeScalars.count
    }
    
}



// MARK: -

private let lineEndingsRegexPattern = "\\r\\n|[\\n\\r\\u2028\\u2029]"

extension StringProtocol where Self.Index == String.Index {
    
    /// return the first line ending type
    var detectedLineEnding: LineEnding? {
        
        guard !self.isEmpty else { return nil }
        
        // We don't use `CharacterSet.newlines` because it contains more characters than we need.
        guard let range = self.rangeOfCharacter(from: LineEnding.characterSet) else { return nil }
        let character = self[range.lowerBound]
        // -> This is enough because Swift (at least Swift 3) treats "\r\n" as a single character.
        
        return LineEnding(rawValue: character)
    }
    
    
    /// remove all kind of line ending characters in string
    var removingLineEndings: String {
        
        return self.replacingOccurrences(of: lineEndingsRegexPattern, with: "", options: .regularExpression)
    }
    
    
    /// replace all kind of line ending characters in the string with the desired line ending.
    func replacingLineEndings(with lineEnding: LineEnding) -> String {
        
        return self.replacingOccurrences(of: lineEndingsRegexPattern, with: lineEnding.string, options: .regularExpression)
    }
    
    
    /// convert passed-in range as if line endings are changed from fromLineEnding to toLineEnding
    /// assuming the receiver has `fromLineEnding` regardless of actual ones if specified
    ///
    /// - Important: Consider to avoid using this method in a frequent loop as it's relatively heavy.
    func convert(from fromLineEnding: LineEnding? = nil, to toLineEnding: LineEnding, range: NSRange) -> NSRange {
        
        guard let currentLineEnding = (fromLineEnding ?? self.detectedLineEnding) else { return range }
        
        let delta = toLineEnding.length - currentLineEnding.length
        
        guard delta != 0 else { return range }
        
        let string = self.replacingLineEndings(with: currentLineEnding)
        let regex = try! NSRegularExpression(pattern: lineEndingsRegexPattern)
        let locationRange = NSRange(location: 0, length: range.location)
        
        let locationDelta = delta * regex.numberOfMatches(in: string, range: locationRange)
        let lengthDelta = delta * regex.numberOfMatches(in: string, range: range)
        
        return NSRange(location: range.location + locationDelta, length: range.length + lengthDelta)
    }
    
}
