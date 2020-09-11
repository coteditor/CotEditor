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
//  © 2018-2020 1024jp
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



enum RegularExpressionSyntaxType {
    
    case character
    case backReference
    case symbol
    case quantifier
    case anchor
    
    static let priority: [RegularExpressionSyntaxType] = [
        .character,
        .backReference,
        .symbol,
        .quantifier,
        .anchor,
    ]
    
    
    
    // MARK: Public Methods
    
    func ranges(in string: String, mode: RegularExpressionParseMode) -> [NSRange] {
        
        var ranges = self.patterns(for: mode)
            .map { try! NSRegularExpression(pattern: $0) }
            .flatMap { $0.matches(in: string, range: string.nsRange) }
            .map(\.range)
        
        if self == .character, case .search = mode {
            ranges += string.ranges(bracePair: BracePair("[", "]"))
                .map { (string[$0.lowerBound] == "^") ? string.index(after: $0.lowerBound)..<$0.upperBound : $0 }
                .map { NSRange($0, in: string) }
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
                            escapeIgnorer + "\\\\" + "[^AbGZzQE1-9]",  // all escaped characters
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
                            escapeIgnorer + "\\$[0-9]",  // $0
                            escapeIgnorer + "\\\\[1-9]",  // \1
                        ]
                    case .symbol:
                        return [
                            escapeIgnorer + "\\(\\?(:|>|#|=|!|<=|<!|-?[ismwx]+:?)",  // (?...
                            escapeIgnorer + "[()|]",  // () |
                            escapeIgnorer + "(\\[\\^?|\\])",  // [^ ]
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
                        return [escapeIgnorer + "\\$[0-9]"]
                    default:
                        return []
                }
        }
    }
    
}



private extension StringProtocol {
    
    /// ranges of inside of the most outer pairs of brace
    func ranges(bracePair: BracePair) -> [Range<Index>] {
        
        var index = self.startIndex
        var braceRanges: [Range<Index>] = []
        
        while index != self.endIndex {
            guard self[index] == bracePair.begin, !self.isCharacterEscaped(at: index) else {
                index = self.index(after: index)
                continue
            }
            
            guard let endIndex = self.indexOfBracePair(beginIndex: index, pair: bracePair) else { break }
            
            braceRanges.append(self.index(after: index)..<endIndex)
            index = self.index(after: endIndex)
        }
        
        return braceRanges
    }
    
}
