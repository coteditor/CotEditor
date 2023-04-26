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
//  © 2014-2023 1024jp
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
    case nfkcCF = "cNcf"
    case modifiedNFC = "cNmc"
    case modifiedNFD = "cNfm"
}



// MARK: -

final class TextSelection: NSObject {
    
    // MARK: Private Properties
    
    private weak var document: Document?  // weak to avoid cycle retain
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
        
        super.init()
    }
    
    
    private override init() { }
    
    
    /// return object name which is determined in the sdef file
    override var objectSpecifier: NSScriptObjectSpecifier? {
        
        NSNameSpecifier(containerSpecifier: self.document!.objectSpecifier, key: "text selection")
    }
    
    
    
    // MARK: AppleScript Accessors
    
    /// string of the selection (Unicode text)
    @objc var contents: Any? {
        
        get {
            guard let textView = self.textView else { return nil }
            
            let string = textView.selectedString
            let textStorage = NSTextStorage(string: string)
            
            textStorage.observeDirectEditing { (editedString) in
                textView.insert(string: editedString, at: .replaceSelection)
            }
            
            return textStorage
        }
        
        set {
            guard let string: String = {
                switch newValue {
                    case let storage as NSTextStorage:
                        return storage.string
                    case let string as String:
                        return string
                    default: return nil
                }
            }() else { return }
            
            self.textView?.insert(string: string, at: .replaceSelection)
        }
    }
    
    
    /// character range (location and length) of the selection
    @objc var range: [Int]? {
        
        get {
            guard let range = self.textView?.selectedRange else { return nil }
            
            return [range.location, range.length]
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
    
    
    /// line range (location and length) of the selection (list type)
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
    
    /// shift the selection to right
    @objc func handleShiftRight(_ command: NSScriptCommand) {
        
        self.textView?.shiftRight(command)
    }
    
    
    /// shift the selection to left
    @objc func handleShiftLeft(_ command: NSScriptCommand) {
        
        self.textView?.shiftLeft(command)
    }
    
    
    /// swap selected lines with the line just above
    @objc func handleMoveLineUp(_ command: NSScriptCommand) {
        
        self.textView?.moveLineUp(command)
    }
    
    
    /// swap selected lines with the line just below
    @objc func handleMoveLineDown(_ command: NSScriptCommand) {
        
        self.textView?.moveLineDown(command)
    }
    
    
    /// sort selected lines ascending
    @objc func handleSortLinesAscending(_ command: NSScriptCommand) {
        
        self.textView?.sortLinesAscending(command)
    }
    
    
    /// reverse selected lines
    @objc func handleReverseLines(_ command: NSScriptCommand) {
        
        self.textView?.reverseLines(command)
    }
    
    
    /// delete duplicate lines in selection
    @objc func handleDeleteDuplicateLine(_ command: NSScriptCommand) {
        
        self.textView?.deleteDuplicateLine(command)
    }
    
    
    /// uncomment the selection
    @objc func handleCommentOut(_ command: NSScriptCommand) {
        
        self.textView?.commentOut(types: .both, fromLineHead: false)
    }
    
    
    /// swap selected lines with the line just below
    @objc func handleUncomment(_ command: NSScriptCommand) {
        
        self.textView?.uncomment()
    }
    
    
    /// convert letters in the selection to lowercase, uppercase or capitalized
    @objc func handleChangeCase(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["caseType"] as? UInt32,
            let type = OSACaseType(rawValue: argument),
            let textView = self.textView
        else { return }
        
        switch type {
            case .lowercase:
                textView.lowercaseWord(command)
            case .uppercase:
                textView.uppercaseWord(command)
            case .capitalized:
                textView.capitalizeWord(command)
        }
    }
    
    
    /// convert half-width roman in the selection to full-width roman or vice versa
    @objc func handleChangeWidthRoman(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["widthType"] as? UInt32,
            let type = OSAWidthType(rawValue: argument),
            let textView = self.textView
        else { return }
        
        switch type {
            case .half:
                textView.exchangeHalfwidthRoman(command)
            case .full:
                textView.exchangeFullwidthRoman(command)
        }
    }
    
    
    /// convert Japanese Hiragana in the selection to Katakana or vice versa
    @objc func handleChangeKana(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["kanaType"] as? UInt32,
            let type = OSAKanaType(rawValue: argument),
            let textView = self.textView
        else { return }
        
        switch type {
            case .hiragana:
                textView.exchangeHiragana(command)
            case .katakana:
                textView.exchangeKatakana(command)
        }
    }
    
    
    /// convert straight quotes to typographical pairs
    @objc func handleSmartenQuotes(_ command: NSScriptCommand) {
        
        self.textView?.perform(Selector(("replaceQuotesInSelection:")))
    }
    
    
    /// convert typographical (curly) quotes to straight
    @objc func handleStraightenQuotes(_ command: NSScriptCommand) {
        
        self.textView?.straightenQuotesInSelection(command)
    }
    
    
    /// convert double hyphens to em dashes (—)
    @objc func handleSmartenDashes(_ command: NSScriptCommand) {
        
        self.textView?.perform(Selector(("replaceDashesInSelection:")))
    }
    
    
    /// Unicode normalization
    @objc func handleNormalizeUnicode(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["unfType"] as? UInt32,
            let type = OSAUnicodeNormalizationType(rawValue: argument),
            let textView = self.textView
        else { return }
        
        switch type {
            case .nfc:
                textView.normalizeUnicodeWithNFC(command)
            case .nfd:
                textView.normalizeUnicodeWithNFD(command)
            case .nfkc:
                textView.normalizeUnicodeWithNFKC(command)
            case .nfkd:
                textView.normalizeUnicodeWithNFKD(command)
            case .nfkcCF:
                textView.normalizeUnicodeWithNFKCCF(command)
            case .modifiedNFC:
                textView.normalizeUnicodeWithModifiedNFC(command)
            case .modifiedNFD:
                textView.normalizeUnicodeWithModifiedNFD(command)
        }
    }
    
    
    
    // MARK: Private Methods
    
    private var textView: EditorTextView? {
        
        self.document?.textView as? EditorTextView
    }
}
