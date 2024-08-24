//
//  String+Commenting.swift
//  TextEditing
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-16.
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
import StringUtils
import Syntax

public struct CommentTypes: OptionSet, Sendable {
    
    public let rawValue: Int
    
    public static let inline = Self(rawValue: 1 << 0)
    public static let block = Self(rawValue: 1 << 1)
    
    public static let both: Self = [.inline, .block]
    
    
    public init(rawValue: Int) {
        
        self.rawValue = rawValue
    }
}


public extension String {
    
    /// Comments out the selections by appending comment delimiters.
    ///
    /// - Parameters:
    ///   - types: The type of commenting-out. When, `.both`, inline-style takes priority over block-style.
    ///   - fromLineHead: When `true`, the receiver comments out from the beginning of the line.
    func commentOut(types: CommentTypes, delimiters: Syntax.Comment, fromLineHead: Bool, in selectedRanges: [NSRange]) -> EditingContext? {
        
        guard !delimiters.isEmpty else { return nil }
        
        let items: [NSRange.InsertionItem] = {
            let targetRanges = selectedRanges
                .map { fromLineHead ? self.lineContentsRange(for: $0) : $0 }
                .uniqued
            
            if types.contains(.inline), let delimiter = delimiters.inline {
                return self.inlineCommentOut(delimiter: delimiter, ranges: targetRanges)
            }
            if types.contains(.block), let delimiters = delimiters.block {
                return self.blockCommentOut(delimiters: delimiters, ranges: targetRanges)
            }
            return []
        }()
        
        guard !items.isEmpty else { return nil }
        
        let newStrings = items.map(\.string)
        let replacementRanges = items.map { NSRange(location: $0.location, length: 0) }
        let newSelectedRanges = selectedRanges.map { $0.inserted(items: items) }
        
        return EditingContext(strings: newStrings, ranges: replacementRanges, selectedRanges: newSelectedRanges)
    }
    
    
    /// Uncomments the selections by removing comment delimiters.
    func uncomment(delimiters: Syntax.Comment, in selectedRanges: [NSRange]) -> EditingContext? {
        
        guard !delimiters.isEmpty else { return nil }
        
        let deletionRanges: [NSRange] = {
            if let delimiters = delimiters.block {
                let targetRanges = selectedRanges.map { $0.isEmpty ? self.lineContentsRange(for: $0) : $0 }.uniqued
                if let ranges = self.rangesOfBlockDelimiters(delimiters, ranges: targetRanges) {
                    return ranges
                }
            }
            if let delimiter = delimiters.inline {
                let targetRanges = selectedRanges.map { self.lineContentsRange(for: $0) }.uniqued
                if let ranges = self.rangesOfInlineDelimiter(delimiter, ranges: targetRanges) {
                    return ranges
                }
            }
            return []
        }()
        
        guard !deletionRanges.isEmpty else { return nil }
        
        let newStrings = [String](repeating: "", count: deletionRanges.count)
        let newSelectedRanges = selectedRanges.map { $0.removed(ranges: deletionRanges) }
        
        return EditingContext(strings: newStrings, ranges: deletionRanges, selectedRanges: newSelectedRanges)
    }
    
    
    /// Returns whether the selected ranges can be uncommented.
    ///
    /// - Parameter partly: When `true`, the method returns `true` when a part of selections is commented-out,
    ///                     otherwise only when the entire selections can be commented out.
    /// - Returns: `true` when selection can be uncommented.
    func canUncomment(partly: Bool, delimiters: Syntax.Comment, in selectedRanges: [NSRange]) -> Bool {
        
        guard !delimiters.isEmpty else { return false }
        
        let targetRanges = selectedRanges
            .map(self.lineContentsRange(for:))
            .filter({ !$0.isEmpty })
            .uniqued
        
        guard !targetRanges.isEmpty else { return false }
        
        if let delimiters = delimiters.block,
           let ranges = self.rangesOfBlockDelimiters(delimiters, ranges: targetRanges)
        {
            return partly ? true : (ranges.count == (2 * targetRanges.count))
        }
        
        if let delimiter = delimiters.inline,
           let ranges = self.rangesOfInlineDelimiter(delimiter, ranges: targetRanges)
        {
            let lineRanges = targetRanges.flatMap { self.lineContentsRanges(for: $0) }.uniqued
            return partly ? true : (ranges.count == lineRanges.count)
        }
        
        return false
    }
}


