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
import FileEncoding
import FuzzyRange
import LineEnding

private enum OSALineEnding: FourCharCode {
    
    case lf = "leLF"
    case cr = "leCR"
    case crlf = "leCL"
    case nel = "leNL"
    case lineSeparator = "leLS"
    case paragraphSeparator = "lePS"
    
    
    var lineEnding: LineEnding {
        
        switch self {
            case .lf: .lf
            case .cr: .cr
            case .crlf: .crlf
            case .nel: .nel
            case .lineSeparator: .lineSeparator
            case .paragraphSeparator: .paragraphSeparator
        }
    }
    
    
    init?(lineEnding: LineEnding) {
        
        self = switch lineEnding {
            case .lf: .lf
            case .cr: .cr
            case .crlf: .crlf
            case .nel: .nel
            case .lineSeparator: .lineSeparator
            case .paragraphSeparator: .paragraphSeparator
        }
    }
}


extension Document {
    
    // MARK: AppleScript Accessors
    
    /// Whole document string (text (NSTextStorage).)
    @objc var scriptTextStorage: Any {
        
        get {
            let textStorage = NSTextStorage(string: self.textStorage.string)
            if self.isEditable {
                textStorage.observeDirectEditing { [weak self] editedString in
                    self?.textView?.insert(string: editedString, at: .replaceAll)
                }
            }
            
            return textStorage
        }
        
        set {
            guard
                self.isEditable,
                let string = String(anyString: newValue)
            else { return }
            
            self.textView?.insert(string: string, at: .replaceAll)
        }
    }
    
    
    /// The document string (text (NSTextStorage)).
    @objc var contents: Any {
        
        get {
            self.scriptTextStorage
        }
        
        set {
            self.scriptTextStorage = newValue
        }
    }
    
    
    /// Selection-object (TextSelection).
    @objc var selectionObject: TextSelection {
        
        self.selection
    }
    
    
    /// Length of the document in UTF-16 (integer).
    ///
    /// - Note: deprecated in CotEditor 4.4.0 (2022-10).
    @objc var length: Int {
        
        self.textStorage.string.utf16.count
    }
    
    
    /// New line code (enum type).
    @objc var lineEndingChar: FourCharCode {
        
        get {
            (OSALineEnding(lineEnding: self.lineEnding) ?? .lf).rawValue
        }
        
        set {
            guard self.isEditable else { return }
            
            let lineEnding = OSALineEnding(rawValue: newValue)?.lineEnding
            
            self.changeLineEnding(to: lineEnding ?? .lf)
        }
    }
    
    
    /// Encoding name (Unicode text).
    @objc var encodingName: String {
        
        String.localizedName(of: self.fileEncoding.encoding)
    }
    
    
    /// Encoding in IANA CharSet name (Unicode text).
    @objc var IANACharSetName: String {
        
        self.fileEncoding.encoding.ianaCharSetName ?? ""
    }
    
    
    /// Whether the document has an encoding BOM.
    @objc var hasBOM: Bool {
        
        self.fileEncoding.withUTF8BOM ||
        self.fileEncoding.encoding == .utf16 ||
        self.fileEncoding.encoding == .utf32
    }
    
    
    /// Syntax name (Unicode text).
    @objc var coloringStyle: String {
        
        get {
            self.syntaxParser.name
        }
        
        set {
            self.setSyntax(name: newValue)
        }
    }
    
    
    /// State of text wrapping (bool).
    @objc var wrapsLines: Bool {
        
        get {
            self.viewController?.wrapsLines ?? false
        }
        
        set {
            self.setViewControllerValue(.wrapsLines(newValue))
        }
    }
    
    
    /// Tab width (integer).
    @objc var tabWidth: Int {
        
        get {
            self.viewController?.tabWidth ?? 0
        }
        
        set {
            self.setViewControllerValue(.tabWidth(newValue))
        }
    }
    
    
    /// Whether replace tab with spaces.
    @objc var expandsTab: Bool {
        
        get {
            self.viewController?.isAutoTabExpandEnabled ?? false
        }
        
        set {
            self.setViewControllerValue(.expandsTab(newValue))
        }
    }
    
    
    // MARK: AppleScript Handlers
    
    override func handlePrint(_ command: NSScriptCommand) -> Any? {
        
        let arguments = command.evaluatedArguments ?? [:]
        let showPrintPanel = arguments["ShowPrintDialog"] as? Bool ?? false
        let settings = arguments["PrintSettings"] as? [NSPrintInfo.AttributeKey: Any] ?? [:]
        
        self.print(withSettings: settings, showPrintPanel: showPrintPanel, delegate: nil, didPrint: nil, contextInfo: nil)
        
        return true
    }
    
    
    /// Handles the Convert AppleScript by changing the text encoding and converting the text.
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
        
        guard fileEncoding != self.fileEncoding else { return true }
        
        guard self.isEditable else {
            command.scriptErrorNumber = editingNotAllowed
            command.scriptErrorString = "The document is not editable."
            return false
        }
        
        let lossy = (arguments["lossy"] as? Bool) ?? false
        if !lossy, !self.canBeConverted(to: fileEncoding) {
            command.scriptErrorNumber = errOSAGeneralError
            command.scriptErrorString = LossyEncodingError(encoding: fileEncoding).localizedDescription
            return false
        }
        
