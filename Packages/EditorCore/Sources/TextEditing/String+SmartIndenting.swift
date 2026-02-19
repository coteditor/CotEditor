//
//  String+SmartIndenting.swift
//  TextEditing
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

public import Foundation
public import StringUtils

public enum IndentToken: Equatable, Sendable {
    
    case tokenPair(Pair<String>)
    case symbolPair(Pair<Character>)
    case beginToken(String)
    
    
    public init?(pair: Pair<String>) {
        
        let begin = pair.begin.trimmingCharacters(in: .whitespacesAndNewlines)
        let end = pair.end.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if begin.isEmpty {
            return nil
            
        } else if end.isEmpty {
            self = .beginToken(begin)
            
        } else if begin.count == 1, end.count == 1,
                  let beginCharacter = begin.first, let endCharacter = end.first,
                  beginCharacter.isPunctuation, endCharacter.isPunctuation
        {
            self = .symbolPair(Pair(beginCharacter, endCharacter))
            
        } else {
            self = .tokenPair(pair)
        }
    }
    
    
    var characters: BracePair? {
        
        switch self {
            case .tokenPair: nil
            case .symbolPair(let pair): pair
            case .beginToken: nil
        }
    }
    
    
    var begin: String {
        
        switch self {
            case .tokenPair(let pair): pair.begin
            case .symbolPair(let pair): String(pair.begin)
            case .beginToken(let string): string
        }
    }
    
    
    var end: String? {
        
        switch self {
            case .tokenPair(let pair): pair.end
            case .symbolPair(let pair): String(pair.end)
            case .beginToken: nil
        }
    }
}


public extension String {
    
    /// Computes auto-indentation strings and insertion positions for newline insertion.
    ///
    /// - Note: Ranges without a line ending immediately before them are ignored.
    ///
    /// - Parameters:
    ///   - style: The indentation style to apply.
    ///   - indentWidth: The number of characters for the indentation.
    ///   - tokens: The tokens to determine indentation behavior.
    ///   - selectedRanges: The selection in the editor.
    /// - Returns: An `EditingContext` that inserts line endings and indentation, or `nil` if no indentation is required.
    func smartIndent(style: IndentStyle, indentWidth: Int, tokens: [IndentToken] = [], in selectedRanges: [NSRange]) -> EditingContext? {
        
        assert(indentWidth > 0)
        
        var indents: [String] = []
        var replacementRanges: [NSRange] = []
        var newSelectedRanges: [NSRange] = []
        var offset = 0
        
        for selectedRange in selectedRanges {
            guard let lineEnding = self.lineEndingString(before: selectedRange.location) else {
                let range = NSRange(location: selectedRange.lowerBound + offset, length: 0)
                newSelectedRanges.append(range)
                assertionFailure()
                continue
            }
            
            let lastLocation = selectedRange.location - lineEnding.length
            let baseIndent = if let indentRange = self.rangeOfIndent(at: lastLocation) {
                (self as NSString).substring(with: indentRange)
            } else {
                ""
            }
            var indent = baseIndent
            var cursorMove = baseIndent.count
            
            // smart indent
            let candidates = tokens.filter { self.matches(token: $0.begin, before: lastLocation) }
            if !candidates.isEmpty {
                let tab = style.string(width: indentWidth)
                
                if candidates.compactMap(\.end)
                    .contains(where: { self.matches(token: $0, after: selectedRange.upperBound) })
                {
                    indent += tab + lineEnding + baseIndent
                    cursorMove += tab.count
                } else {
                    indent += tab
                    cursorMove += tab.count
                }
            }
            
            // calculate insertion
            let range = NSRange(location: selectedRange.lowerBound, length: 0)
            if !indent.isEmpty {
                indents.append(indent)
                replacementRanges.append(range)
            }
            newSelectedRanges.append(range.shifted(by: cursorMove + offset))
            
            offset += indent.length
        }
        
        guard !indents.isEmpty else { return nil }
        
        return EditingContext(strings: indents, ranges: replacementRanges, selectedRanges: newSelectedRanges)
    }
    
    
    /// Returns how many indent levels should be reduced when inserting a closing token.
    ///
    /// - Parameters:
    ///   - string: The inserted string to evaluate.
    ///   - indentWidth: The number of characters for the indentation.
    ///   - tokens: The tokens to determine indentation behavior.
    ///   - range: The insertion range in the receiver.
    /// - Returns: The number of indent levels to reduce.
    func smartOutdentLevel(with string: String, indentWidth: Int, tokens: [IndentToken] = [], in range: NSRange) -> Int {
        
        assert(indentWidth > 0)
        
        guard
            let pair = tokens.compactMap(\.characters).first(where: { String($0.end) == string })
        else { return 0 }
        
        let insertionIndex = String.Index(utf16Offset: range.upperBound, in: self)
        let lineRange = self.lineRange(at: insertionIndex)
        
        // decrease indent level if the line is consists of only whitespace
        guard
            self[lineRange].starts(with: /[ \t]+\R?$/),
            let precedingIndex = self.indexOfBracePair(endIndex: insertionIndex, pair: pair)
        else { return 0 }
        
        let desiredLevel = self.indentLevel(at: precedingIndex, tabWidth: indentWidth)
        let currentLevel = self.indentLevel(at: insertionIndex, tabWidth: indentWidth)
        let levelToReduce = currentLevel - desiredLevel
        
        return max(levelToReduce, 0)
    }
}


extension NSString {
    
    /// Returns the line ending string immediately before the given character index.
    ///
    /// - Parameter location: The UTF-16 location just after the line ending.
    /// - Returns: The line ending string, or `nil` if not found.
    func lineEndingString(before location: Int) -> String? {
        
        guard location > 0 else { return nil }
        
        let character = self.character(at: location - 1)
        
        return switch character {
            case 0xA:
                (location >= 2 && self.character(at: location - 2) == 0xD) ? "\r\n" : "\n"
            case 0xD, 0x85, 0x2028, 0x2029:
                UnicodeScalar(character).map(String.init)
            default:
                nil
        }
    }
    
    
    /// Returns whether the given token matches the string just before the location.
    ///
    /// - Parameters:
    ///   - token: The token string to match.
    ///   - location: The UTF-16 location just after the target character.
    /// - Returns: `true` if the token matches; otherwise `false`.
    func matches(token: String, before location: Int) -> Bool {
        
        guard location > 0 else { return false }
        
        let range = NSRange(0..<location)
        let foundRange = if token.first?.isLetter == true {
            self.range(of: "(?<![A-Za-z0-9_])\(NSRegularExpression.escapedPattern(for: token))$",
                       options: .regularExpression, range: range)
        } else {
            self.range(of: token, options: [.anchored, .backwards], range: range)
        }
        
        return !foundRange.isNotFound
    }
    
    
    /// Returns whether the given token matches the string just after the location.
    ///
    /// - Parameters:
    ///   - token: The token string to match.
    ///   - location: The UTF-16 location just before the target character.
    /// - Returns: `true` if the token matches; otherwise `false`.
    func matches(token: String, after location: Int) -> Bool {
        
        guard location < self.length else { return false }
        
        let range = NSRange(location..<self.length)
        let foundRange = if token.last?.isLetter == true {
            self.range(of: "^\(NSRegularExpression.escapedPattern(for: token))(?![A-Za-z0-9_])",
                       options: .regularExpression, range: range)
        } else {
            self.range(of: token, options: [.anchored], range: range)
        }
        
        return !foundRange.isNotFound
    }
}
