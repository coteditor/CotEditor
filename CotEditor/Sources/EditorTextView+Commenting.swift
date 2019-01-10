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
//  © 2014-2019 1024jp
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

import Cocoa

extension EditorTextView: Commenting {
    
    // MARK: Commenting Protocol
    
    var appendsCommentSpacer: Bool {
        
        return UserDefaults.standard[.appendsCommentSpacer]
    }
    
    
    var commentsAtLineHead: Bool {
        
        return UserDefaults.standard[.commentsAtLineHead]
    }
    
    
    
    // MARK: Action Messages
    
    /// toggle comment state in selection
    @IBAction func toggleComment(_ sender: Any?) {
        
        if self.canUncomment(partly: false) {
            self.uncomment(fromLineHead: self.commentsAtLineHead)
        } else {
            self.commentOut(types: .both, fromLineHead: self.commentsAtLineHead)
        }
    }
    
    
    /// comment out selection appending comment delimiters
    @IBAction func commentOut(_ sender: Any?) {
        
        self.commentOut(types: .both, fromLineHead: false)
    }
    
    
    /// comment out selection appending block comment delimiters
    @IBAction func blockCommentOut(_ sender: Any?) {
        
        self.commentOut(types: .block, fromLineHead: false)
    }
    
    
    /// comment out selection appending inline comment delimiters
    @IBAction func inlineCommentOut(_ sender: Any?) {
        
        self.commentOut(types: .inline, fromLineHead: false)
    }
    
    
    /// uncomment selection removing comment delimiters
    @IBAction func uncomment(_ sender: Any?) {
        
        self.uncomment(fromLineHead: false)
    }
    
}



// MARK: - Protocol

struct CommentTypes: OptionSet {
    
    let rawValue: Int
    
    static let inline = CommentTypes(rawValue: 1 << 0)
    static let block = CommentTypes(rawValue: 1 << 1)
    
    static let both: CommentTypes = [.inline, .block]
}


protocol Commenting: AnyObject {
    
    var inlineCommentDelimiter: String? { get }
    var blockCommentDelimiters: Pair<String>? { get }
    
    var appendsCommentSpacer: Bool { get }
    var commentsAtLineHead: Bool { get }
}


extension Commenting where Self: NSTextView {
    
    // MARK: Public Methods
    
    /// Comment out selections by appending comment delimiters.
    ///
    /// - Parameters:
    ///   - types: The type of commenting-out. When, `.both`, inline-style takes priprity over block-style.
    ///   - fromLineHead: When `true`, the receiver comments out from the beginning of the line.
    func commentOut(types: CommentTypes, fromLineHead: Bool) {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return }
        
        let spacer = self.appendsCommentSpacer ? " " : ""
        let targetRanges = self.commentingRanges(fromLineHead: fromLineHead)
        let items: [(string: String, location: Int, forward: Bool)] = {
            if let delimiter = self.inlineCommentDelimiter, types.contains(.inline) {
                return self.string.inlineCommentOut(delimiter: delimiter, spacer: spacer, ranges: targetRanges)
            }
            if let delimiters = self.blockCommentDelimiters, types.contains(.block) {
                return self.string.blockCommentOut(delimiters: delimiters, spacer: spacer, ranges: targetRanges)
            }
            return []
        }()
        
        guard !items.isEmpty else { return }
        
        let newStrings = items.map { $0.string }
        let replacementRanges = items.map { NSRange($0.location..<$0.location) }
        let selectedRanges = (self.rangesForUserTextChange ?? self.selectedRanges)
            .map { $0.rangeValue.move(inserting: items) }
        
