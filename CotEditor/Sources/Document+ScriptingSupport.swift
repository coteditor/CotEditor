/*
 
 Document+ScriptingSupport.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-03-12.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

typealias OSALineEnding = FourCharCode
private extension OSALineEnding {
    static let LF = FourCharCode(code: "leLF")
    static let CR = FourCharCode(code: "leCR")
    static let CRLF = FourCharCode(code: "leCL")
}

extension Document {
    
    // MARK: AppleScript Accessors
    
    /// whole document string (text (NSTextStorage))
    var scriptTextStorage: Any {
        get {
            let textStorage = NSTextStorage(string: self.string)
            
            NotificationCenter.default.addObserver(self, selector: #selector(scriptTextStorageDidProcessEditing),
                                                   name: .NSTextStorageDidProcessEditing,
                                                   object: textStorage)
            
            // disconnect the delegate after 0.5 sec. (otherwise app may crash)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let strongSelf = self else { return }
                
                NotificationCenter.default.removeObserver(strongSelf, name: .NSTextStorageDidProcessEditing, object: textStorage)
            }
            
            return textStorage
        }
        
        set {
            if let textStorage = newValue as? NSTextStorage {
                self.replaceAllString(with: textStorage.string)
            } else if let string = newValue as? String {
                self.replaceAllString(with: string)
            }
        }
    }
    
    
    /// document string (text (NSTextStorage))
    var contents: Any {
        
        get {
            return self.scriptTextStorage
        }
        set {
            self.scriptTextStorage = newValue
        }
    }
    
    
    /// length of document (integer)
    var length: Int {
        
        return self.string.utf16.count
    }
    
    
    /// new line code (enum type)
    var lineEndingChar: FourCharCode {
        
        get {
            switch self.lineEnding {
            case .LF:
                return OSALineEnding.LF
            case .CR:
                return OSALineEnding.CR
            case .CRLF:
                return OSALineEnding.CRLF
            default:
                return OSALineEnding.LF
            }
        }
        set {
            let type: LineEnding = {
                switch newValue {
                case OSALineEnding.LF:
                    return .LF
                case OSALineEnding.CR:
                    return .CR
                case OSALineEnding.CRLF:
                    return .CRLF
                default:
                    return .LF
                }
            }()
            self.changeLineEnding(to: type)
        }
    }
    
    
    /// encoding name (Unicode text)
    var encodingName: String {
        
        return String.localizedName(of: self.encoding)
    }
    
    
    /// encoding in IANA CharSet name (Unicode text)
    var IANACharSetName: String {
        
        return self.encoding.ianaCharSetName ?? ""
    }
    
    
    /// syntax style name (Unicode text)
    var coloringStyle: String {
        
        get {
            return self.syntaxStyle.styleName
        }
        set {
            self.setSyntaxStyle(name: newValue)
        }
    }
    
    
    /// selection-object
    func selectionObject() -> TextSelection {
        return self.selection
    }
    func setSelectionObject(_ object: Any) {
        
        if let string = object as? String {
            self.selection.contents = string
        }
    }
    
    
    /// state of text wrapping (bool)
    var wrapsLines: Bool {
        
        get {
            return self.viewController?.wrapsLines ?? false
        }
        set {
            self.viewController?.wrapsLines = newValue
        }
    }
    
    
    /// tab width (integer)
    var tabWidth: Int {
        
        get {
            return self.viewController?.tabWidth ?? 0
        }
        set {
            self.viewController?.tabWidth = newValue
        }
    }
    
    
    /// whether replace tab with spaces
    var expandsTab: Bool {
        
        get {
            return self.viewController?.isAutoTabExpandEnabled ?? false
        }
        set {
            self.viewController?.isAutoTabExpandEnabled = newValue
        }
    }
    
    
    
    // MARK: AppleScript Handler
    
    /// change encoding and convert text
    func handleConvert(_ command: NSScriptCommand) -> NSNumber {
        
        let arguments = command.evaluatedArguments
        
        guard
            let encodingName = arguments?["newEncoding"] as? String,
            let encoding = EncodingManager.encoding(fromName: encodingName) else { return .no }
        
        if encoding == self.encoding {
            return .yes
        }
        
        let lossy = (arguments?["lossy"] as? Bool) ?? false
        
        return self.changeEncoding(to: encoding, withUTF8BOM: false, askLossy: false, lossy: lossy) ? .yes : .no
    }
    
    
    /// change encoding and reinterpret text
    func handleReinterpret(_ command: NSScriptCommand) -> NSNumber {
        
        let arguments = command.evaluatedArguments
        
        guard
            let encodingName = arguments?["newEncoding"] as? String,
            let encoding = EncodingManager.encoding(fromName: encodingName) else { return .no }
        
        do {
            try self.reinterpret(encoding: encoding)
        } catch {
            return .no
        }
        
        return .yes
    }
    
    
    /// find
    func handleFind(_ command: NSScriptCommand) -> NSNumber {
        
        guard
            let arguments = command.evaluatedArguments,
            let searchString = arguments["targetString"] as? String, !searchString.isEmpty else { return .no }
        
        let isRegex = (arguments["regularExpression"] as? Bool) ?? false
        let ignoresCase = (arguments["ignoreCase"] as? Bool) ?? false
        let isBackwards = (arguments["backwardsSearch"] as? Bool) ?? false
        let isWrapSearch = (arguments["wrapSearch"] as? Bool) ?? false
        
        let wholeString = self.string
        
        guard !wholeString.isEmpty else { return .no }
        
        // set target range
        let targetRange: NSRange = {
            let selectedRange = self.selectedRange
            if isBackwards {
                return NSRange(location: 0, length: selectedRange.location)
            }
            return NSRange(location: selectedRange.max, length: string.utf16.count - selectedRange.max)
        }()
        
        // perform find
        var success = self.find(searchString, regularExpression: isRegex, ignoreCase: ignoresCase, backwards: isBackwards, range: targetRange)
        if !success && isWrapSearch {
            success = self.find(searchString, regularExpression: isRegex, ignoreCase: ignoresCase, backwards: isBackwards, range: wholeString.nsRange)
        }
        
        return NSNumber(value: success)
    }
    
    
    /// replace
    func handleReplace(_ command: NSScriptCommand) -> NSNumber {
        
        guard
            let arguments = command.evaluatedArguments,
            let searchString = arguments["targetString"] as? String, !searchString.isEmpty else { return .no }
        
        let wholeString = self.string
        
        guard !wholeString.isEmpty else { return .no }
        
        let replacementString = (arguments["newString"] as? String) ?? ""
        let isRegex = (arguments["regularExpression"] as? Bool) ?? false
        let ignoresCase = (arguments["ignoreCase"] as? Bool) ?? false
        let isBackwards = (arguments["backwardsSearch"] as? Bool) ?? false
        let isWrapSearch = (arguments["wrapSearch"] as? Bool) ?? false
        let isAll = (arguments["all"] as? Bool) ?? false
        
        guard isRegex || searchString != replacementString else { return .no }
        
        // set target range
        let targetRange: NSRange = {
            if isAll {
                return wholeString.nsRange
            }
            let selectedRange = self.selectedRange
            if isBackwards {
                return NSRange(location: 0, length: selectedRange.location)
            }
            return NSRange(location: selectedRange.max, length: string.utf16.count - selectedRange.max)
        }()
        
        // perform replacement
        var numberOfReplacements = 0
        if isAll {
            let newWholeString = NSMutableString(string: wholeString)
            if isRegex {
                let options: NSRegularExpression.Options = ignoresCase ? .caseInsensitive : []
                guard let regex = try? NSRegularExpression(pattern: searchString, options: options) else { return .no }
                numberOfReplacements = regex.replaceMatches(in: newWholeString, range: targetRange, withTemplate: replacementString)
                
            } else {
                var options = NSString.CompareOptions()
                if ignoresCase {
                    options.update(with: .caseInsensitive)
                }
                if isBackwards {
                    options.update(with: .backwards)
                }
                numberOfReplacements = newWholeString.replaceOccurrences(of: searchString, with: replacementString,
                                                                         options: options, range: targetRange)
            }
            if numberOfReplacements > 0 {
                self.replaceAllString(with: newWholeString as String)
                self.selectedRange = NSRange()
            }
            
        } else {
            var success = self.find(searchString, regularExpression: isRegex, ignoreCase: ignoresCase, backwards: isBackwards, range: targetRange)
            if !success && isWrapSearch {
                success = self.find(searchString, regularExpression: isRegex, ignoreCase: ignoresCase, backwards: isBackwards, range: wholeString.nsRange)
            }
            if success {
                self.selection.contents = replacementString  // TextSelection's `setContents:` accepts also String for its argument
                numberOfReplacements = 1
            }
        }
        
        return NSNumber(value: numberOfReplacements)
    }
    
    
    /// scroll to make selection visible
    func handleScroll(_ command: NSScriptCommand) {
        
        self.textView?.centerSelectionInVisibleArea(nil)
    }
    
    
    /// return sting in the specified range
    func handleString(_ command: NSScriptCommand) -> String? {
        
        let arguments = command.evaluatedArguments
        
        guard let rangeArray = arguments?["range"] as? [Int] else { return "" }
        
        let location = rangeArray[0]
        let length = max(rangeArray[1], 1)
        
        let range = self.string.range(location: location, length: length)
        
        return (self.string as NSString?)?.substring(with: range)
    }
    
    
    
    // MARK: Notifications
    
    /// text strage as AppleScript's return value did update
    func scriptTextStorageDidProcessEditing(_ notification: Notification) {
        
        guard let textStorage = notification.object as? NSTextStorage else { return }
        
        self.replaceAllString(with: textStorage.string)
        
        NotificationCenter.default.removeObserver(self, name: .NSTextStorageDidProcessEditing, object: textStorage)
    }
    
    
    
    // MARK: Private Methods
    
    /// find string, select if found and return whether succeed
    private func find(_ searchString: String, regularExpression: Bool, ignoreCase: Bool, backwards: Bool, range: NSRange) -> Bool {
        
        var options = NSString.CompareOptions()
        if regularExpression {
            options.update(with: .regularExpression)
        }
        if ignoreCase {
            options.update(with: .caseInsensitive)
        }
        if backwards {
            options.update(with: .backwards)
        }
        
        let foundRange = (self.string as NSString).range(of: searchString, options: options, range: range)
        
        guard foundRange.location != NSNotFound else { return false }
        
        self.selectedRange = foundRange
        
        return true
    }
    
}



private extension NSNumber {

    @nonobjc static let no = NSNumber(value: false)
    @nonobjc static let yes = NSNumber(value: true)
}
