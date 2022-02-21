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
//  © 2014-2022 1024jp
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

private enum OSALineEnding: FourCharCode {
    
    case lf = "leLF"
    case cr = "leCR"
    case crlf = "leCL"
    case nel = "leNL"
    case ls = "leLS"
    case ps = "lePS"
    
    
    var lineEnding: LineEnding {
        
        switch self {
            case .lf:
                return .lf
            case .cr:
                return .cr
            case .crlf:
                return .crlf
            case .nel:
                return .nel
            case .ls:
                return .lineSeparator
            case .ps:
                return .paragraphSeparator
        }
    }
    
    
    init?(lineEnding: LineEnding) {
        
        switch lineEnding {
            case .lf:
                self = .lf
            case .cr:
                self = .cr
            case .crlf:
                self = .crlf
            case .nel:
                self = .nel
            case .lineSeparator:
                self = .ls
            case .paragraphSeparator:
                self = .ps
        }
    }
    
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
            return (OSALineEnding(lineEnding: self.lineEnding) ?? .lf).rawValue
        }
        
        set {
            let lineEnding = OSALineEnding(rawValue: newValue)?.lineEnding
            
            self.changeLineEnding(to: lineEnding ?? .lf)
        }
    }
    
    
    /// encoding name (Unicode text)
    @objc var encodingName: String {
        
        return String.localizedName(of: self.fileEncoding.encoding)
    }
    
    
    /// encoding in IANA CharSet name (Unicode text)
    @objc var IANACharSetName: String {
        
        return self.fileEncoding.encoding.ianaCharSetName ?? ""
    }
    
    
    @objc var hasBOM: Bool {
        
        self.fileEncoding.withUTF8BOM ||
        self.fileEncoding.encoding == .utf16 ||
        self.fileEncoding.encoding == .utf32
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
            self.setViewControllerValue(newValue, for: \.wrapsLines)
        }
    }
    
    
    /// tab width (integer)
    @objc var tabWidth: Int {
        
        get {
            return self.viewController?.tabWidth ?? 0
        }
        
        set {
            self.setViewControllerValue(newValue, for: \.tabWidth)
        }
    }
    
    
    /// whether replace tab with spaces
    @objc var expandsTab: Bool {
        
        get {
            return self.viewController?.isAutoTabExpandEnabled ?? false
        }
        
        set {
            self.setViewControllerValue(newValue, for: \.isAutoTabExpandEnabled)
        }
    }
    
    
    
    // MARK: AppleScript Handler
    
    /// handle the Convert AppleScript by changing the text encoding and converting the text
    @objc func handleConvert(_ command: NSScriptCommand) -> NSNumber {
        
        guard
            let arguments = command.evaluatedArguments,
            let encodingName = arguments["newEncoding"] as? String,
            let encoding = EncodingManager.shared.encoding(name: encodingName) ?? EncodingManager.shared.encoding(ianaCharSetName: encodingName)
        else {
            command.scriptErrorNumber = OSAParameterMismatch
            command.scriptErrorString = "Invalid encoding name."
            return false
        }
        
        let withBOM = arguments["BOM"] as? Bool ?? false
        let fileEncoding = FileEncoding(encoding: encoding, withUTF8BOM: withBOM)
        
        if fileEncoding == self.fileEncoding {
            return true
        }
        
        let lossy = (arguments["lossy"] as? Bool) ?? false
        
        do {
            try self.changeEncoding(to: fileEncoding, lossy: lossy)
        } catch {
            command.scriptErrorNumber = errOSAGeneralError
            command.scriptErrorString = error.localizedDescription
            return false
        }
        
        return true
    }
    
    
    /// handle the Convert AppleScript by changing the text encoding and reinterpreting the text
    @objc func handleReinterpret(_ command: NSScriptCommand) -> NSNumber {
        
        guard
            let arguments = command.evaluatedArguments,
            let encodingName = arguments["newEncoding"] as? String,
            let encoding = EncodingManager.shared.encoding(name: encodingName) ?? EncodingManager.shared.encoding(ianaCharSetName: encodingName)
        else {
            command.scriptErrorNumber = OSAParameterMismatch
            command.scriptErrorString = "Invalid encoding name."
            return false
        }
        
        do {
            try self.reinterpret(encoding: encoding)
        } catch {
            command.scriptErrorNumber = errOSAGeneralError
            command.scriptErrorString = error.localizedDescription
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
        
        let options = NSString.CompareOptions(scriptingArguments: arguments)
        let isWrapSearch = (arguments["wrapSearch"] as? Bool) ?? false
        
        // perform find
        let string = self.string as NSString
        guard let foundRange = string.range(of: searchString, selectedRange: self.selectedRange,
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
        
        let options = NSString.CompareOptions(scriptingArguments: arguments)
        let isWrapSearch = (arguments["wrapSearch"] as? Bool) ?? false
        let isAll = (arguments["all"] as? Bool) ?? false
        
        let string = self.string
        
        guard !string.isEmpty else { return 0 }
        
        // perform replacement
        if isAll {
            let mutableString = NSMutableString(string: string)
            let count: Int
            if options.contains(.regularExpression) {
                let regexOptions: NSRegularExpression.Options = options.contains(.caseInsensitive) ? [.caseInsensitive] : []
                guard let regex = try? NSRegularExpression(pattern: searchString, options: regexOptions.union(.anchorsMatchLines)) else {
                    command.scriptErrorNumber = errOSAGeneralError
                    command.scriptErrorString = "Invalid regular expression."
                    return 0
                }
                
                count = regex.replaceMatches(in: mutableString, range: string.nsRange, withTemplate: replacementString)
            } else {
                count = mutableString.replaceOccurrences(of: searchString, with: replacementString, options: options, range: string.nsRange)
            }
            
            guard count > 0 else { return 0 }
            
            self.insert(string: mutableString as String, at: .replaceAll)
            self.selectedRange = NSRange()
            
            return count as NSNumber
            
        } else {
            guard let foundRange = (string as NSString).range(of: searchString, selectedRange: self.selectedRange,
                                                              options: options, isWrapSearch: isWrapSearch)
                else { return 0 }
            
            let replacedString: String
            if options.contains(.regularExpression) {
                let regexOptions: NSRegularExpression.Options = options.contains(.caseInsensitive) ? .caseInsensitive : []
                guard let regex = try? NSRegularExpression(pattern: searchString, options: regexOptions.union(.anchorsMatchLines)) else {
                    command.scriptErrorNumber = errOSAGeneralError
                    command.scriptErrorString = "Invalid regular expression."
                    return 0
                }
                
                guard let match = regex.firstMatch(in: string, options: .withoutAnchoringBounds, range: foundRange) else { return 0 }
                
                replacedString = regex.replacementString(for: match, in: string, offset: 0, template: replacementString)
            } else {
                replacedString = replacementString
            }
            
            self.selectedRange = foundRange
            self.selection.contents = replacedString  // TextSelection's `setContents:` accepts also String for its argument.
            
            return 1
        }
    }
    
    
    /// handle the Scroll AppleScript command by scrolling the text tiew to make selection visible
    @objc func handleScroll(_ command: NSScriptCommand) {
        
        self.textView?.centerSelectionInVisibleArea(nil)
    }
    
    
    /// handle the Jump AppleScript command by moving the cursor to the specified line and scrolling the text view to make it visible
    @objc func handleJump(_ command: NSScriptCommand) {
        
        guard
            let arguments = command.evaluatedArguments,
            let line = arguments["line"] as? Int
        else {
            command.scriptErrorNumber = OSAMissingParameter
            return
        }
        
        let column = arguments["column"] as? Int ?? 0
        
        guard let textView = self.textView else { return assertionFailure() }
        
        let location: Int
        do {
            location = try textView.string.fuzzyLocation(line: line, column: column)
        } catch {
            command.scriptErrorNumber = OSAParameterMismatch
            command.scriptErrorString = "Invalid parameter. " + error.localizedDescription
            return
        }
        
        textView.selectedRange = NSRange(location: location, length: 0)
        textView.centerSelectionInVisibleArea(nil)
    }
    
    
    /// return sting in the specified range
    @objc func handleString(_ command: NSScriptCommand) -> String? {
        
        guard
            let arguments = command.evaluatedArguments,
            let rangeArray = arguments["range"] as? [Int], rangeArray.count == 2
        else {
            command.scriptErrorNumber = OSAParameterMismatch
            command.scriptErrorString = "The range paramator must be a list of {location, length}."
            return nil
        }
        
        let fuzzyRange = FuzzyRange(location: rangeArray[0], length: max(rangeArray[1], 1))
        
        guard let range = string.range(in: fuzzyRange) else {
            command.scriptErrorNumber = OSAParameterMismatch
            command.scriptErrorString = "Out of the range."
            return nil
        }
        
        return (self.string as NSString).substring(with: range)
    }
    
    
    
    // MARK: Private Methods
    
    /// Set the value to DocumentViewController but lazily by waiting the DocumentViewController is attached if it is not available yet.
    ///
    /// When document's properties are set in the document creation phase like in the following code,
    /// those setters are invoked while `self.viewController` is still `nil`.
    /// Therefore, to avoid ignoring initialization, this method asynchronously waits for the DocumentViewController is available, and then sets the value.
    ///
    ///     tell application "CotEditor"
    ///         make new document with properties { name: "Untitled.txt", tab width: 16 }
    ///     end tell
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - keyPath: The keyPath of the DocumentViewController to set the value.
    private func setViewControllerValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<DocumentViewController, Value>) {
        
        if let viewController = self.viewController {
            viewController[keyPath: keyPath] = value
            return
        }
        
        weak var observer: NSObjectProtocol?
        observer = NotificationCenter.default.addObserver(forName: EditorTextView.didBecomeFirstResponderNotification, object: nil, queue: .main) { [weak self] _ in
            guard let viewController = self?.viewController else { return }
            
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
            
            viewController[keyPath: keyPath] = value
        }
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
            self.formUnion(.regularExpression)
        }
        if ignoresCase {
            self.formUnion(.caseInsensitive)
        }
        if isBackwards {
            self.formUnion(.backwards)
        }
    }
    
}


