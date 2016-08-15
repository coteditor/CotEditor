/*
 
 DocumentAnalyzer.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-12-18.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

extension Notification.Name {
    
    static let AnalyzerDidUpdateFileInfo = Notification.Name("AnalyzerDidUpdateFileInfo")
    static let AnalyzerDidUpdateModeInfo = Notification.Name("AnalyzerDidUpdateModeInfo")
    static let AnalyzerDidUpdateEditorInfo = Notification.Name("AnalyzerDidUpdateEditorInfo")
}



// MARK:

final class DocumentAnalyzer: NSObject {
    
    // MARK: Public Properties
    
    var needsUpdateEditorInfo = false  // need to update all editor info
    var needsUpdateStatusEditorInfo = false // need only to update editor info in satus bar
    
    // file info
    private(set) dynamic var creationDate: Date?
    private(set) dynamic var modificationDate: Date?
    private(set) dynamic var fileSize: NSNumber?
    private(set) dynamic var filePath: String?
    private(set) dynamic var owner: String?
    private(set) dynamic var permission: NSNumber?
    private(set) dynamic var isReadOnly = false
    
    // mode info
    private(set) dynamic var encoding: String?
    private(set) dynamic var charsetName: String?
    private(set) dynamic var lineEndings: String?
    
    // editor info
    private(set) dynamic var lines: String?
    private(set) dynamic var chars: String?
    private(set) dynamic var words: String?
    private(set) dynamic var length: String?
    private(set) dynamic var location: String?  // caret location from the beginning of document
    private(set) dynamic var line: String?      // current line
    private(set) dynamic var column: String?    // caret location from the beginning of line
    private(set) dynamic var unicode: String?   // Unicode of selected single character (or surrogate-pair)
    
    
    // MARK: Private Properties
    
    private weak var document: Document?  // weak to avoid cycle retain
    private weak var editorInfoUpdateTimer: Timer?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
        
        super.init()
    }
    
    
    deinit {
        self.editorInfoUpdateTimer?.invalidate()
    }
    
    
    
    // MARK: Public Methods
    
    /// update file info
    func invalidateFileInfo() {
        
        guard let document = self.document else { return }
        
        let attrs = document.fileAttributes
        
        self.creationDate = attrs?[.creationDate] as? Date
        self.modificationDate = attrs?[.modificationDate] as? Date
        self.fileSize = attrs?[.size] as? NSNumber
        self.filePath = document.fileURL?.path
        self.owner = attrs?[.ownerAccountName] as? String
        self.permission = attrs?[.posixPermissions] as? NSNumber
        self.isReadOnly = {
            guard !document.isInViewingMode else { return false }
            
            return (attrs?[.immutable] as? NSNumber)?.boolValue ?? false
        }()
        
        NotificationCenter.default.post(name: .AnalyzerDidUpdateFileInfo, object: self)
    }
    
    
    /// update current encoding and line endings
    func invalidateModeInfo() {
        
        guard let document = self.document else { return }
        
        self.encoding = String.localizedName(of: document.encoding, withUTF8BOM: document.hasUTF8BOM)
        self.charsetName = String.IANACharSetName(of: document.encoding)
        self.lineEndings = document.lineEnding.name
        
        NotificationCenter.default.post(name: .AnalyzerDidUpdateModeInfo, object: self)
    }
    
    
    /// update editor info (only if really needed)
    func invalidateEditorInfo() {
        
        guard self.needsUpdateEditorInfo || self.needsUpdateStatusEditorInfo else { return }
        
        self.setupEditorInfoUpdateTimer()
        
    }
    
    
    
    // MARK: Private Methods
    
    /// update editor info (only if really needed)
    func updateEditorInfo() {
        
        guard
            let document = self.document,
            let textView = document.editor?.focusedTextView else { return }
        
        let needsAll = self.needsUpdateEditorInfo
        
        let string = NSString(string: document.textStorage.string) as String
        let lineEnding = document.lineEnding
        let selectedRange: NSRange = {
            var range = textView.selectedRange
            // exclude editing range from selected range (2007-05-20)
            if textView.hasMarkedText() {
                range.length = 0
            }
            return range
        }()
        
        // calculate on background thread
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            
            let countsLineEnding = Defaults[.countLineEndingAsChar]
            var location = 0
            var line = 0
            var column = 0
            var length = 0, selectedLength = 0
            var numberOfChars = 0, numberOfSelectedChars = 0
            var numberOfLines = 0, numberOfSelectedLines = 0
            var numberOfWords = 0, numberOfSelectedWords = 0
            var unicode: String?

            if !string.isEmpty {
                let selectedString = (string as NSString).substring(with: selectedRange)
                let hasSelection = !selectedString.isEmpty
                
                // count length
                if needsAll || Defaults[.showStatusBarLength] {
                    let isSingleLineEnding = (String(lineEnding.rawValue).unicodeScalars.count == 1)
                    var tmp = isSingleLineEnding ? string : string.replacingLineEndings(with: lineEnding)
                    length = tmp.utf16.count
                    
                    if hasSelection {
                        tmp = isSingleLineEnding ? selectedString : selectedString.replacingLineEndings(with: lineEnding)
                        selectedLength = tmp.utf16.count
                    }
                }
                
                // count characters
                if needsAll || Defaults[.showStatusBarChars] {
                    var tmp = countsLineEnding ? string : string.removingLineEndings
                    numberOfChars = tmp.numberOfComposedCharacters
                    
                    if hasSelection {
                        tmp = countsLineEnding ? selectedString : selectedString.removingLineEndings
                        numberOfSelectedChars = tmp.numberOfComposedCharacters
                    }
                }
                
                // count lines
                if needsAll || Defaults[.showStatusBarLines] {
                    numberOfLines = string.numberOfLines
                    if hasSelection {
                        numberOfSelectedLines = selectedString.numberOfLines
                    }
                }
                
                // count words
                if needsAll || Defaults[.showStatusBarWords] {
                    numberOfWords = string.numberOfWords
                    if hasSelection {
                        numberOfSelectedWords = selectedString.numberOfWords
                    }
                }
                
                // calculate current location
                if needsAll || Defaults[.showStatusBarLocation] {
                    let locString = (string as NSString).substring(to: selectedRange.location)
                    let tmp = countsLineEnding ? locString : locString.removingLineEndings
                    location = tmp.numberOfComposedCharacters
                }
                
                // calculate current line
                if needsAll || Defaults[.showStatusBarLine] {
                    line = string.lineNumber(at: selectedRange.location)
                    
                }
                
                // calculate current column
                if needsAll || Defaults[.showStatusBarColumn] {
                    let lineRange = (string as NSString).lineRange(for: selectedRange)
                    column = selectedRange.location - lineRange.location  // as length
                    column = (string as NSString).substring(with: NSRange(location: lineRange.location, length: column)).numberOfComposedCharacters
                }
                
                // unicode
                if needsAll && hasSelection {
                    if selectedString.unicodeScalars.count == 1,
                        let first = selectedString.unicodeScalars.first
                    {
                        unicode = first.codePoint
                    }
                }
            }
            
            // apply to UI
            DispatchQueue.main.sync {
                self.length = self.dynamicType.format(count: length, selectedCount: selectedLength)
                self.chars = self.dynamicType.format(count: numberOfChars, selectedCount: numberOfSelectedChars)
                self.lines = self.dynamicType.format(count: numberOfLines, selectedCount: numberOfSelectedLines)
                self.words = self.dynamicType.format(count: numberOfWords, selectedCount: numberOfSelectedWords)
                self.location = String.localizedStringWithFormat("%li", location)
                self.line = String.localizedStringWithFormat("%li", line)
                self.column = String.localizedStringWithFormat("%li", column)
                self.unicode = unicode
                
                NotificationCenter.default.post(name: .AnalyzerDidUpdateEditorInfo, object: self)
            }
        }
    }
    
    
    /// format count number with selection
    private static func format(count: Int, selectedCount: Int?) -> String {
        
        if let selectedCount = selectedCount, selectedCount > 0 {
            return String.localizedStringWithFormat("%li (%li)", count, selectedCount)
        }
        return String.localizedStringWithFormat("%li", count)
    }
    
    
    /// set update timer for information about the content text
    private func setupEditorInfoUpdateTimer() {
        
        let interval: TimeInterval = Defaults[.infoUpdateInterval]
        
        if let timer = self.editorInfoUpdateTimer, timer.isValid {
            timer.fireDate = Date(timeIntervalSinceNow: interval)
        } else {
            self.editorInfoUpdateTimer = Timer.scheduledTimer(timeInterval: interval,
                                                              target: self,
                                                              selector: #selector(updateEditorInfo(timer:)),
                                                              userInfo: nil,
                                                              repeats: false)
        }
    }
    
    
    /// editor info update timer is fired
    func updateEditorInfo(timer: Timer) {
        
        self.editorInfoUpdateTimer?.invalidate()
        self.updateEditorInfo()
    }
    
}