        self.replace(with: newStrings, ranges: replacementRanges, selectedRanges: selectedRanges,
                     actionName: "Comment Out".localized)
    }
    
    
    /// Uncomment selections by removing comment delimiters.
    ///
    /// - Parameters:
    ///   - fromLineHead: When `true`, the receiver uncomments from the beginning of the line.
    func uncomment(fromLineHead: Bool) {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return }
        
        let spacer = self.appendsCommentSpacer ? " " : ""
        let targetRanges = self.commentingRanges(fromLineHead: fromLineHead)
        let deletionRanges: [NSRange] = {
            if let delimiters = self.blockCommentDelimiters {
                let indices = self.string.rangesOf(delimiters: delimiters, spacer: spacer, ranges: targetRanges)
                if !indices.isEmpty { return indices }
            }
            if let delimiter = self.inlineCommentDelimiter {
                return self.string.rangesOf(delimiter: delimiter, spacer: spacer, ranges: targetRanges)
            }
            return []
        }()
        
        guard !deletionRanges.isEmpty else { return }
        
        let newStrings = [String](repeating: "", count: deletionRanges.count)
        let selectedRanges = (self.rangesForUserTextChange ?? self.selectedRanges)
            .map { $0.rangeValue.move(deleting: deletionRanges) }
        
        self.replace(with: newStrings, ranges: deletionRanges, selectedRanges: selectedRanges,
                     actionName: "Uncomment".localized)
    }
    
    
    /// Whether given range can be uncommented.
    ///
    /// - Parameter partly: When `true`, the method returns true when a part of slections is commented-out,
    ///                     otherwise only when the entire selections are commented out.
    /// - Returns: `true` when selection can be uncommented.
    func canUncomment(partly: Bool) -> Bool {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return false }
        
        let targets = self.commentingRanges(fromLineHead: self.commentsAtLineHead)
            .filter { $0.length > 0 }
            .map { (self.string as NSString).substring(with: $0) }
        
        guard !targets.isEmpty else { return false }
        
        if let delimiters = self.blockCommentDelimiters {
            let predicate: ((String) -> Bool) = { $0.hasPrefix(delimiters.begin) && $0.hasSuffix(delimiters.end) }
            
            if partly ? targets.contains(where: predicate) : targets.allSatisfy(predicate) {
                return true
            }
        }
        
        if let delimiter = self.inlineCommentDelimiter {
            let predicate: ((String) -> Bool) = { $0.hasPrefix(delimiter) }
            let lines = targets.flatMap { $0.components(separatedBy: "\n") }
            
            if partly ? lines.contains(where: predicate) : lines.allSatisfy(predicate) {
                return true
            }
        }
        
        return false
    }
    
    
    
    // MARK: Private Methods
    
    /// return commenting target range
    private func commentingRanges(fromLineHead: Bool) -> [NSRange] {
        
        return (self.rangesForUserTextChange ?? [])
            .map { $0.rangeValue }
            .map { fromLineHead ? self.string.lineRange(for: $0, excludingLastLineEnding: true) : $0 }
            .unique
    }
    
}



private extension NSRange {
    
    /// Return a new range by assuming the indices of the given items are inserted.
    ///
    /// - Parameter items: An array of items to be inserted.
    /// - Returns: A new range that the receiver moved.
    func move(inserting items: [(string: String, location: Int, forward: Bool)]) -> NSRange {
        
        let location = items
            .prefix { $0.location < self.lowerBound || ($0.location == self.lowerBound && $0.forward) }
            .map { ($0.string as NSString).length }
            .reduce(self.location, +)
        let length = items
            .filter { self.lowerBound < $0.location && $0.location < self.upperBound }
            .map { ($0.string as NSString).length }
            .reduce(self.length, +)
        
        return NSRange(location: location, length: length)
    }
    
    
    /// Return a new range by assuming the indexes in the given ranges are removed.
    ///
    /// - Parameter deletingRanges: An array of NSRange where the indexes are emoved.
    /// - Returns: A new range that the receiver moved.
    func move(deleting deletingRanges: [NSRange]) -> NSRange {
        
        let indices = deletingRanges.reduce(into: IndexSet()) { $0.insert(integersIn: Range($1)!) }
        
        let location = self.location - indices.count(in: ..<self.lowerBound)
        let length = self.length - indices.count(in: Range(self)!)
        
        return NSRange(location: location, length: length)
    }

}


