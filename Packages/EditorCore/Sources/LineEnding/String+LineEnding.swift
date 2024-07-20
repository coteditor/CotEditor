//
//  String+LineEnding.swift
//  LineEnding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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
import ValueRange

public extension String {
    
    /// Collects ranges of all line endings with line ending types in the specified range.
    ///
    /// - Parameters:
    ///     - range: The range to parse, or `nil` for the entire range.
    /// - Returns: Ranges of line endings.
    func lineEndingRanges(in range: NSRange? = nil) -> [ValueRange<LineEnding>] {
        
        guard !self.isEmpty else { return [] }
        
        var lineEndingRanges: [ValueRange<LineEnding>] = []
        let string = self as NSString
        let range = range ?? NSRange(..<string.length)
        
        string.enumerateSubstrings(in: range, options: [.byLines, .substringNotRequired]) { (_, substringRange, enclosingRange, _) in
            guard enclosingRange.length > 0 else { return }
            
            let lineEndingRange = NSRange(substringRange.upperBound..<enclosingRange.upperBound)
            
            guard
                lineEndingRange.length > 0,
                let lastCharacter = string.substring(with: lineEndingRange).first,  // line ending must be a single character
                let lineEnding = LineEnding(rawValue: lastCharacter)
            else { return }
            
            lineEndingRanges.append(.init(value: lineEnding, range: lineEndingRange))
        }
        
        return lineEndingRanges
    }
    
    
    /// Collects ranges of all line endings with line ending types in the specified range.
    ///
    /// This API can return line endings out of the specified range by considering the possibility
    /// that the boundary of the specified range lies between CRLF.
    ///
    /// - Parameters:
    ///   - range: The range to parse.
    ///   - effectiveRange: Upon return, the actual range of line endings collected.
    /// - Returns: Ranges of line endings.
    func lineEndingRanges(in range: NSRange, effectiveRange: inout NSRange) -> [ValueRange<LineEnding>] {
        
        let nsString = self as NSString
        let lowerScanBound = (0..<range.lowerBound).reversed().lazy
            .prefix { [0xA, 0xD].contains(nsString.character(at: $0)) }
            .last ?? range.lowerBound
        let upperScanBound = (range.upperBound..<nsString.length)
            .prefix { [0xA, 0xD].contains(nsString.character(at: $0)) }
            .last?.advanced(by: 1) ?? range.upperBound
        
        effectiveRange = NSRange(lowerScanBound..<upperScanBound)
        
        return self.lineEndingRanges(in: effectiveRange)
    }
    
    
    /// Returns the next line ending with its range after the given character `location`.
    ///
    /// The method returns `nil` if there is no line ending until the end of the string.
    ///
    /// - Parameter location: The character location.
    /// - Returns: The line ending type and the character range.
    func nextLineEnding(at location: Int) -> ValueRange<LineEnding>? {
        
        let nsString = self as NSString
        
        var end: Int = 0
        var contentsEnd: Int = 0
        nsString.getLineStart(nil, end: &end, contentsEnd: &contentsEnd, for: NSRange(location: location, length: 0))
        
        let range = NSRange(contentsEnd..<end)
        
        guard
            range.length > 0,
            let lastCharacter = nsString.substring(with: range).first,  // line ending must be a single character
            let lineEnding = LineEnding(rawValue: lastCharacter)
        else { return nil }
        
        return ValueRange(value: lineEnding, range: range)
    }
}


public extension StringProtocol {
    
    /// Returns a new string in which all line endings in the receiver are replaced with the given line endings.
    ///
    /// - Parameters:
    ///     - lineEnding: The line ending type with which to replace the target.
    /// - Returns: String replacing line ending characters.
    func replacingLineEndings(with lineEnding: LineEnding) -> String {
        
        self.replacingOccurrences(of: LineEnding.allRegexPattern, with: lineEnding.string, options: .regularExpression)
    }
}


private extension LineEnding {
    
    static let allRegexPattern = "\r\n|[\r\n\u{0085}\u{2028}\u{2029}]"
}
