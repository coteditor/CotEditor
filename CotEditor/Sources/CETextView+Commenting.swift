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
    
    // MARK: Action Messages
    
    /// toggle comment state in selection
    @IBAction func toggleComment(_ sender: AnyObject?) {
        
        if self.canUncomment(range: self.selectedRange()) {
            self.uncomment(sender)
        } else {
            self.commentOut(sender)
        }
    }
    
    
    /// comment out selection appending comment delimiters
    @IBAction func commentOut(_ sender: AnyObject?) {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return }
        
        guard let string = self.string, let selectedRange = string.range(from: self.selectedRange()) else { return }
        
        // determine comment out target
        var targetRange = selectedRange
        if !(sender is NSScriptCommand) && UserDefaults.standard.bool(forKey: CEDefaultCommentsAtLineHeadKey) {
            targetRange = string.lineRange(for: targetRange)
        }
        
        // remove last return
        if string.characters[string.index(before: targetRange.upperBound)] == "\n" {
            targetRange = targetRange.lowerBound..<string.index(before: targetRange.upperBound)
        }
        
        let target = string.substring(with: targetRange)
        
        let spacer = UserDefaults.standard.bool(forKey: CEDefaultAppendsCommentSpacerKey) ? " " : ""
        let newString: String
        let offsetBeforeCursor: Int
        
        // insert delimiters
        if let delimiter = self.inlineCommentDelimiter {
            newString = delimiter + spacer + target.replacingOccurrences(of: "\n", with: "\n" + delimiter + spacer)
            offsetBeforeCursor = newString.characters.count - target.characters.count
            
        } else if let delimiters = self.blockCommentDelimiters {
            let begin = delimiters[CEBeginDelimiterKey]!
            let end = delimiters[CEEndDelimiterKey]!
            
            newString = begin + spacer + target + spacer + end
            offsetBeforeCursor = begin.characters.count + spacer.characters.count
        } else { return }
        
        // set selection
        let selected: NSRange
        if selectedRange.isEmpty {
            let selectedLocation = string.utf16.distance(from: string.utf16.startIndex, to: selectedRange.lowerBound.samePosition(in: string.utf16))
            selected = NSRange(location: selectedLocation + offsetBeforeCursor, length: 0)
        } else {
            let targetLocation = string.utf16.distance(from: string.utf16.startIndex, to: targetRange.lowerBound.samePosition(in: string.utf16))
            selected = NSRange(location: targetLocation, length: newString.utf16.count)
        }
        
        // replace
        self.replace(with: newString, range: string.nsRange(from: targetRange), selectedRange: selected,
                     actionName: NSLocalizedString("Comment Out", comment: "action name"))
    }
    
    
    /// uncomment selection removing comment delimiters
    @IBAction func uncomment(_ sender: AnyObject?) {
        
        guard let string = self.string, let selectedRange = string.range(from: self.selectedRange()) else { return }
        
        // determine comment out target
        var targetRange = selectedRange
        if !(sender is NSScriptCommand) && UserDefaults.standard.bool(forKey: CEDefaultCommentsAtLineHeadKey) {
            targetRange = string.lineRange(for: targetRange)
        }
        
        // remove last return
        if string.characters[string.index(before: targetRange.upperBound)] == "\n" {
            targetRange = targetRange.lowerBound..<string.index(before: targetRange.upperBound)
        }
        
        let target = string.substring(with: targetRange)
        
        guard !target.isEmpty else { return }
        
        let spacer = UserDefaults.standard.bool(forKey: CEDefaultAppendsCommentSpacerKey) ? " " : ""
        var newString: String
        var offsetBeforeCursor = 0
        
        
        // block comment
        if let delimiters = self.blockCommentDelimiters where target.hasPrefix(delimiters[CEBeginDelimiterKey]!) && target.hasSuffix(delimiters[CEEndDelimiterKey]!) {
            let begin = delimiters[CEBeginDelimiterKey]!
            let end = delimiters[CEEndDelimiterKey]!
            
                let trimFrom = target.index(target.startIndex, offsetBy: begin.characters.count)
                let trimTo = target.index(target.endIndex, offsetBy: -end.characters.count)
                newString = target.substring(with: trimFrom..<trimTo)
                offsetBeforeCursor -= begin.characters.count
                
                if !spacer.isEmpty && newString.hasPrefix(spacer) && newString.hasSuffix(spacer) {
                    let trimFrom = newString.index(newString.startIndex, offsetBy: spacer.characters.count)
                    let trimTo = newString.index(newString.endIndex, offsetBy: -spacer.characters.count)
                    newString = newString.substring(with: trimFrom..<trimTo)
                    offsetBeforeCursor -= spacer.characters.count
                }
        }
        
        // inline comment
        else if let delimiter = self.inlineCommentDelimiter {
            let lines = target.components(separatedBy: "\n")
            var newLines = [String]()
            for line in lines {
                var newLine = line
                if line.hasPrefix(delimiter) {
                    newLine = line.substring(from: line.index(line.startIndex, offsetBy: delimiter.characters.count))
                    offsetBeforeCursor -= delimiter.characters.count
                    
                    if !spacer.isEmpty && newLine.hasPrefix(spacer) {
                        newLine = newLine.substring(from: newLine.index(newLine.startIndex, offsetBy: spacer.characters.count))
                        offsetBeforeCursor -= spacer.characters.count
                    }
                }
                
                newLines.append(newLine)
            }
            
            newString = newLines.joined(separator: "\n")
            
        } else { return }
        
        guard offsetBeforeCursor != 0 else { return }
        
        // set selection
        let selected: NSRange
        if selectedRange.isEmpty {
            let selectedLocation = string.utf16.distance(from: string.utf16.startIndex, to: selectedRange.lowerBound.samePosition(in: string.utf16))
            selected = NSRange(location: selectedLocation + offsetBeforeCursor, length: 0)
        } else {
            let targetLocation = string.utf16.distance(from: string.utf16.startIndex, to: targetRange.lowerBound.samePosition(in: string.utf16))
            selected = NSRange(location: targetLocation, length: newString.utf16.count)
        }
        
        // replace
        self.replace(with: newString, range: string.nsRange(from: targetRange), selectedRange: selected,
                     actionName: NSLocalizedString("Uncomment", comment: "action name"))
    }
    
    
    
    // MARK: Semi-Private Methods
    
    /// whether given range can be uncommented
    @objc(canUncommentRange:)
    func canUncomment(range: NSRange) -> Bool {
        
        guard self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil else { return false }
        guard let string = self.string,
            var targetRange = string.range(from: range) else { return false }
        
        // determine comment out target
        if UserDefaults.standard.bool(forKey: CEDefaultCommentsAtLineHeadKey) {
            targetRange = string.lineRange(for: targetRange)
        }
        
        // remove last return
        if string.characters[string.index(before: targetRange.upperBound)] == "\n" {
            targetRange = targetRange.lowerBound..<string.index(before: targetRange.upperBound)
        }
        
        let target = string.substring(with: targetRange)
        
        guard !targetRange.isEmpty else { return false }
        
        if let delimiters = self.blockCommentDelimiters {
            if target.hasPrefix(delimiters[CEBeginDelimiterKey]!) &&
               target.hasSuffix(delimiters[CEEndDelimiterKey]!)
            {
                return true
            }
        }
        
        if let delimiter = self.inlineCommentDelimiter {
            let lines = target.components(separatedBy: "\n")
            var commentLineCount = 0
            for line in lines {
                if line.hasPrefix(delimiter) {
                    commentLineCount += 1
                }
            }
            return commentLineCount == lines.count
        }
        
        return false
    }
    
}