private extension NSString {
    
    /// Find the range of the first occurrence starting from the given selectedRange.
    ///
    /// - Parameters:
    ///   - searchString: The string to search for.
    ///   - selectedRange: The range to search in.
    ///   - options: The search option.
    ///   - isWrapSearch: Whether the search should wrap.
    /// - Returns: The range of found or `nil` if not found.
    func range(of searchString: String, selectedRange: NSRange, options: NSString.CompareOptions, isWrapSearch: Bool) -> NSRange? {
        
        guard self.length > 0 else { return nil }
        
        let targetRange = (options.contains(.backwards) && !options.contains(.regularExpression))
            ? NSRange(..<selectedRange.lowerBound)
            : NSRange(selectedRange.upperBound..<self.length)
        
        var foundRange: NSRange = .notFound
        if options.contains(.regularExpression) {
            let regexOptions: NSRegularExpression.Options = options.contains(.caseInsensitive) ? .caseInsensitive : []
            guard let regex = try? NSRegularExpression(pattern: searchString, options: regexOptions.union(.anchorsMatchLines)) else { return nil }
            
            foundRange = regex.rangeOfFirstMatch(in: self as String, options: .withoutAnchoringBounds, range: targetRange)
            if foundRange == .notFound, isWrapSearch {
                foundRange = regex.rangeOfFirstMatch(in: self as String, options: .withoutAnchoringBounds, range: self.range)
            }
            
        } else {
            foundRange = self.range(of: searchString, options: options, range: targetRange)
            if foundRange == .notFound, isWrapSearch {
                foundRange = self.range(of: searchString, options: options)
            }
        }
        
        guard foundRange.location != NSNotFound else { return nil }
        
        return foundRange
    }
    
}