        self.changeEncoding(to: fileEncoding)
        
        return true
    }
    
    
    /// Handles the Convert AppleScript by changing the text encoding and reinterpreting the text.
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
    
    
    /// Handles the Find AppleScript command.
    @objc func handleFind(_ command: NSScriptCommand) -> NSNumber {
        
        guard
            let arguments = command.evaluatedArguments,
            let searchString = arguments["targetString"] as? String, !searchString.isEmpty,
            let textView = self.textView
        else { return false }
        
        let options = NSString.CompareOptions(scriptingArguments: arguments)
        let isWrapSearch = (arguments["wrapSearch"] as? Bool) ?? false
        
        // perform find
        let string = self.textStorage.string as NSString
        guard let foundRange = string.range(of: searchString, selectedRange: textView.selectedRange,
                                            options: options, isWrapSearch: isWrapSearch)
        else { return false }
        
        textView.selectedRange = foundRange
        
        return true
    }
    
    
    /// Handles the Replace AppleScript command.
    @objc func handleReplace(_ command: NSScriptCommand) -> NSNumber {
        
        guard
            let arguments = command.evaluatedArguments,
            let searchString = arguments["targetString"] as? String, !searchString.isEmpty,
            let replacementString = arguments["newString"] as? String,
            let textView = self.textView
        else { return 0 }
        
        guard self.isEditable else {
            command.scriptErrorNumber = editingNotAllowed
            command.scriptErrorString = "The document is not editable."
            return 0
        }
        
        let options = NSString.CompareOptions(scriptingArguments: arguments)
        let isWrapSearch = (arguments["wrapSearch"] as? Bool) ?? false
        let isAll = (arguments["all"] as? Bool) ?? false
        
        let string = self.textStorage.string
        
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
            
            textView.insert(string: mutableString as String, at: .replaceAll)
            textView.selectedRange = NSRange()
            
            return count as NSNumber
            
        } else {
            guard let foundRange = (string as NSString).range(of: searchString, selectedRange: textView.selectedRange,
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
            
            textView.selectedRange = foundRange
            textView.insert(string: replacedString, at: .replaceSelection)
            
            return 1
        }
    }
    
    
    /// Handles the Scroll AppleScript command by scrolling the text view to make selection visible.
    @objc func handleScroll(_ command: NSScriptCommand) {
        
        self.textView?.centerSelectionInVisibleArea(nil)
    }
    
    
    /// Handles the Jump AppleScript command by moving the cursor to the specified line and scrolling the text view to make it visible.
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
    
    
    /// Returns string in the specified range.
    @objc func handleString(_ command: NSScriptCommand) -> String? {
        
        guard
            let arguments = command.evaluatedArguments,
            let rangeArray = arguments["range"] as? [Int], rangeArray.count == 2
        else {
            command.scriptErrorNumber = OSAParameterMismatch
            command.scriptErrorString = "The range parameter must be a list of {location, length}."
            return nil
        }
        
        let fuzzyRange = FuzzyRange(location: rangeArray[0], length: max(rangeArray[1], 1))
        
        guard let range = self.textStorage.string.range(in: fuzzyRange) else {
            command.scriptErrorNumber = OSAParameterMismatch
            command.scriptErrorString = "Out of the range."
            return nil
        }
        
        return (self.textStorage.string as NSString).substring(with: range)
    }
    
    
    // MARK: Private Methods
    
    /// Sets the value to DocumentViewController but lazily by waiting the DocumentViewController is attached if it is not available yet.
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
    ///   - property: The value and property type to set.
    private func setViewControllerValue(_ property: DocumentViewController.ScriptingProperty) {
        
        if let viewController = self.viewController {
            viewController.apply(scriptingProperty: property)
            return
        }
        
        Task.detached { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: EditorTextView.didBecomeFirstResponderNotification).map(\.name) {
                guard let viewController = await self?.viewController else { return }
                
                await MainActor.run {
                    viewController.apply(scriptingProperty: property)
                }
                break
            }
        }
    }
}


private extension DocumentViewController {
    
    enum ScriptingProperty {
        
        case wrapsLines(Bool)
        case tabWidth(Int)
        case expandsTab(Bool)
    }
    
    
    /// Applies the scripting property to the user interface.
    ///
    /// - Parameter property: The scripting property.
    func apply(scriptingProperty property: ScriptingProperty) {
        
        switch property {
            case .wrapsLines(let value):
                self.wrapsLines = value
            case .tabWidth(let value):
                self.tabWidth = value
            case .expandsTab(let value):
                self.isAutoTabExpandEnabled = value
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
    
    /// Finds the range of the first occurrence starting from the given selectedRange.
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
            if foundRange.isNotFound, isWrapSearch {
                foundRange = regex.rangeOfFirstMatch(in: self as String, options: .withoutAnchoringBounds, range: self.range)
            }
            
        } else {
            foundRange = self.range(of: searchString, options: options, range: targetRange)
            if foundRange.isNotFound, isWrapSearch {
                foundRange = self.range(of: searchString, options: options)
            }
        }
        
        guard foundRange.location != NSNotFound else { return nil }
        
        return foundRange
    }
}
