//
//  RegularExpressionSyntaxType.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2022 1024jp
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

import Foundation.NSRegularExpression

enum RegularExpressionParseMode {
    
    case search
    case replacement(unescapes: Bool)
}



enum RegularExpressionSyntaxType: CaseIterable {
    
    case character
    case backReference
    case symbol
    case quantifier
    case anchor
    
    
    // MARK: Public Methods
    
    func ranges(in string: String, mode: RegularExpressionParseMode = .search) -> [NSRange] {
        
        var ranges = self.patterns(for: mode)
            .map { try! NSRegularExpression(pattern: $0) }
            .flatMap { $0.matches(in: string, range: string.nsRange) }
            .map(\.range)
        
        if case .search = mode {
            switch self {
                case .character:
                    ranges += string.rangesForRegularExpressionBrackets(includingSymbols: false)
                case .symbol:
                    ranges += string.rangesForRegularExpressionBrackets(includingSymbols: true)
                default: break
            }
        }
        
        return ranges
    }
    
    
    
    // MARK: Private Methods
    
    private func patterns(for mode: RegularExpressionParseMode) -> [String] {
        
        // regex pattern to avoid matching escaped character
        let escapeIgnorer = "(?<!\\\\)(?:\\\\\\\\)*"
        
        switch mode {
            case .search:
                switch self {
                    case .character:
                        // -> [abc] will be extracted in ranges(in:) since regex cannot parse nested []
                        return [
                            escapeIgnorer + "\\.",  // .
                            escapeIgnorer + "\\\\" + "[^AbGkZzQE1-9]",  // all escaped characters
                            escapeIgnorer + "\\\\" + "[sdDefnrsStwWX]",  // \s, \d, ...
                            escapeIgnorer + "\\\\" + "v",  // \v
                            escapeIgnorer + "\\\\" + "\\\\",  // \\
                            escapeIgnorer + "\\\\" + "c[a-z]",  // \cX (control)
                            escapeIgnorer + "\\\\" + "N\\{[a-zA-Z0-9 ]+\\}",  // \N{UNICODE CHARACTER NAME}
                            escapeIgnorer + "\\\\" + "[pP]\\{[a-zA-Z0-9 ]+\\}",  // \p{UNICODE PROPERTY NAME}
                            escapeIgnorer + "\\\\" + "u[0-9a-fA-F]{4}",  // \uhhhh (h: hex)
                            escapeIgnorer + "\\\\" + "U[0-9a-fA-F]{8}",  // \Uhhhhhhhh (h: hex)
                            escapeIgnorer + "\\\\" + "x\\{[0-9a-fA-F]{1,6}\\}",  // \x{hhhh} (h: hex)
                            escapeIgnorer + "\\\\" + "x[0-9a-fA-F]{2}",  // \xhh (h: hex)
                            escapeIgnorer + "\\\\" + "0[0-7]{1,3}",  // \0ooo (o: octal)
                        ]
                    case .backReference:
                        return [
                            escapeIgnorer + "\\$[0-9]+",  // $0
                            escapeIgnorer + "\\\\[1-9]+",  // \1
                            escapeIgnorer + "\\\\k<[a-zA-Z][a-zA-Z0-9]+>",  // \k<name>
                        ]
                    case .symbol:
                        // -> [abc] will be extracted in ranges(in:) since regex cannot parse nested []
                        return [
                            escapeIgnorer + "\\(\\?(:|>|#|=|!|<=|<!|-?[ismwx]+:?|<[a-zA-Z][a-zA-Z0-9]*>)",  // (?...
                            escapeIgnorer + "[()|]",  // () |
                            escapeIgnorer + "\\\\[QE]",  // \Q ... \E
                        ]
                    case .quantifier:
                        // -> `?` is also used for .symbol.
                        return [
                            escapeIgnorer + "[*+?]",  // * + ?
                            escapeIgnorer + "\\{[0-9]+(,[0-9]*)?\\}",  // {n,m}
                        ]
                    case .anchor:
                        // -> `^` is also used for [^abc].
                        // -> `$` is also used for .backReference.
                        return [
                            escapeIgnorer + "[$^]",  // ^ $
                            escapeIgnorer + "\\\\[AbGZz]",  // \A, \b, ...
                        ]
                }
                
            case .replacement(let unescapes):
                switch self {
                    case .character where unescapes:
                        return [escapeIgnorer + "\\\\[$0tnr\"'\\\\]"]
                    case .backReference:
                        return [escapeIgnorer + "\\$[0-9]+"]
                    default:
                        return []
                }
        }
    }
}



private extension StringProtocol {
    
    /// Find the ranges of `[^abc]` pattern in the regular expression.
    ///
    /// - Parameter includingSymbols: Whether the result ranges including `[]` and `^`.
    /// - Returns: The matched ranges.
    func rangesForRegularExpressionBrackets(includingSymbols: Bool) -> [NSRange] {
        
        var index = self.startIndex
        var braceRanges: [Range<Index>] = []
        
        while index != self.endIndex {
            guard let (range, isNegative) = self.rangeForRegularExpressionBrackets(starting: index) else { break }
            
            if includingSymbols {
                braceRanges.append(range)
            } else {
                braceRanges.append(self.index(range.lowerBound, offsetBy: isNegative ? 2 : 1)..<self.index(before: range.upperBound))
            }
            
            index = range.upperBound
        }
        
        return braceRanges.map { NSRange($0, in: self) }
    }
    
    
    
    // MARK: Private Methods
    
    /// Find the range of the first `[^abc]` pattern in the regular expression after the given index.
    ///
    /// - Parameter searchIndex: The character index to start finding.
    /// - Returns: The found range and if the found pattern is a negative pattern (not `[abc]` but `[^abc]`), or `nil` if not found.
    private func rangeForRegularExpressionBrackets(starting searchIndex: Index) -> (range: Range<Index>, isNegative: Bool)? {
        
        assert(searchIndex == self.startIndex || self[self.index(before: searchIndex)] != "\\")
        
        var startIndex: Index?
        var isFirst = false  // flag wtheter the index is just after the opening
        var isNegative = false
        var isEscaped = false
        
        for index in self[searchIndex...].indices {
            switch (self[index], startIndex) {
                case ("\\", _):
                    isFirst = false
                    isEscaped.toggle()
                    
                case ("[", .none) where !isEscaped:
                    startIndex = index
                    isFirst = true
                    isEscaped = false
                    
                case ("]", .some(let startIndex)) where !isEscaped && !isFirst:
                    return (startIndex..<self.index(after: index), isNegative)
                    
                case ("^", _) where isFirst && !isNegative:
                    isNegative = true
                    isEscaped = false
                    
                default:
                    isFirst = false
                    isEscaped = false
            }
        }
        
        return nil
    }
}
