//
//  EditorTextView+Commenting.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-10.
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

import AppKit

extension EditorTextView: Commenting {
    
    // MARK: Action Messages
    
    /// Toggles the comment state of the selections.
    @IBAction func toggleComment(_ sender: Any?) {
        
        if self.canUncomment(partly: false) {
            self.uncomment()
        } else {
            self.commentOut(types: .both, fromLineHead: true)
        }
    }
    
    
    /// Comments out the selections by appending comment delimiters.
    @IBAction func commentOut(_ sender: Any?) {
        
        self.commentOut(types: .both, fromLineHead: false)
    }
    
    
    /// Comments out the selections by appending block comment delimiters.
    @IBAction func blockCommentOut(_ sender: Any?) {
        
        self.commentOut(types: .block, fromLineHead: false)
    }
    
    
    /// Comments out the selections by appending inline comment delimiters.
    @IBAction func inlineCommentOut(_ sender: Any?) {
        
        self.commentOut(types: .inline, fromLineHead: false)
    }
    
    
    /// Uncomments the selections by removing comment delimiters.
    @IBAction func uncomment(_ sender: Any?) {
        
        self.uncomment()
    }
}



// MARK: - Protocol

struct CommentTypes: OptionSet {
    
    let rawValue: Int
    
    static let inline = Self(rawValue: 1 << 0)
    static let block = Self(rawValue: 1 << 1)
    
    static let both: Self = [.inline, .block]
}


@MainActor protocol Commenting: NSTextView {
    
    var commentDelimiters: Syntax.Comment { get }
}


extension Commenting {
    
    // MARK: Public Methods
    
    /// Comments out the selections by appending comment delimiters.
    ///
    /// - Parameters:
    ///   - types: The type of commenting-out. When, `.both`, inline-style takes priority over block-style.
    ///   - fromLineHead: When `true`, the receiver comments out from the beginning of the line.
    func commentOut(types: CommentTypes, fromLineHead: Bool) {
        
        guard
            self.commentDelimiters.block != nil || self.commentDelimiters.inline != nil,
            let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue)
        else { return }
        
        let items: [NSRange.InsertionItem] = {
            let targetRanges = selectedRanges
                .map { fromLineHead ? self.string.lineContentsRange(for: $0) : $0 }
                .uniqued
            
            if types.contains(.inline), let delimiter = self.commentDelimiters.inline {
                return self.string.inlineCommentOut(delimiter: delimiter, ranges: targetRanges)
            }
            if types.contains(.block), let delimiters = self.commentDelimiters.block {
                return self.string.blockCommentOut(delimiters: delimiters, ranges: targetRanges)
            }
            return []
        }()
        
        guard !items.isEmpty else { return }
        
        let newStrings = items.map(\.string)
        let replacementRanges = items.map { NSRange(location: $0.location, length: 0) }
        let newSelectedRanges = selectedRanges.map { $0.inserted(items: items) }
        
        self.replace(with: newStrings, ranges: replacementRanges, selectedRanges: newSelectedRanges,
                     actionName: String(localized: "Comment Out", table: "MainMenu"))
    }
    
    
    /// Uncomments the selections by removing comment delimiters.
    func uncomment() {
        
        guard
            self.commentDelimiters.block != nil || self.commentDelimiters.inline != nil,
            let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue)
        else { return }
        
        let deletionRanges: [NSRange] = {
            if let delimiters = self.commentDelimiters.block {
                let targetRanges = selectedRanges.map { $0.isEmpty ? self.string.lineContentsRange(for: $0) : $0 }.uniqued
                if let ranges = self.string.rangesOfBlockDelimiters(delimiters, ranges: targetRanges) {
                    return ranges
                }
            }
            if let delimiter = self.commentDelimiters.inline {
                let targetRanges = selectedRanges.map { self.string.lineContentsRange(for: $0) }.uniqued
                if let ranges = self.string.rangesOfInlineDelimiter(delimiter, ranges: targetRanges) {
                    return ranges
                }
            }
            return []
        }()
        
        guard !deletionRanges.isEmpty else { return }
        
        let newStrings = [String](repeating: "", count: deletionRanges.count)
        let newSelectedRanges = selectedRanges.map { $0.removed(ranges: deletionRanges) }
        
        self.replace(with: newStrings, ranges: deletionRanges, selectedRanges: newSelectedRanges,
                     actionName: String(localized: "Uncomment", table: "MainMenu"))
    }
    
    
    /// Returns whether the selected ranges can be uncommented.
    ///
    /// - Parameter partly: When `true`, the method returns `true` when a part of selections is commented-out,
    ///                     otherwise only when the entire selections can be commented out.
    /// - Returns: `true` when selection can be uncommented.
    func canUncomment(partly: Bool) -> Bool {
        
        guard
            self.commentDelimiters.block != nil || self.commentDelimiters.inline != nil,
            let targetRanges = self.rangesForUserTextChange?.map(\.rangeValue)
                .map(self.string.lineContentsRange(for:))
                .filter({ !$0.isEmpty })
                .uniqued,
            !targetRanges.isEmpty
        else { return false }
        
        if let delimiters = self.commentDelimiters.block,
           let ranges = self.string.rangesOfBlockDelimiters(delimiters, ranges: targetRanges)
        {
            return partly ? true : (ranges.count == (2 * targetRanges.count))
        }
        
        if let delimiter = self.commentDelimiters.inline,
           let ranges = self.string.rangesOfInlineDelimiter(delimiter, ranges: targetRanges)
        {
            let lineRanges = targetRanges.flatMap { self.string.lineContentsRanges(for: $0) }.uniqued
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
