/*
 
 CETextView+Commenting.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-10.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension CETextView {
    
    // MARK: Options
    
    struct CommentTypes: OptionSet {
        let rawValue: Int
        
        static let inline = CommentTypes(rawValue: 1 << 0)
        static let block  = CommentTypes(rawValue: 1 << 1)
        
        static let both: CommentTypes = [.inline, .block]
    }
    
    
    
    // MARK: Action Messages
    
    /// toggle comment state in selection
    @IBAction func toggleComment(_ sender: AnyObject?) {
        
        if self.canUncomment(range: self.selectedRange(), partly: false) {
            self.uncomment(types: .both, fromLineHead: UserDefaults.standard.bool(forKey: DefaultKey.commentsAtLineHead.rawValue))
        } else {
            self.commentOut(types: .both, fromLineHead: UserDefaults.standard.bool(forKey: DefaultKey.commentsAtLineHead.rawValue))
        }
    }
    
    
    /// comment out selection appending comment delimiters
    @IBAction func commentOut(_ sender: AnyObject?) {
        
        self.commentOut(types: .both, fromLineHead: false)
    }
    
    
    /// comment out selection appending block comment delimiters
    @IBAction func blockCommentOut(_ sender: AnyObject?) {
        
        self.commentOut(types: .block, fromLineHead: false)
    }
    
    
    /// comment out selection appending inline comment delimiters
    @IBAction func inlineCommentOut(_ sender: AnyObject?) {
        
        self.commentOut(types: .inline, fromLineHead: false)
    }
    
    
    /// uncomment selection removing comment delimiters
    @IBAction func uncomment(_ sender: AnyObject?) {
        
        self.uncomment(types: .both, fromLineHead: false)
    }
    
    
    
    // MARK: Public Methods
    
    /// comment out selection appending comment delimiters
    func commentOut(types: CommentTypes, fromLineHead: Bool) {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return }
        
        guard let string = self.string,
            let selectedRange = string.range(from: self.selectedRange()),
            let targetRange = self.commentingRange(fromLineHead: fromLineHead)
            else { return }
        
        let spacer = UserDefaults.standard.bool(forKey: DefaultKey.appendsCommentSpacer.rawValue) ? " " : ""
        var new: (String, NSRange)?
        
        // insert delimiters
        if let delimiter = self.inlineCommentDelimiter, types.contains(.inline) {
            new = string.inlineCommentOut(delimiter: delimiter, spacer: spacer, range: targetRange, selectedRange: selectedRange)
            
        } else if let blockDelimiters = self.blockCommentDelimiters, types.contains(.block) {
            let delimiters = BlockDelimiters(begin: blockDelimiters[CEBeginDelimiterKey]!, end: blockDelimiters[CEEndDelimiterKey]!)
            
            new = string.blockCommentOut(delimiters: delimiters, spacer: spacer, range: targetRange, selectedRange: selectedRange)
        }
        
        guard let (newString, newSelectedRange) = new else { return }
        
        self.replace(with: newString, range: string.nsRange(from: targetRange), selectedRange: newSelectedRange,
                     actionName: NSLocalizedString("Comment Out", comment: "action name"))
        
    }
    
    
    /// uncomment selection removing comment delimiters
    func uncomment(types: CommentTypes, fromLineHead: Bool) {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return }
        
        guard let string = self.string,
            let selectedRange = string.range(from: self.selectedRange()),
            let targetRange = self.commentingRange(fromLineHead: fromLineHead),
            !targetRange.isEmpty else { return }
        
        let spacer = UserDefaults.standard.bool(forKey: DefaultKey.appendsCommentSpacer.rawValue) ? " " : ""
        var new: (String, NSRange)?
        
        if let blockDelimiters = self.blockCommentDelimiters, types.contains(.block) {
            let delimiters = BlockDelimiters(begin: blockDelimiters[CEBeginDelimiterKey]!, end: blockDelimiters[CEEndDelimiterKey]!)
            
            new = string.blockUncomment(delimiters: delimiters, spacer: spacer, range: targetRange, selectedRange: selectedRange)
        }
        if let delimiter = self.inlineCommentDelimiter, types.contains(.inline) && new == nil {
            new = string.inlineUncomment(delimiter: delimiter, spacer: spacer, range: targetRange, selectedRange: selectedRange)
        }
        
        guard let (newString, newSelectedRange) = new else { return }
        
        self.replace(with: newString, range: string.nsRange(from: targetRange), selectedRange: newSelectedRange,
                     actionName: NSLocalizedString("Uncomment", comment: "action name"))
        
    }
    
    
    /// whether given range can be uncommented
    @objc(canUncommentRange:partly:)
    func canUncomment(range: NSRange, partly: Bool) -> Bool {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return false }
        
        guard
            let string = self.string,
            let targetRange = self.commentingRange(fromLineHead: UserDefaults.standard.bool(forKey: DefaultKey.commentsAtLineHead.rawValue)),
            !targetRange.isEmpty else { return false }
        
        let target = string.substring(with: targetRange)
        
        if let blockDelimiters = self.blockCommentDelimiters {
            let delimiters = BlockDelimiters(begin: blockDelimiters[CEBeginDelimiterKey]!, end: blockDelimiters[CEEndDelimiterKey]!)
            
            if target.hasPrefix(delimiters.begin) && target.hasSuffix(delimiters.end) {
                return true
            }
        }
        
        if let delimiter = self.inlineCommentDelimiter {
            let lines = target.components(separatedBy: "\n")
            var commentLineCount = 0
            for line in lines {
                if line.hasPrefix(delimiter) {
                    if partly { return true }
                    commentLineCount += 1
                }
            }
            return commentLineCount == lines.count
        }
        
        return false
    }
    
    
    
    // MARK: Private Methods
    
    /// return commenting target range
    private func commentingRange(fromLineHead: Bool) -> Range<String.Index>? {
        
        guard let string = self.string, let selectedRange = string.range(from: self.selectedRange()) else { return nil }
        
        var targetRange = fromLineHead ? string.lineRange(for: selectedRange) : selectedRange
        
        // remove last return
        if string.characters[string.index(before: targetRange.upperBound)] == "\n" {
            targetRange = targetRange.lowerBound..<string.index(before: targetRange.upperBound)
        }
        
        return targetRange
    }
    
}


private extension String {
    
    /// append inline style comment delimiters in range inserting spacer after delimiters and return commented-out string and new selected range
    func inlineCommentOut(delimiter: String, spacer: String, range: Range<Index>, selectedRange: Range<Index>) -> (String, NSRange) {
        
        let target = self.substring(with: range)
        
        let newString = delimiter + spacer + target.replacingOccurrences(of: "\n", with: "\n" + delimiter + spacer)
        let cursorOffset = newString.characters.count - target.characters.count
        
        let newSelectedRange = self.seletedRange(range: range, selectedRange: selectedRange, newString: newString, offset: cursorOffset)
        
        return (newString, newSelectedRange)
    }
    
    
    /// append block style comment delimiters in range inserting spacer between string and delimiters and return commented-out string and new selected range
    func blockCommentOut(delimiters: BlockDelimiters, spacer: String, range: Range<Index>, selectedRange: Range<Index>) -> (String, NSRange) {
        
        let target = self.substring(with: range)
        
        let newString = delimiters.begin + spacer + target + spacer + delimiters.end
        let cursorOffset = delimiters.begin.characters.count + spacer.characters.count
        
        let newSelectedRange = self.seletedRange(range: range, selectedRange: selectedRange, newString: newString, offset: cursorOffset)
        
        return (newString, newSelectedRange)
    }
    
    
    /// remove inline style comment delimiters in range removing also spacers after delimiter and return uncommented string and new selected range
    func inlineUncomment(delimiter: String, spacer: String, range: Range<Index>, selectedRange: Range<Index>) -> (String, NSRange)? {
        
        let target = self.substring(with: range)
        
        var cursorOffset = 0
        
        let lines = target.components(separatedBy: "\n")
        var newLines = [String]()
        for line in lines {
            var newLine = line
            if line.hasPrefix(delimiter) {
                newLine = line.substring(from: line.index(line.startIndex, offsetBy: delimiter.characters.count))
                cursorOffset -= delimiter.characters.count
                
                if !spacer.isEmpty && newLine.hasPrefix(spacer) {
                    newLine = newLine.substring(from: newLine.index(newLine.startIndex, offsetBy: spacer.characters.count))
                    cursorOffset -= spacer.characters.count
                }
            }
            
            newLines.append(newLine)
        }
        
        guard cursorOffset != 0 else { return nil }
        
        let newString = newLines.joined(separator: "\n")
        let newSelectedRange = self.seletedRange(range: range, selectedRange: selectedRange, newString: newString, offset: cursorOffset)
        
        return (newString, newSelectedRange)
    }
    
    
    /// remove block style comment delimiters in range removing also spacers between string and delimiter and return uncommented string and new selected range
    func blockUncomment(delimiters: BlockDelimiters, spacer: String, range: Range<Index>, selectedRange: Range<Index>) -> (String, NSRange)? {
        
        let target = self.substring(with: range)
        
        guard target.hasPrefix(delimiters.begin) && target.hasSuffix(delimiters.end) else { return nil }
        
        let trimFrom = target.index(target.startIndex, offsetBy: delimiters.begin.characters.count)
        let trimTo = target.index(target.endIndex, offsetBy: -delimiters.end.characters.count)
        var newString = target.substring(with: trimFrom..<trimTo)
        var cursorOffset = delimiters.begin.characters.count
        
        if !spacer.isEmpty && newString.hasPrefix(spacer) && newString.hasSuffix(spacer) {
            let trimFrom = newString.index(newString.startIndex, offsetBy: spacer.characters.count)
            let trimTo = newString.index(newString.endIndex, offsetBy: -spacer.characters.count)
            newString = newString.substring(with: trimFrom..<trimTo)
            cursorOffset -= spacer.characters.count
        }
        
        let newSelectedRange = self.seletedRange(range: range, selectedRange: selectedRange, newString: newString, offset: cursorOffset)
        
        return (newString, newSelectedRange)
    }
    
    
    
    // MARK: Private Methods
    
    /// create selected range after commenting-out/uncommenting
    private func seletedRange(range: Range<Index>, selectedRange: Range<Index>, newString: String, offset: Int) -> NSRange {
        
        if selectedRange.isEmpty {
            let selectedLocation = self.utf16.distance(from: self.utf16.startIndex, to: selectedRange.lowerBound.samePosition(in: self.utf16))
            return NSRange(location: selectedLocation + offset, length: 0)
        } else {
            let targetLocation = self.utf16.distance(from: self.utf16.startIndex, to: range.lowerBound.samePosition(in: self.utf16))
            return NSRange(location: targetLocation, length: newString.utf16.count)
        }
    }
    
}