extension String {
    
    /// Returns the editing information to comment out the given `ranges` by appending inline-style comment delimiters.
    ///
    /// - Parameters:
    ///   - delimiter: The inline comment delimiter to insert.
    ///   - ranges: The ranges where to comment out.
    /// - Returns: Items that contain editing information to insert comment delimiters.
    func inlineCommentOut(delimiter: String, ranges: [NSRange]) -> [NSRange.InsertionItem] {
        
        let regex = try! NSRegularExpression(pattern: "^", options: [.anchorsMatchLines])
        
        return ranges.flatMap { regex.matches(in: self, range: $0) }
            .map(\.range.location)
            .uniqued
            .map { NSRange.InsertionItem(string: delimiter, location: $0, forward: true) }
    }
    
    
    /// Returns the editing information to comment out the given `ranges` by appending block-style comment delimiters.
    ///
    /// - Parameters:
    ///   - delimiters: The pair of block comment delimiters to insert.
    ///   - ranges: The ranges where to comment out.
    /// - Returns: Items that contain editing information to insert comment delimiters.
    func blockCommentOut(delimiters: Pair<String>, ranges: [NSRange]) -> [NSRange.InsertionItem] {
        
        ranges.flatMap {
            [NSRange.InsertionItem(string: delimiters.begin, location: $0.lowerBound, forward: true),
             NSRange.InsertionItem(string: delimiters.end, location: $0.upperBound, forward: false)]
        }
    }
    
    
    /// Finds inline-style delimiters in `ranges`.
    ///
    /// - Parameters:
    ///   - delimiter: The inline delimiter to find.
    ///   - ranges: The ranges where to find.
    /// - Returns: Ranges where delimiters are, or `nil` when no delimiters was found.
    func rangesOfInlineDelimiter(_ delimiter: String, ranges: [NSRange]) -> [NSRange]? {
        
        let ranges = ranges.filter { !$0.isEmpty }
        
        guard !ranges.isEmpty, !self.isEmpty else { return [] }
        
        let delimiterPattern = NSRegularExpression.escapedPattern(for: delimiter)
        let pattern = "^[ \t]*(\(delimiterPattern))"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        
        let delimiterRanges = ranges
            .flatMap { regex.matches(in: self, range: $0) }
            .map { $0.range(at: 1) }
            .uniqued
        
        return delimiterRanges.isEmpty ? nil : delimiterRanges
    }
    
    
    /// Finds block-style delimiters in `ranges`.
    ///
    /// - Note: This method matches a block only when one of the given `ranges` fits exactly.
    ///
    /// - Parameters:
    ///   - delimiters: The pair of block delimiters to find.
    ///   - ranges: The ranges where to find.
    /// - Returns: Ranges where delimiters are, or `nil` when no delimiters was found.
    func rangesOfBlockDelimiters(_ delimiters: Pair<String>, ranges: [NSRange]) -> [NSRange]? {
        
        let ranges = ranges.filter { !$0.isEmpty }
        
        guard !ranges.isEmpty, !self.isEmpty else { return [] }
        
        let beginPattern = NSRegularExpression.escapedPattern(for: delimiters.begin)
        let endPattern = NSRegularExpression.escapedPattern(for: delimiters.end)
        let pattern = "\\A[ \t]*(\(beginPattern)).*?(\(endPattern))[ \t]*\\Z"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        let delimiterRanges = ranges
            .flatMap { regex.matches(in: self, range: $0) }
            .flatMap { [$0.range(at: 1), $0.range(at: 2)] }
        
        return delimiterRanges.isEmpty ? nil : delimiterRanges
    }
}
