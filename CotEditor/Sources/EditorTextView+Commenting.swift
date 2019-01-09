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
            self.uncomment(types: .both, fromLineHead: self.commentsAtLineHead)
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
        
        self.uncomment(types: .both, fromLineHead: false)
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
    
    /// comment out selection appending comment delimiters
    func commentOut(types: CommentTypes, fromLineHead: Bool) {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return }
        
        let spacer = self.appendsCommentSpacer ? " " : ""
        let targetRanges = self.commentingRanges(fromLineHead: self.commentsAtLineHead)
        let infos: [(string: String, location: Int, before: Bool)] = {
            if let delimiter = self.inlineCommentDelimiter, types.contains(.inline) {
                return self.string.inlineCommentOut(delimiter: delimiter, spacer: spacer, ranges: targetRanges)
            }
            if let delimiters = self.blockCommentDelimiters, types.contains(.block) {
                return self.string.blockCommentOut(delimiters: delimiters, spacer: spacer, ranges: targetRanges)
            }
            return []
        }()
        
        guard !infos.isEmpty else { return }
        
        let newStrings = infos.map { $0.string }
        let replacementRanges = infos.map { NSRange($0.location..<$0.location) }
        let selectedRanges = (self.rangesForUserTextChange ?? self.selectedRanges)
            .map { $0.rangeValue }
            .map { range -> NSRange in
                let location = infos
                    .filter { $0.location < range.location || ($0.location == range.location && $0.before) }
                    .reduce(into: range.location) { $0 += ($1.string as NSString).length }
                let length = infos.filter { range.lowerBound < $0.location && $0.location < range.upperBound }
                    .reduce(into: range.length) { $0 += ($1.string as NSString).length }
                
                return NSRange(location: location, length: length)
            }
        
        self.replace(with: newStrings, ranges: replacementRanges, selectedRanges: selectedRanges,
                     actionName: "Comment Out".localized)
    }
    
    
    /// uncomment selection removing comment delimiters
    func uncomment(types: CommentTypes, fromLineHead: Bool) {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return }
        
        let spacer = self.appendsCommentSpacer ? " " : ""
        let targetRanges = self.commentingRanges(fromLineHead: self.commentsAtLineHead).filter { $0.length > 0 }
        let indices: IndexSet = {
            if let delimiters = self.blockCommentDelimiters, types.contains(.block) {
                let indices = self.string.blockUncomment(delimiters: delimiters, spacer: spacer, ranges: targetRanges)
                if !indices.isEmpty { return indices }
            }
            if let delimiter = self.inlineCommentDelimiter, types.contains(.inline) {
                return self.string.inlineUncomment(delimiter: delimiter, spacer: spacer, ranges: targetRanges)
            }
            return IndexSet()
        }()
        
        guard !indices.isEmpty else { return }
        
        let replacementRanges = indices.rangeView.map { NSRange($0.lowerBound..<$0.upperBound) }
        let newStrings = [String](repeating: "", count: replacementRanges.count)
        let selectedRanges = (self.rangesForUserTextChange ?? self.selectedRanges)
            .map { $0.rangeValue }
            .map { range -> NSRange in
                let location = range.location - indices.count { $0 < range.location }
                let length = range.length - indices.count { range.contains($0) }
                
                return NSRange(location: location, length: length)
            }
        
        
        self.replace(with: newStrings, ranges: replacementRanges, selectedRanges: selectedRanges,
                     actionName: "Uncomment".localized)
    }
    
    
    /// whether given range can be uncommented
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



private extension String {
    
    /// append inline style comment delimiters in range inserting spacer after delimiters and return commented-out string and new selected range
    func inlineCommentOut(delimiter: String, spacer: String, ranges: [NSRange]) -> [(string: String, location: Int, before: Bool)] {
        
        let regex = try! NSRegularExpression(pattern: "^", options: [.anchorsMatchLines])
        
        return ranges.flatMap { regex.matches(in: self, range: $0) }
            .map { $0.range.location }
            .unique
            .map { (delimiter + spacer, $0, true) }
    }
    
    
    /// append block style comment delimiters in range inserting spacer between string and delimiters and return commented-out string and new selected range
    func blockCommentOut(delimiters: Pair<String>, spacer: String, ranges: [NSRange]) -> [(string: String, location: Int, before: Bool)] {
        
        return ranges.flatMap { [(delimiters.begin + spacer, $0.lowerBound, true), (spacer + delimiters.end, $0.upperBound, false)] }
    }
    
    
    /// find inline style comment delimiters with and without spacers in range and return a character location IndexSet to remove
    func inlineUncomment(delimiter: String, spacer: String, ranges: [NSRange]) -> IndexSet {
        
        let pattern = NSRegularExpression.escapedPattern(for: delimiter)
        let spacerPattern = spacer.isEmpty ? "" : "(?:" + spacer + ")?"
        let regex = try! NSRegularExpression(pattern: "^" + pattern + spacerPattern,
                                             options: [.anchorsMatchLines])
        
        return ranges.flatMap { regex.matches(in: self, range: $0) }
            .map { $0.range }
            .map { $0.lowerBound..<$0.upperBound }
            .reduce(into: IndexSet()) { $0.insert(integersIn: $1) }
    }
    
    
    /// remove block style comment delimiters in range removing also spacers between string and delimiter and return uncommented string and new selected range
    func blockUncomment(delimiters: Pair<String>, spacer: String, ranges: [NSRange]) -> IndexSet {
        
        let beginPattern = NSRegularExpression.escapedPattern(for: delimiters.begin)
        let endPattern = NSRegularExpression.escapedPattern(for: delimiters.end)
        let spacerPattern = spacer.isEmpty ? "" : "(?:" + spacer + ")?"
        let regex = try! NSRegularExpression(pattern: "\\A(" + beginPattern + spacerPattern + ").*?(" + spacerPattern + endPattern + ")\\Z",
                                             options: [.dotMatchesLineSeparators])
        
        return ranges.flatMap { regex.matches(in: self, range: $0) }
            .flatMap { [$0.range(at: 1), $0.range(at: 2)] }
            .map { $0.lowerBound..<$0.upperBound }
            .reduce(into: IndexSet()) { $0.insert(integersIn: $1) }
    }
    
}
