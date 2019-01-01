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
//  © 2014-2018 1024jp
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
        
        if self.canUncomment(range: self.selectedRange, partly: false) {
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
        
        let string = self.string
        
        guard
            let selectedRange = Range(self.selectedRange, in: string),
            let targetRange = self.commentingRange(fromLineHead: fromLineHead)
            else { return }
        
        let spacer = self.appendsCommentSpacer ? " " : ""
        var new: (String, NSRange)?
        
        // insert delimiters
        if let delimiter = self.inlineCommentDelimiter, types.contains(.inline) {
            new = string.inlineCommentOut(delimiter: delimiter, spacer: spacer, range: targetRange, selectedRange: selectedRange)
            
        } else if let delimiters = self.blockCommentDelimiters, types.contains(.block) {
            new = string.blockCommentOut(delimiters: delimiters, spacer: spacer, range: targetRange, selectedRange: selectedRange)
        }
        
        guard let (newString, newSelectedRange) = new else { return }
        
        self.replace(with: newString, range: NSRange(targetRange, in: string), selectedRange: newSelectedRange,
                     actionName: "Comment Out".localized)
    }
    
    
    /// uncomment selection removing comment delimiters
    func uncomment(types: CommentTypes, fromLineHead: Bool) {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return }
        
        let string = self.string
        
        guard
            let selectedRange = Range(self.selectedRange, in: string),
            let targetRange = self.commentingRange(fromLineHead: fromLineHead),
            !targetRange.isEmpty else { return }
        
        let spacer = self.appendsCommentSpacer ? " " : ""
        var new: (String, NSRange)?
        
        if let delimiters = self.blockCommentDelimiters, types.contains(.block) {
            new = string.blockUncomment(delimiters: delimiters, spacer: spacer, range: targetRange, selectedRange: selectedRange)
        }
        if let delimiter = self.inlineCommentDelimiter, types.contains(.inline), new == nil {
            new = string.inlineUncomment(delimiter: delimiter, spacer: spacer, range: targetRange, selectedRange: selectedRange)
        }
        
        guard let (newString, newSelectedRange) = new else { return }
        
        self.replace(with: newString, range: NSRange(targetRange, in: string), selectedRange: newSelectedRange,
                     actionName: "Uncomment".localized)
    }
    
    
    /// whether given range can be uncommented
    func canUncomment(range: NSRange, partly: Bool) -> Bool {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return false }
        
        guard
            let targetRange = self.commentingRange(fromLineHead: self.commentsAtLineHead),
            !targetRange.isEmpty else { return false }
        
        let target = self.string[targetRange]
        
        if let delimiters = self.blockCommentDelimiters {
            if target.hasPrefix(delimiters.begin), target.hasSuffix(delimiters.end) {
                return true
            }
        }
        
        if let delimiter = self.inlineCommentDelimiter {
            let lines = target.components(separatedBy: "\n")
            var commentLineCount = 0
            for line in lines where line.hasPrefix(delimiter) {
                if partly { return true }
                commentLineCount += 1
            }
            return commentLineCount == lines.count
        }
        
        return false
    }
    
    
    
    // MARK: Private Methods
    
    /// return commenting target range
    private func commentingRange(fromLineHead: Bool) -> Range<String.Index>? {
        
        guard let selectedRange = Range(self.selectedRange, in: self.string) else { return nil }
        
        return fromLineHead ? self.string.lineRange(for: selectedRange, excludingLastLineEnding: true) : selectedRange
    }
    
}



private extension StringProtocol where Self.Index == String.Index {
    
    /// append inline style comment delimiters in range inserting spacer after delimiters and return commented-out string and new selected range
    func inlineCommentOut(delimiter: String, spacer: String, range: Range<Index>, selectedRange: Range<Index>) -> (String, NSRange) {
        
        let target = self[range]
        
        let newString = delimiter + spacer + target.replacingOccurrences(of: "\n", with: "\n" + delimiter + spacer)
        let cursorOffset = newString.count - target.count
        
        let newSelectedRange = self.seletedRange(range: range, selectedRange: selectedRange, newString: newString, offset: cursorOffset)
        
        return (newString, newSelectedRange)
    }
    
    
    /// append block style comment delimiters in range inserting spacer between string and delimiters and return commented-out string and new selected range
    func blockCommentOut(delimiters: Pair<String>, spacer: String, range: Range<Index>, selectedRange: Range<Index>) -> (String, NSRange) {
        
        let target = self[range]
        
        let newString = delimiters.begin + spacer + target + spacer + delimiters.end
        let cursorOffset = delimiters.begin.count + spacer.count
        
        let newSelectedRange = self.seletedRange(range: range, selectedRange: selectedRange, newString: newString, offset: cursorOffset)
        
        return (newString, newSelectedRange)
    }
    
    
    /// remove inline style comment delimiters in range removing also spacers after delimiter and return uncommented string and new selected range
    func inlineUncomment(delimiter: String, spacer: String, range: Range<Index>, selectedRange: Range<Index>) -> (String, NSRange)? {
        
        let target = self[range]
        
        let lines = target.components(separatedBy: "\n")
        let newLines: [String] = lines.map { line in
            guard line.hasPrefix(delimiter) else { return line }
            
            let newLine = line.dropFirst(delimiter.count)
            
            guard !spacer.isEmpty, newLine.hasPrefix(spacer) else { return String(newLine) }
            
            return String(newLine.dropFirst(spacer.count))
        }
        
        let newString = newLines.joined(separator: "\n")
        let cursorOffset = -(target.count - newString.count)
        
        guard cursorOffset != 0 else { return nil }
        
        let newSelectedRange = self.seletedRange(range: range, selectedRange: selectedRange, newString: newString, offset: cursorOffset)
        
        return (newString, newSelectedRange)
    }
    
    
    /// remove block style comment delimiters in range removing also spacers between string and delimiter and return uncommented string and new selected range
    func blockUncomment(delimiters: Pair<String>, spacer: String, range: Range<Index>, selectedRange: Range<Index>) -> (String, NSRange)? {
        
        let target = self[range]
        
        guard target.hasPrefix(delimiters.begin), target.hasSuffix(delimiters.end) else { return nil }
        
        let trimFrom = target.index(target.startIndex, offsetBy: delimiters.begin.count)
        let trimTo = target.index(target.endIndex, offsetBy: -delimiters.end.count)
        var substring = target[trimFrom..<trimTo]
        var cursorOffset = -delimiters.begin.count
        
        if !spacer.isEmpty, substring.hasPrefix(spacer), substring.hasSuffix(spacer) {
            let trimFrom = substring.index(substring.startIndex, offsetBy: spacer.count)
            let trimTo = substring.index(substring.endIndex, offsetBy: -spacer.count)
            substring = substring[trimFrom..<trimTo]
            cursorOffset -= spacer.count
        }
        
        let newString = String(substring)
        let newSelectedRange = self.seletedRange(range: range, selectedRange: selectedRange, newString: newString, offset: cursorOffset)
        
        return (newString, newSelectedRange)
    }
    
    
    
    // MARK: Private Methods
    
    /// create selected range after commenting-out/uncommenting
    private func seletedRange(range: Range<Index>, selectedRange: Range<Index>, newString: String, offset: Int) -> NSRange {
        
        var nsRange: NSRange
        
        if selectedRange.isEmpty {
            nsRange = NSRange(selectedRange, in: self)
            nsRange.location += offset
        } else {
            nsRange = NSRange(range, in: self)
            nsRange.length = newString.utf16.count
        }
        
        return nsRange
    }
    
}
