//
//  TextSelection.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-03-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2025 1024jp
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
import FuzzyRange
import StringUtils

private enum OSACaseType: FourCharCode {
    
    case lowercase = "cClw"
    case uppercase = "cCup"
    case capitalized = "cCcp"
}


private enum OSAWidthType: FourCharCode {
    
    case full = "rWfl"
    case half = "rWhf"
}


private enum OSAKanaType: FourCharCode {
    
    case hiragana = "cHgn"
    case katakana = "cKkn"
}


private enum OSAUnicodeNormalizationType: FourCharCode {
    
    case nfc = "cNfc"
    case nfd = "cNfd"
    case nfkc = "cNkc"
    case nfkd = "cNkd"
    case nfkcCasefold = "cNcf"
    case modifiedNFC = "cNmc"
    case modifiedNFD = "cNfm"
    
    
    var form: UnicodeNormalizationForm {
        
        switch self {
            case .nfc: .nfc
            case .nfd: .nfd
            case .nfkc: .nfkc
            case .nfkd: .nfkd
            case .nfkcCasefold: .nfkcCaseFold
            case .modifiedNFC: .modifiedNFC
            case .modifiedNFD: .modifiedNFD
        }
    }
}


// MARK: -

@MainActor final class TextSelection: NSObject {
    
    // MARK: Private Properties
    
