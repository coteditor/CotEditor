//
//  RegexSyntaxType.swift
//  RegexHighlighting
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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

enum RegexSyntaxType: CaseIterable {
    
    case character
    case backReference
    case symbol
    case quantifier
    case anchor
    
    
    // MARK: Internal Methods
    
    /// Extracts the ranges of the receiver type in the given string.
    ///
    /// - Parameters:
    ///   - string: The string to parse.
    ///   - mode: The regular expression parse mode.
    /// - Returns: The ranges of the receiver type in the given string.
    func ranges(in string: String, mode: RegexParseMode = .search) -> [NSRange] {
        
        var ranges = self.patterns(for: mode)
            .map { #"(?<!\\)(?:\\\\)*"# + $0 }  // regex pattern to avoid matching escaped character
            .map { try! NSRegularExpression(pattern: $0) }
            .flatMap { $0.matches(in: string, range: NSRange(..<string.utf16.count)) }
            .map(\.range)
        
        if case .search = mode {
            let (quotedRanges, quoteEndRanges) = string.rangesForRegularExpressionQuotes()
            let scan = string.rangesForRegularExpressionBrackets(excluding: quotedRanges)
            
            // remove tokens overlapping quotes and comments
            // (their ends are taken from the scans, since `\` in them is not an escape)
            let literalRanges = quotedRanges + quoteEndRanges + scan.comments + scan.commentEnds
            if !literalRanges.isEmpty {
                ranges.removeAll { range in
                    literalRanges.contains { literalRange in
                        literalRange.lowerBound < range.upperBound && range.lowerBound < literalRange.upperBound
                    }
                }
            }
            
            switch self {
                case .character:
                    ranges += scan.bracketContents
                case .symbol:
                    ranges += quoteEndRanges.filter { range in !scan.comments.contains { $0.contains(range.location) } }
                    ranges += scan.commentEnds
                    ranges += scan.brackets
                default: break
            }
        }
        
        return ranges
    }
    
    
    // MARK: Private Methods
    
    /// Returns regular expression patterns to extract the ranges of the receiver type in a string.
    ///
    /// - Parameter mode: The regular expression parse mode.
    /// - Returns: The regular expression patterns.
    private func patterns(for mode: RegexParseMode) -> [String] {
        
        switch mode {
            case .search:
                switch self {
                    case .character:
                        // -> [abc] will be extracted in ranges(in:) since regex cannot parse nested []
                        [
                            #"\."#,  // .
                            #"\\[^ABbGkZzQE1-9]"#,  // all escaped characters
                            #"\\[sdDefnrsStwWX]"#,  // \s, \d, ...
                            #"\\v"#,  // \v
                            #"\\\\"#,  // \\
                            #"\\c[a-z]"#,  // \cX (control)
                            #"\\N\{[a-zA-Z0-9 -]+\}"#,  // \N{UNICODE CHARACTER NAME}
                            #"\\[pP]\{[a-zA-Z0-9 _=-]+\}"#,  // \p{UNICODE PROPERTY NAME}
                            #"\\u[0-9a-fA-F]{4}"#,  // \uhhhh (h: hex)
                            #"\\U[0-9a-fA-F]{8}"#,  // \Uhhhhhhhh (h: hex)
                            #"\\x\{[0-9a-fA-F]{1,6}\}"#,  // \x{hhhh} (h: hex)
                            #"\\x[0-9a-fA-F]{2}"#,  // \xhh (h: hex)
                            #"\\0[0-7]{1,3}"#,  // \0ooo (o: octal)
                        ]
                    case .backReference:
                        [
                            #"\$[0-9]+"#,  // $0
                            #"\\[1-9]+"#,  // \1
                            #"\\k<[a-zA-Z][a-zA-Z0-9]*>"#,  // \k<name>
                        ]
                    case .symbol:
                        // -> [abc] will be extracted in ranges(in:) since regex cannot parse nested []
                        [
                            #"\(\?(:|>|#|=|!|<=|<!|-?[ismwx]+:?|<[a-zA-Z][a-zA-Z0-9]*>)"#,  // (?...
                            #"[()|]"#,  // () |
                            #"\\[QE]"#,  // \Q ... \E
                        ]
                    case .quantifier:
                        // -> `?` is also used for .symbol.
                        [
                            #"[*+?]"#,  // * + ?
                            #"\{[0-9]+(,[0-9]*)?\}"#,  // {n,m}
                        ]
                    case .anchor:
                        // -> `^` is also used for [^abc].
                        // -> `$` is also used for .backReference.
                        [
                            #"[$^]"#,  // ^ $
                            #"\\[ABbGZz]"#,  // \A, \b, ...
                        ]
                }
                
            case .replacement(let unescapes):
                switch self {
                    case .character where unescapes:
                        [#"\\[$0tnr"'\\]"#]
                    case .backReference:
                        [#"\$[0-9]+"#]
                    default:
                        []
                }
        }
    }
}


private struct RegexBracketRanges {
    
    var brackets: [NSRange] = []
    var bracketContents: [NSRange] = []
    var comments: [NSRange] = []
    var commentEnds: [NSRange] = []
}


private extension StringProtocol {
    
    /// Finds the ranges quoted by `\Q...\E` pattern in the regular expression.
    ///
    /// - Returns: The matched ranges, excluding the surrounding `\Q` and `\E`, and the ranges of the closing `\E`.
    func rangesForRegularExpressionQuotes() -> (quoted: [NSRange], ends: [NSRange]) {
        
        let scalars = self.unicodeScalars
        var quoteStartIndex: Index?
        var quoteRanges: [Range<Index>] = []
        var endRanges: [Range<Index>] = []
        var lastIndex: Index?
        var lastScalar: Unicode.Scalar?
        var backslashCount = 0
        
        for (index, scalar) in zip(scalars.indices, scalars) {
            if lastScalar == "\\", let lastIndex {
                switch (scalar, quoteStartIndex) {
                    case ("Q", .none) where !backslashCount.isMultiple(of: 2):
                        quoteStartIndex = scalars.index(after: index)
                    case ("E", .some(let startIndex)):  // `\` in quotes is not an escape
                        quoteRanges.append(startIndex..<lastIndex)
                        endRanges.append(lastIndex..<scalars.index(after: index))
                        quoteStartIndex = nil
                    default:
                        break
                }
            }
            
            backslashCount = (scalar == "\\") ? (backslashCount + 1) : 0
            lastIndex = index
            lastScalar = scalar
        }
        
        if let quoteStartIndex {
            quoteRanges.append(quoteStartIndex..<self.endIndex)
        }
        
        return (quoteRanges.map { NSRange($0, in: self) }, endRanges.map { NSRange($0, in: self) })
    }
    
    
    /// Finds the ranges of `[^abc]` and `(?#...)` patterns in the regular expression.
    ///
    /// Both are found in a single scan, as `(?#` in a bracket and `[` in a comment are just characters.
    ///
    /// - Parameters:
    ///   - excludedRanges: The ranges to ignore, sorted and not overlapping.
    /// - Returns: The ranges of the brackets and the comments.
    func rangesForRegularExpressionBrackets(excluding excludedRanges: [NSRange] = []) -> RegexBracketRanges {
        
        assert(zip(excludedRanges, excludedRanges.dropFirst()).allSatisfy { $0.upperBound <= $1.lowerBound })
        
        let scalars = self.unicodeScalars
        var excludedRanges = excludedRanges[...]
        var ranges = RegexBracketRanges()
        
        var openBracket: (index: Index, contentIndex: Index)?  // the opening `[` of the outermost bracket and its content
        var commentStartIndex: Index?
        var depth = 0  // nesting level of the inner sets, such as `[:alpha:]` in `[[:alpha:]]`
        var isFirst = false  // flag whether the index is just after the opening `[` or `[^`
        var isNegatable = false  // flag whether the index is just after the opening `[`
        var isEscaped = false
        
        for index in scalars.indices {
            if !excludedRanges.isEmpty {
                let location = index.utf16Offset(in: self)
                excludedRanges = excludedRanges.drop { $0.upperBound <= location }
                
                if excludedRanges.first?.contains(location) == true { continue }
            }
            
            if let commentStart = commentStartIndex {
                // any `)` ends the comment, even if escaped
                if scalars[index] == ")" {
                    ranges.comments.append(NSRange(commentStart..<index, in: self))
                    ranges.commentEnds.append(NSRange(index..<scalars.index(after: index), in: self))
                    commentStartIndex = nil
                }
                continue
            }
            
            switch (scalars[index], openBracket) {
                case ("\\", _):
                    isFirst = false
                    isNegatable = false
                    isEscaped.toggle()
                    
                case ("(", .none) where !isEscaped && scalars[scalars.index(after: index)...].starts(with: "?#".unicodeScalars):
                    commentStartIndex = scalars.index(index, offsetBy: 3)
                    
                case ("[", .none) where !isEscaped:
                    openBracket = (index, scalars.index(after: index))
                    isFirst = true
                    isNegatable = true
                    
                case ("[", .some) where !isEscaped:
                    depth += 1
                    isFirst = true
                    isNegatable = true
                    
                case ("]", .some(let bracket)) where !isEscaped && !isFirst:
                    if depth == 0 {
                        ranges.brackets.append(NSRange(bracket.index..<scalars.index(after: index), in: self))
                        ranges.bracketContents.append(NSRange(bracket.contentIndex..<index, in: self))
                        openBracket = nil
                    } else {
                        depth -= 1
                    }
                    
                case ("^", _) where isNegatable:
                    if depth == 0 {
                        openBracket?.contentIndex = scalars.index(after: index)
                    }
                    isNegatable = false
                    
                default:
                    isFirst = false
                    isNegatable = false
                    isEscaped = false
            }
        }
        
        return ranges
    }
}
