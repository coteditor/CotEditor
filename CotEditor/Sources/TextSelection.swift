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



// MARK: -

final class TextSelection: NSObject {
    
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
        
        return NSNameSpecifier(containerSpecifier: self.document!.objectSpecifier, key: "text selection")
    }
    
    
    
    // MARK: AppleScript Accessors
    
    /// string of the selection (Unicode text)
    @objc var contents: Any? {
        
        get {
            guard let string = self.document?.selectedString else { return nil }
            
            let textStorage = NSTextStorage(string: string)
            
            textStorage.observeDirectEditing { [weak self] (editedString) in
                self?.document?.insert(string: editedString)
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
            
            self.document?.insert(string: string)
        }
    }
    
    
    /// character range (location and length) of the selection
    @objc var range: [Int]? {
        
        get {
            guard let range = self.document?.selectedRange else { return nil }
            
            return [range.location, range.length]
        }
        
        set {
            guard
                newValue?.count == 2,
                let location = newValue?[0],
                let length = newValue?[1],
                let string = self.document?.string,
                let range = string.range(location: location, length: length)
                else { return }
            
            self.document?.selectedRange = range
        }
    }
    
    
    /// line range (location and length) of the selection (list type)
    @objc var lineRange: Any? {
        
        get {
            guard
                let selectedRange = self.document?.selectedRange,
                let string = self.document?.string else { return nil }
            
            let startLine = string.lineNumber(at: selectedRange.location)
            let endLine = string.lineNumber(at: selectedRange.upperBound)
            
            return [startLine,
                    endLine - startLine + 1]
        }
        
        set {
            let location: Int
            let length: Int
            
            switch newValue {
            case let number as Int:
                location = number
                length = 1
            case let range as [Int] where range.count == 2:
                location = range[0]
                length = range[1]
            default:
                return
            }
            
            // you can ignore actuall line ending type and directly comunicate with textView, as this handle just lines
            guard let string = self.textView?.string else { return }
            
            guard let range = string.rangeForLine(location: location, length: length) else { return }
            
            self.document?.selectedRange = range
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
        
        self.textView?.uncomment(types: .both, fromLineHead: false)
    }
    
    
    /// convert letters in the selection to lowercase, uppercase or capitalized
    @objc func handleChangeCase(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["caseType"] as? UInt32,
            let textView = self.textView else { return }
        
        let type = FourCharCode(argument)
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
    @objc func handleChangeWidthRoman(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["widthType"] as? UInt32,
            let textView = self.textView else { return }
        
        let type = FourCharCode(argument)
        switch type {
        case OSAWidthType.half:
            textView.exchangeHalfwidthRoman(command)
        case OSAWidthType.full:
            textView.exchangeFullwidthRoman(command)
        default: break
        }
    }
    
    
    /// convert Japanese Hiragana in the selection to Katakana or vice versa
    @objc func handleChangeKanaScript(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["kanaType"] as? UInt32,
            let textView = self.textView else { return }
        
        let type = FourCharCode(argument)
        switch type {
        case OSAKanaType.hiragana:
            textView.exchangeHiragana(command)
        case OSAKanaType.katakana:
            textView.exchangeKatakana(command)
        default: break
        }
    }
    
    
    /// Unicode normalization
    @objc func handleNormalizeUnicode(_ command: NSScriptCommand) {
        
        guard
            let argument = command.evaluatedArguments?["unfType"] as? UInt32,
            let textView = self.textView else { return }
        
        let type = FourCharCode(argument)
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
    
    
    
    // MARK: Private Methods
    
    private var textView: EditorTextView? {
        
        return self.document?.viewController?.focusedTextView
    }
    
}
