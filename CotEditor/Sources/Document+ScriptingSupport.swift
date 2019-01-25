//
//  Document+ScriptingSupport.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-03-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
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

typealias OSALineEnding = FourCharCode
private extension OSALineEnding {
    
    static let lf = FourCharCode(code: "leLF")
    static let cr = FourCharCode(code: "leCR")
    static let crlf = FourCharCode(code: "leCL")
}


extension Document {
    
    // MARK: AppleScript Accessors
    
    /// whole document string (text (NSTextStorage))
    @objc var scriptTextStorage: Any {
        
        get {
            let textStorage = NSTextStorage(string: self.string)
            
            textStorage.observeDirectEditing { [weak self] (editedString) in
                self?.insert(string: editedString, at: .replaceAll)
            }
            
            return textStorage
        }
        
        set {
            switch newValue {
            case let textStorage as NSTextStorage:
                self.insert(string: textStorage.string, at: .replaceAll)
                
            case let string as String:
                self.insert(string: string, at: .replaceAll)
                
            default:
                assertionFailure()
            }
        }
    }
    
    
    /// document string (text (NSTextStorage))
    @objc var contents: Any {
        
        get {
            return self.scriptTextStorage
        }
        
        set {
            self.scriptTextStorage = newValue
        }
    }
    
    
    /// selection-object (TextSelection)
    @objc var selectionObject: Any {
        
        get {
            return self.selection
        }
        
        set {
            guard let string = newValue as? String else { return }
            
            self.selection.contents = string
        }
    }
    
    
    /// length of document (integer)
    @objc var length: Int {
        
        return (self.string as NSString).length
    }
    
    
    /// new line code (enum type)
    @objc var lineEndingChar: FourCharCode {
        
        get {
            switch self.lineEnding {
            case .lf:
                return OSALineEnding.lf
            case .cr:
                return OSALineEnding.cr
            case .crlf:
                return OSALineEnding.crlf
            default:
                return OSALineEnding.lf
            }
        }
        
        set {
            let type: LineEnding = {
                switch newValue {
                case OSALineEnding.lf:
                    return .lf
                case OSALineEnding.cr:
                    return .cr
                case OSALineEnding.crlf:
                    return .crlf
                default:
                    return .lf
                }
            }()
            self.changeLineEnding(to: type)
        }
    }
    
    
    /// encoding name (Unicode text)
    @objc var encodingName: String {
        
        return String.localizedName(of: self.encoding)
    }
    
    
    /// encoding in IANA CharSet name (Unicode text)
    @objc var IANACharSetName: String {
        
        return self.encoding.ianaCharSetName ?? ""
    }
    
    
    /// syntax style name (Unicode text)
    @objc var coloringStyle: String {
        
        get {
            return self.syntaxParser.style.name
        }
        
        set {
            self.setSyntaxStyle(name: newValue)
        }
    }
    
    
    /// state of text wrapping (bool)
    @objc var wrapsLines: Bool {
        
        get {
            return self.viewController?.wrapsLines ?? false
        }
        
        set {
            self.viewController?.wrapsLines = newValue
        }
    }
    
    
    /// tab width (integer)
    @objc var tabWidth: Int {
        
        get {
            return self.viewController?.tabWidth ?? 0
        }
        
        set {
            self.viewController?.tabWidth = newValue
        }
    }
    
    
    /// whether replace tab with spaces
    @objc var expandsTab: Bool {
        
        get {
            return self.viewController?.isAutoTabExpandEnabled ?? false
        }
        
        set {
            self.viewController?.isAutoTabExpandEnabled = newValue
        }
    }
    
    
    
    // MARK: AppleScript Handler
    
