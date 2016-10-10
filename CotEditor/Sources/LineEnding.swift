/*
 
 LineEnding.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-11-30.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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

enum LineEnding: Character {
    
    case LF = "\n"
    case CR = "\r"
    case CRLF = "\r\n"
    case lineSeparator = "\u{2028}"
    case paragraphSeparator = "\u{2029}"
    
    static let basic: [LineEnding] = [.LF, .CR, .CRLF]
    
    static let characterSet = CharacterSet(charactersIn: "\n\r\u{2028}\u{2029}")
    
    
    var string: String {
        
        return String(self.rawValue)
    }
    
    
    var name: String {
        
        switch self {
        case .LF:
            return "LF"
        case .CR:
            return "CR"
        case .CRLF:
            return "CR/LF"
        case .lineSeparator:
            return "LS"
        case .paragraphSeparator:
            return "PS"
        }
    }
    
    
    var localizedName: String {
        
        switch self {
        case .LF:
            return NSLocalizedString("macOS / Unix (LF)", comment: "")
        case .CR:
            return NSLocalizedString("Classic Mac OS (CR)", comment: "")
        case .CRLF:
            return NSLocalizedString("Windows (CR/LF)", comment: "")
        case .lineSeparator:
            return NSLocalizedString("Unix Line Separator", comment: "")
        case .paragraphSeparator:
            return NSLocalizedString("Unix Paragraph Separator", comment: "")
        }
    }
    
}



// MARK: -

extension String {
    
    /// return the first line ending type
    var detectedLineEnding: LineEnding? {
        
        guard !self.isEmpty else { return nil }
        
        // We don't use `CharacterSet.newlines` because it contains more characters than we need.
        guard let range = self.rangeOfCharacter(from: LineEnding.characterSet) else { return nil }
        let character = self.characters[range.lowerBound]
        // -> This is enough because Swift (at least Swift 3-beta) treats "\r\n" as single character.
        
        return LineEnding(rawValue: character)
    }
    
    
    /// remove all kind of line ending characters in string
    var removingLineEndings: String {
        
        return self.replacingLineEndings(with: nil)
    }
    
    
    /// replace all kind of line ending characters in the string with the desired line ending.
    func replacingLineEndings(with lineEnding: LineEnding?) -> String {
        
        let regex = try! NSRegularExpression(pattern: "\\r\\n|[\\n\\r\\u2028\\u2029]")
        let template = lineEnding?.string ?? ""
        
        return regex.stringByReplacingMatches(in: self, range: self.nsRange, withTemplate: template)
    }
    
    
    /// convert passed-in range as if line endings are changed from fromLineEnding to toLineEnding
    func convert(from fromLineEnding: LineEnding? = nil, to toLineEnding: LineEnding, range: NSRange) -> NSRange {
        
        guard let currentLineEnding = (fromLineEnding ?? self.detectedLineEnding) else { return range }
        
        guard currentLineEnding.string.unicodeScalars.count != toLineEnding.string.unicodeScalars.count else { return range }
        
        let locationString = (self as NSString).substring(to: range.location).replacingLineEndings(with: toLineEnding)
        let lengthString = (self as NSString).substring(with: range).replacingLineEndings(with: toLineEnding)
        
        return NSRange(location: locationString.utf16.count, length: lengthString.utf16.count)
    }
    
}
