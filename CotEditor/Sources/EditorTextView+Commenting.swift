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
        
        guard let targetRange = self.commentingRange(fromLineHead: fromLineHead) else { return }
        
        let spacer = self.appendsCommentSpacer ? " " : ""
        var new: (String, Int)?
        
        // insert delimiters
        if let delimiter = self.inlineCommentDelimiter, types.contains(.inline) {
            new = self.string.inlineCommentOut(delimiter: delimiter, spacer: spacer, range: targetRange, selectedRange: self.selectedRange)
            
        } else if let delimiters = self.blockCommentDelimiters, types.contains(.block) {
            new = self.string.blockCommentOut(delimiters: delimiters, spacer: spacer, range: targetRange, selectedRange: self.selectedRange)
        }
        
        guard let (newString, cursorOffset) = new else { return }
        
        let newSelectedRange = self.string.seletedRange(range: targetRange, selectedRange: selectedRange, newString: newString, offset: cursorOffset)
        
        self.replace(with: newString, range: targetRange, selectedRange: newSelectedRange,
                     actionName: "Comment Out".localized)
    }
    
    
    /// uncomment selection removing comment delimiters
    func uncomment(types: CommentTypes, fromLineHead: Bool) {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return }
        
        guard let targetRange = self.commentingRange(fromLineHead: fromLineHead),
            targetRange.length > 0 else { return }
        
        let spacer = self.appendsCommentSpacer ? " " : ""
        var new: (String, Int)?
        
        if let delimiters = self.blockCommentDelimiters, types.contains(.block) {
            new = self.string.blockUncomment(delimiters: delimiters, spacer: spacer, range: targetRange, selectedRange: self.selectedRange)
        }
        if let delimiter = self.inlineCommentDelimiter, types.contains(.inline), new == nil {
            new = self.string.inlineUncomment(delimiter: delimiter, spacer: spacer, range: targetRange, selectedRange: self.selectedRange)
        }
        
        guard let (newString, cursorOffset) = new else { return }
        
        let newSelectedRange = self.string.seletedRange(range: targetRange, selectedRange: self.selectedRange, newString: newString, offset: cursorOffset)
        
        self.replace(with: newString, range: targetRange, selectedRange: newSelectedRange,
                     actionName: "Uncomment".localized)
    }
    
    
    /// whether given range can be uncommented
    func canUncomment(partly: Bool) -> Bool {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return false }
        
        guard
            let targetRange = self.commentingRange(fromLineHead: self.commentsAtLineHead),
            targetRange.length > 0 else { return false }
        
        let target = (self.string as NSString).substring(with: targetRange)
        
        if let delimiters = self.blockCommentDelimiters {
            if target.hasPrefix(delimiters.begin), target.hasSuffix(delimiters.end) {
                return true
            }
        }
        
        if let delimiter = self.inlineCommentDelimiter {
            let lines = target.components(separatedBy: "\n")
            if partly ? lines.contains(where: { $0.hasPrefix(delimiter) }) : lines.allSatisfy({ $0.hasPrefix(delimiter) }) {
                return true
            }
        }
        
        return false
    }
    
    
    
    // MARK: Private Methods
    
    /// return commenting target range
    private func commentingRange(fromLineHead: Bool) -> NSRange? {
        
        return fromLineHead
            ? self.string.lineRange(for: self.selectedRange, excludingLastLineEnding: true)
            : self.selectedRange
    }
    
}



private extension String {
    
    /// append inline style comment delimiters in range inserting spacer after delimiters and return commented-out string and new selected range
    func inlineCommentOut(delimiter: String, spacer: String, range: NSRange, selectedRange: NSRange) -> (String, Int) {
        
        let target = (self as NSString).substring(with: range)
        
        let newString = delimiter + spacer + target.replacingOccurrences(of: "\n", with: "\n" + delimiter + spacer)
        let cursorOffset = newString.length - target.length
        
        return (newString, cursorOffset)
    }
    
    
    /// append block style comment delimiters in range inserting spacer between string and delimiters and return commented-out string and new selected range
    func blockCommentOut(delimiters: Pair<String>, spacer: String, range: NSRange, selectedRange: NSRange) -> (String, Int) {
        
        let target = (self as NSString).substring(with: range)
        
        let newString = delimiters.begin + spacer + target + spacer + delimiters.end
        let cursorOffset = delimiters.begin.length + spacer.length
        
        return (newString, cursorOffset)
    }
    
    
    /// remove inline style comment delimiters in range removing also spacers after delimiter and return uncommented string and new selected range
    func inlineUncomment(delimiter: String, spacer: String, range: NSRange, selectedRange: NSRange) -> (String, Int)? {
        
        let target = (self as NSString).substring(with: range)
        
        let newString = target.components(separatedBy: "\n")
            .map { $0.replacingOccurrences(of: delimiter, with: "", options: .anchored) }
            .map { spacer.isEmpty ? $0 : $0.replacingOccurrences(of: spacer, with: "", options: .anchored) }
            .joined(separator: "\n")
        let cursorOffset = newString.length - target.length
        
        guard cursorOffset != 0 else { return nil }
        
        return (newString, cursorOffset)
    }
    
    
    /// remove block style comment delimiters in range removing also spacers between string and delimiter and return uncommented string and new selected range
    func blockUncomment(delimiters: Pair<String>, spacer: String, range: NSRange, selectedRange: NSRange) -> (String, Int)? {
        
        let target = (self as NSString).substring(with: range)
        
        guard target.hasPrefix(delimiters.begin), target.hasSuffix(delimiters.end) else { return nil }
        
        var newString = target
            .replacingOccurrences(of: delimiters.begin, with: "", options: .anchored)
            .replacingOccurrences(of: delimiters.end, with: "", options: [.anchored, .backwards])
        var cursorOffset = -delimiters.begin.length
        
        if !spacer.isEmpty, newString.hasPrefix(spacer), newString.hasSuffix(spacer) {
            newString = target
                .replacingOccurrences(of: spacer, with: "", options: .anchored)
                .replacingOccurrences(of: spacer, with: "", options: [.anchored, .backwards])
            cursorOffset -= spacer.length
        }
        
        return (newString, cursorOffset)
    }
    
    
    /// create selected range after commenting-out/uncommenting
    func seletedRange(range: NSRange, selectedRange: NSRange, newString: String, offset: Int) -> NSRange {
        
        if selectedRange.length == 0 {
            return NSRange(location: selectedRange.location + offset, length: selectedRange.length)
        } else {
            return NSRange(location: range.location, length: (newString as NSString).length)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// NSString-style length
    private var length: Int {
        
        return self.utf16.count
    }
    
}