    private weak var document: Document?  // weak to avoid cycle retain
    private let documentSpecifier: NSScriptObjectSpecifier
    
    
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
        self.documentSpecifier = document.objectSpecifier
    }
    
    
    /// Returns object name which is determined in the sdef file.
     override var objectSpecifier: NSScriptObjectSpecifier? {
        
         NSNameSpecifier(containerSpecifier: self.documentSpecifier, key: "text selection")
    }
    
    
    // MARK: AppleScript Accessors
    
    /// The string of the selection (Unicode text).
    @objc var contents: Any? {
        
        get {
            guard let textView = self.textView else { return nil }
            
            let string = textView.selectedString
            let textStorage = NSTextStorage(string: string)
            if self.isEditable {
                textStorage.observeDirectEditing { [weak textView] editedString in
                    textView?.insert(string: editedString, at: .replaceSelection)
                }
            }
            
            return textStorage
        }
        
        set {
            guard
                self.isEditable,
                let newValue,
                let string = String(anyString: newValue)
            else { return }
            
            self.textView?.insert(string: string, at: .replaceSelection)
        }
    }
    
    
    /// The character range (location and length) of the selection.
    @objc var range: [Int]? {
        
        get {
            guard
                let textView = self.textView,
                let string = self.textView?.string,
                let range = Range(textView.selectedRange, in: string)
            else { return nil }
            
            return [string.distance(from: string.startIndex, to: range.lowerBound),
                    string.distance(from: range.lowerBound, to: range.upperBound)]
        }
        
        set {
            guard
                newValue?.count == 2,
                let location = newValue?[0],
                let length = newValue?[1],
                let textView = self.textView,
                let range = textView.string.range(in: FuzzyRange(location: location, length: length))
            else { return }
            
            textView.selectedRange = range
        }
    }
    
    
    /// The line range (location and length) of the selection (list type).
    @objc var lineRange: [Int]? {
        
        get {
            guard let textView = self.textView else { return nil }
            
            let selectedRange = textView.selectedRange
            let string = textView.string
            
            let start = string.lineNumber(at: selectedRange.lowerBound)
            let end = string.lineNumber(at: selectedRange.upperBound)
            
            return [start, end - start + 1]
        }
        
        set {
            guard
                let lineRange = newValue,
                (1...2).contains(lineRange.count),
                let textView = self.textView
            else { return }
            
            let fuzzyRange = FuzzyRange(location: lineRange[0], length: lineRange[safe: 1] ?? 1)
            
            guard let range = textView.string.rangeForLine(in: fuzzyRange) else { return }
            
            textView.selectedRange = range
        }
    }
    
    
    // MARK: AppleScript Handlers
    
    /// Shifts the selection to right.
    @objc func handleShiftRight(_ command: NSScriptCommand) {
        
        self.textView?.shiftRight(command)
    }
    
    
    /// Shifts the selection to left.
    @objc func handleShiftLeft(_ command: NSScriptCommand) {
        
        self.textView?.shiftLeft(command)
    }
    
    
    /// Swaps selected lines with the line just above.
    @objc func handleMoveLineUp(_ command: NSScriptCommand) {
        
        self.textView?.moveLineUp(command)
    }
    
    
    /// Swaps selected lines with the line just below.
    @objc func handleMoveLineDown(_ command: NSScriptCommand) {
        
        self.textView?.moveLineDown(command)
    }
    
    
    /// Sorts selected lines ascending.
    @objc func handleSortLinesAscending(_ command: NSScriptCommand) {
        
        self.textView?.sortLinesAscending(command)
    }
    
    
    /// Reverses selected lines.
    @objc func handleReverseLines(_ command: NSScriptCommand) {
        
        self.textView?.reverseLines(command)
    }
    
    
    /// Deletes duplicate lines in the selection.
    @objc func handleDeleteDuplicateLine(_ command: NSScriptCommand) {
        
        self.textView?.deleteDuplicateLine(command)
    }
    
    
    /// Uncomments the selection.
    @objc func handleCommentOut(_ command: NSScriptCommand) {
        
        self.textView?.commentOut(types: .both, fromLineHead: false)
    }
    
    
    /// Swaps the selected lines with the line just below.
    @objc func handleUncomment(_ command: NSScriptCommand) {
        
        self.textView?.uncomment()
    }
    
    
    /// Converts letters in the selection to lowercase, uppercase, or capitalized.
    @objc func handleChangeCase(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["caseType"] as? UInt32,
            let type = OSACaseType(rawValue: argument)
        else {
            command.scriptErrorNumber = OSAParameterMismatch
            return
        }
        
        switch type {
            case .lowercase:
                self.textView?.lowercaseWord(command)
            case .uppercase:
                self.textView?.uppercaseWord(command)
            case .capitalized:
                self.textView?.capitalizeWord(command)
        }
    }
    
    
    /// Converts half-width roman in the selection to full-width roman or vice versa.
    @objc func handleChangeWidthRoman(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["widthType"] as? UInt32,
            let type = OSAWidthType(rawValue: argument)
        else {
            command.scriptErrorNumber = OSAParameterMismatch
            return
        }
        
        switch type {
            case .half:
                self.textView?.exchangeHalfwidthRoman(command)
            case .full:
                self.textView?.exchangeFullwidthRoman(command)
        }
    }
    
    
    /// Converts Japanese Hiragana in the selection to Katakana or vice versa.
    @objc func handleChangeKana(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["kanaType"] as? UInt32,
            let type = OSAKanaType(rawValue: argument)
        else {
            command.scriptErrorNumber = OSAParameterMismatch
            return
        }
        
        switch type {
            case .hiragana:
                self.textView?.exchangeHiragana(command)
            case .katakana:
                self.textView?.exchangeKatakana(command)
        }
    }
    
    
    /// Converts straight quotes to typographical pairs.
    @objc func handleSmartenQuotes(_ command: NSScriptCommand) {
        
        self.textView?.perform(Selector(("replaceQuotesInSelection:")))
    }
    
    
    /// Converts typographical (curly) quotes to straight.
    @objc func handleStraightenQuotes(_ command: NSScriptCommand) {
        
        self.textView?.straightenQuotesInSelection(command)
    }
    
    
    /// Converts double hyphens to em dashes (—).
    @objc func handleSmartenDashes(_ command: NSScriptCommand) {
        
        self.textView?.perform(Selector(("replaceDashesInSelection:")))
    }
    
    
    /// Performs Unicode normalization.
    @objc func handleNormalizeUnicode(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["unfType"] as? UInt32,
            let type = OSAUnicodeNormalizationType(rawValue: argument)
        else {
            command.scriptErrorNumber = OSAParameterMismatch
            return
        }
        
        self.textView?.normalizeUnicode(form: type.form)
    }
    
    
    // MARK: Private Methods
    
    /// Whether the document is editable.
    private var isEditable: Bool {
        
        self.document?.isEditable == true
    }
    
    
    private var textView: EditorTextView? {
        
        self.document?.textView as? EditorTextView
    }
}
