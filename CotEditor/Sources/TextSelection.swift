/*
 
 TextSelection.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-03-01.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

typealias OSACaseType = FourCharCode
private extension OSACaseType {
    
    static let lowercase = FourCharCode(code: "cClw")
    static let uppercase = FourCharCode(code: "cCup")
    static let capitalized = FourCharCode(code: "cCcp")
}


typealias OSAWidthType = FourCharCode
private extension OSAWidthType {
    
    static let full = FourCharCode(code: "rWfl")
    static let half = FourCharCode(code: "rWhf")
}


typealias OSAKanaType = FourCharCode
private extension OSAKanaType {
    
    static let hiragana = FourCharCode(code: "cHgn")
    static let katakana = FourCharCode(code: "cKkn")
}


typealias OSAUnicodeNormalizationType = FourCharCode
private extension OSAUnicodeNormalizationType {
    
    static let NFC = FourCharCode(code: "cNfc")
    static let NFD = FourCharCode(code: "cNfd")
    static let NFKC = FourCharCode(code: "cNkc")
    static let NFKD = FourCharCode(code: "cNkd")
    static let NFKCCF = FourCharCode(code: "cNcf")
    static let modifiedNFC = FourCharCode(code: "cNmc")
    static let modifiedNFD = FourCharCode(code: "cNfm")
}



// MARK:

class TextSelection: NSObject {
    
    private weak var document: Document?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
    }
    
    
    private override init() { }
    
    
    /// return object name which is determined in the sdef file
    override var objectSpecifier: NSScriptObjectSpecifier? {
        
        return NSNameSpecifier(containerSpecifier: self.document!.objectSpecifier, key: "text selection")
    }
    
    
    
    // MARK: AppleScript Accessors
    
    /// string of the selection (Unicode text)
    var contents: AnyObject? {
        get {
            guard let document = self.document, let editor = document.editor else { return nil }
            
            var string = editor.substringWithSelection!
            
            // apply line endings
            string = string.replacingLineEndings(with: document.lineEnding)
            
            let storage = NSTextStorage(string: string)
            
            return storage
        }
        
        set (object) {
            let string: String
            
            if let storage = object as? NSTextStorage {
                string = storage.string
            } else if let stringObject = object as? String {
                string = stringObject
            } else {
                return
            }
            
            self.document?.editor?.insert(string: string)
        }
    }
    
    
    /// character range (location and length) of the selection
    var range: [NSNumber]? {
        get {
            guard let range = self.document?.editor?.selectedRange else { return nil }
            
            return [NSNumber(value: range.location),
                    NSNumber(value: range.length)]
        }
        set (range) {
            guard
                range?.count == 2,
                let location = range?[0].intValue,
                let length = range?[1].intValue else { return }
            
            self.document?.editor?.setSelectedCharacterRange(location: location, length: length)
        }
    }
    
    
    /// line range (location and length) of the selection (list type)
    var lineRange: AnyObject? {
        get {
            guard
                let selectedRange = self.document?.editor?.selectedRange,
                let string = self.document?.string else { return nil }
            
            let startLine = string.lineNumber(at: selectedRange.location)
            let endLine = string.lineNumber(at: selectedRange.max)
            
            return [NSNumber(value: startLine),
                    NSNumber(value: endLine - startLine + 1)]
        }
        set (range) {
            let location: Int
            let length: Int
            
            if let number = range as? NSNumber {
                location = number.intValue
                length = 1
            } else if let range = range as? [NSNumber], range.count == 2 {
                location = range[0].intValue
                length = range[1].intValue
            } else {
                return
            }
            
            self.document?.editor?.setSelectedLineRange(location: location, length: length)
        }
    }
    
    
    // MARK: AppleScript Handlers
    
    /// shift the selection to right
    func handleShiftRight(_ command: NSScriptCommand) {
        
        self.textView?.shiftRight(command)
    }
    
    
    /// shift the selection to left
    func handleShiftLeft(_ command: NSScriptCommand) {
        
        self.textView?.shiftLeft(command)
    }
    
    
    /// swap selected lines with the line just above
    func handleMoveLineUp(_ command: NSScriptCommand) {
        
        self.textView?.moveLineUp(command)
    }
    
    
    /// swap selected lines with the line just below
    func handleMoveLineDown(_ command: NSScriptCommand) {
        
        self.textView?.moveLineDown(command)
    }
    
    
    /// sort selected lines ascending
    func handleSortLinesAscending(_ command: NSScriptCommand) {
        
        self.textView?.sortLinesAscending(command)
    }
    
    
    /// reverse selected lines
    func handleReverseLines(_ command: NSScriptCommand) {
        
        self.textView?.reverseLines(command)
    }
    
    
    /// delete duplicate lines in selection
    func handleDeleteDuplicateLine(_ command: NSScriptCommand) {
        
        self.textView?.deleteDuplicateLine(command)
    }
    
    
    /// uncomment the selection
    func handleCommentOut(_ command: NSScriptCommand) {
        
        self.textView?.commentOut(types: .both, fromLineHead: false)
    }
    
    
    /// swap selected lines with the line just below
    func handleUncomment(_ command: NSScriptCommand) {
        
        self.textView?.uncomment(types: .both, fromLineHead: false)
    }
    
    
    /// convert letters in the selection to lowercase, uppercase or capitalized
    func handleChangeCase(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["caseType"] as? NSNumber,
            let textView = self.textView else { return }
        
        let type = FourCharCode(argument.uint32Value)
        switch type {
        case OSACaseType.lowercase:
            textView.lowercaseWord(command)
        case OSACaseType.uppercase:
            textView.uppercaseWord(command)
        case OSACaseType.capitalized:
            textView.capitalizeWord(command)
        default: break
        }
    }
    
    
    /// convert half-width roman in the selection to full-width roman or vice versa
    func handleChangeWidthRoman(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["widthType"] as? NSNumber,
            let textView = self.textView else { return }
        
        let type = FourCharCode(argument.uint32Value)
        switch type {
        case OSAWidthType.half:
            textView.exchangeHalfwidthRoman(command)
        case OSAWidthType.full:
            textView.exchangeFullwidthRoman(command)
        default: break
        }
    }
    
    
    /// convert Japanese Hiragana in the selection to Katakana or vice versa
    func handleChangeKanaScript(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["kanaType"] as? NSNumber,
            let textView = self.textView else { return }
        
        let type = FourCharCode(argument.uint32Value)
        switch type {
        case OSAKanaType.hiragana:
            textView.exchangeHiragana(command)
        case OSAKanaType.katakana:
            textView.exchangeKatakana(command)
        default: break
        }
        
    }
    
    
    /// Unicode normalization
    func handleNormalizeUnicode(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["unfType"] as? NSNumber,
            let textView = self.textView else { return }
        
        let type = FourCharCode(argument.uint32Value)
        switch type {
        case OSAUnicodeNormalizationType.NFC:
            textView.normalizeUnicodeWithNFC(command)
        case OSAUnicodeNormalizationType.NFD:
            textView.normalizeUnicodeWithNFD(command)
        case OSAUnicodeNormalizationType.NFKC:
            textView.normalizeUnicodeWithNFKC(command)
        case OSAUnicodeNormalizationType.NFKD:
            textView.normalizeUnicodeWithNFKD(command)
        case OSAUnicodeNormalizationType.NFKCCF:
            textView.normalizeUnicodeWithNFKCCF(command)
        case OSAUnicodeNormalizationType.modifiedNFC:
            textView.normalizeUnicodeWithModifiedNFC(command)
        case OSAUnicodeNormalizationType.modifiedNFD:
            textView.normalizeUnicodeWithModifiedNFD(command)
        default: break
        }
    }
    
    
    
    // MARK: Delegate
    
    /// text strage as AppleScript's return value did update
    override func textStorageDidProcessEditing(_ notification: Notification) {
        
        guard let storage = notification.object as? NSTextStorage else { return }
        
        self.document?.editor?.insert(string: storage.string)
        storage.delegate = nil
    }
    
    
    
    // MARK: Private Methods
    
    private var textView: EditorTextView? {
        
        return self.document?.editor?.focusedTextView
    }
    
}