private extension String {
    
    /// Return editing information to comment out given `ranges` by appending inline-style comment delimiters
    /// and spacers after delimiters.
    ///
    /// - Parameters:
    ///   - delimiter: The inline comment delimiter to insert.
    ///   - spacer: The spacer between delimiter and string.
    ///   - ranges: The ranges where to comment out.
    /// - Returns: Items that contain editing information to insert comment delimiters.
    func inlineCommentOut(delimiter: String, spacer: String, ranges: [NSRange]) -> [(string: String, location: Int, forward: Bool)] {
        
        let regex = try! NSRegularExpression(pattern: "^", options: [.anchorsMatchLines])
        
        return ranges.flatMap { regex.matches(in: self, range: $0) }
            .map { $0.range.location }
            .unique
            .map { (delimiter + spacer, $0, true) }
    }
    
    
    /// Return editing information to comment out given `ranges` by appending block-style comment delimiters
    /// and spacers between string and delimiters.
    ///
    /// - Parameters:
    ///   - delimiters: The pair of block comment delimiters to insert.
    ///   - spacer: The spacer between delimiter and string.
    ///   - ranges: The ranges where to comment out.
    /// - Returns: Items that contain editing information to insert comment delimiters.
    func blockCommentOut(delimiters: Pair<String>, spacer: String, ranges: [NSRange]) -> [(string: String, location: Int, forward: Bool)] {
        
        return ranges.flatMap { [(delimiters.begin + spacer, $0.lowerBound, true), (spacer + delimiters.end, $0.upperBound, false)] }
    }
    
    
    /// Find inline-style delimiters in `ranges` as well as spacers between the content and a delimiter if eny.
    ///
    /// - Parameters:
    ///   - delimiter: The inline delimiter to find.
    ///   - spacer: The spacer between delimiter and string.
    ///   - ranges: The ranges where to find.
    /// - Returns: Ranges where delimiters and spacers are.
    func rangesOf(delimiter: String, spacer: String, ranges: [NSRange]) -> [NSRange] {
        
        let ranges = ranges.filter { $0.length > 0 }
        
        guard !ranges.isEmpty, !self.isEmpty else { return [] }
        
        let delimiterPattern = NSRegularExpression.escapedPattern(for: delimiter)
        let spacerPattern = spacer.isEmpty ? "" : "(?:" + spacer + ")?"
        let pattern = "^" + delimiterPattern + spacerPattern
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        
        return ranges.flatMap { regex.matches(in: self, range: $0) }
            .map { $0.range }
    }
    
    
    /// Find block-style delimiters in `ranges` as well as spacers between the content and a delimiter if eny.
    ///
    /// - Note: This method matches a block only when one of the given `ranges` fits exactly.
    ///
    /// - Parameters:
    ///   - delimiters: The pair of block delimiters to find.
    ///   - spacer: The spacer between delimiter and string.
    ///   - ranges: The ranges where to find.
    /// - Returns: Ranges where delimiters and spacers are.
    func rangesOf(delimiters: Pair<String>, spacer: String, ranges: [NSRange]) -> [NSRange] {
        
        let ranges = ranges.filter { $0.length > 0 }
        
        guard !ranges.isEmpty, !self.isEmpty else { return [] }
        
        let beginPattern = NSRegularExpression.escapedPattern(for: delimiters.begin)
        let endPattern = NSRegularExpression.escapedPattern(for: delimiters.end)
        let spacerPattern = spacer.isEmpty ? "" : "(?:" + spacer + ")?"
        let pattern = "\\A(" + beginPattern + spacerPattern + ").*?(" + spacerPattern + endPattern + ")\\Z"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        return ranges.flatMap { regex.matches(in: self, range: $0) }
            .flatMap { [$0.range(at: 1), $0.range(at: 2)] }
    }
    
}