    /// handle the Convert AppleScript by changing the text encoding and converting the text
    @objc func handleConvert(_ command: NSScriptCommand) -> Bool {
        
        guard
            let arguments = command.evaluatedArguments,
            let encodingName = arguments["newEncoding"] as? String,
            let encoding = EncodingManager.shared.encoding(name: encodingName)
            else { return false }
        
        if encoding == self.encoding {
            return true
        }
        
        let lossy = (arguments["lossy"] as? Bool) ?? false
        
        do {
            try self.changeEncoding(to: encoding, withUTF8BOM: false, lossy: lossy)
        } catch {
            return false
        }
        
        return true
    }
    
    
    /// handle the Convert AppleScript by changing the text encoding and reinterpreting the text
    @objc func handleReinterpret(_ command: NSScriptCommand) -> Bool {
        
        guard
            let arguments = command.evaluatedArguments,
            let encodingName = arguments["newEncoding"] as? String,
            let encoding = EncodingManager.shared.encoding(name: encodingName) else { return false }
        
        do {
            try self.reinterpret(encoding: encoding)
        } catch {
            return false
        }
        
        return true
    }
    
    
    /// handle the Find AppleScript command
    @objc func handleFind(_ command: NSScriptCommand) -> NSNumber {
        
        guard
            let arguments = command.evaluatedArguments,
            let searchString = arguments["targetString"] as? String, !searchString.isEmpty
            else { return false }
        
        let wholeString = self.string
        
        guard !wholeString.isEmpty else { return false }
        
        let options = NSString.CompareOptions(scriptingArguments: arguments)
        let isWrapSearch = (arguments["wrapSearch"] as? Bool) ?? false
        
        // perform find
        guard let foundRange = (wholeString as NSString).range(of: searchString, selectedRange: self.selectedRange,
                                                               options: options, isWrapSearch: isWrapSearch)
            else { return false }
        
        self.selectedRange = foundRange
        
        return true
    }
    
    
    /// handle the Replace AppleScript command
    @objc func handleReplace(_ command: NSScriptCommand) -> NSNumber {
        
        guard
            let arguments = command.evaluatedArguments,
            let searchString = arguments["targetString"] as? String, !searchString.isEmpty,
            let replacementString = arguments["newString"] as? String
            else { return 0 }
        
        let wholeString = self.string
        
        guard !wholeString.isEmpty else { return 0 }
        
        let options = NSString.CompareOptions(scriptingArguments: arguments)
        let isWrapSearch = (arguments["wrapSearch"] as? Bool) ?? false
        let isAll = (arguments["all"] as? Bool) ?? false
        
        // perform replacement
        if isAll {
            let newWholeString = NSMutableString(string: wholeString)
            let numberOfReplacements = newWholeString.replaceOccurrences(of: searchString, with: replacementString,
                                                                         options: options, range: wholeString.nsRange)
            
            guard numberOfReplacements > 0 else { return 0 }
            
            self.insert(string: newWholeString as String, at: .replaceAll)
            self.selectedRange = NSRange()
            
            return numberOfReplacements as NSNumber
            
        } else {
            guard let foundRange = (wholeString as NSString).range(of: searchString, selectedRange: self.selectedRange,
                                                                   options: options, isWrapSearch: isWrapSearch)
                else { return 0 }
            
            let replacedString: String
            if options.contains(.regularExpression) {
                let regexOptions: NSRegularExpression.Options = options.contains(.caseInsensitive) ? .caseInsensitive : []
                guard
                    let regex = try? NSRegularExpression(pattern: searchString, options: regexOptions),
                    let match = regex.firstMatch(in: wholeString, options: .withoutAnchoringBounds, range: foundRange)
                    else { return 0 }
                
                replacedString = regex.replacementString(for: match, in: wholeString, offset: 0, template: replacementString)
            } else {
                replacedString = replacementString
            }
            
            self.selectedRange = foundRange
            self.selection.contents = replacedString  // TextSelection's `setContents:` accepts also String for its argument
            
            return 1
        }
    }
    
    
    /// handle the Scroll AppleScript command by scrolling the text tiew to make selection visible
    @objc func handleScroll(_ command: NSScriptCommand) {
        
        self.textView?.centerSelectionInVisibleArea(nil)
    }
    
    
    /// return sting in the specified range
    func handleString(_ command: NSScriptCommand) -> String? {
        
        guard
            let arguments = command.evaluatedArguments,
            let rangeArray = arguments["range"] as? [Int], rangeArray.count == 2
            else { return nil }
        
        let location = rangeArray[0]
        let length = max(rangeArray[1], 1)
        
        guard let range = string.range(location: location, length: length) else { return nil }
        
        return (self.string as NSString).substring(with: range)
    }
    
}




// MARK: -

private extension NSString.CompareOptions {
    
    init(scriptingArguments arguments: [String: Any]) {
        
        let isRegex = (arguments["regularExpression"] as? Bool) ?? false
        let ignoresCase = (arguments["ignoreCase"] as? Bool) ?? false
        let isBackwards = (arguments["backwardsSearch"] as? Bool) ?? false
        
        self.init()
        
        if isRegex {
            self.update(with: .regularExpression)
        }
        if ignoresCase {
            self.update(with: .caseInsensitive)
        }
        if isBackwards {
            self.update(with: .backwards)
        }
    }
    
}


private extension NSString {
    
    /// find and return the range of the first occurrence starting from the given selectedRange
    func range(of searchString: String, selectedRange: NSRange, options: NSString.CompareOptions, isWrapSearch: Bool) -> NSRange? {
        
        let targetRange: NSRange = {
            if options.contains(.backwards), !options.contains(.regularExpression) {
                return NSRange(location: 0, length: selectedRange.location)
            }
            return NSRange(selectedRange.upperBound..<self.length)
        }()
        
        var foundRange = self.range(of: searchString, options: options, range: targetRange)
        if foundRange.location == NSNotFound, isWrapSearch {
            foundRange = self.range(of: searchString, options: options)
        }
        
        guard foundRange.location != NSNotFound else { return nil }
        
        return foundRange
    }
    
}
