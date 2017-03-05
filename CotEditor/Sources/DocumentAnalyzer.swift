/*
 
 DocumentAnalyzer.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-12-18.
 
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

extension Notification.Name {
    
    static let AnalyzerDidUpdateFileInfo = Notification.Name("AnalyzerDidUpdateFileInfo")
    static let AnalyzerDidUpdateModeInfo = Notification.Name("AnalyzerDidUpdateModeInfo")
    static let AnalyzerDidUpdateEditorInfo = Notification.Name("AnalyzerDidUpdateEditorInfo")
}



// MARK: -

final class DocumentAnalyzer: NSObject {
    
    // MARK: Public Properties
    
    var needsUpdateEditorInfo = false  // need to update all editor info
    var needsUpdateStatusEditorInfo = false  // need only to update editor info in satus bar
    
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
    
    private lazy var editorUpdateTask: Debouncer = Debouncer(delay: 0.2) { [weak self] in self?.updateEditorInfo() }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
        
        super.init()
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
            
            return attrs?[.immutable] as? Bool ?? false
        }()
        
        NotificationCenter.default.post(name: .AnalyzerDidUpdateFileInfo, object: self)
    }
    
    
    /// update current encoding and line endings
    func invalidateModeInfo() {
        
        guard let document = self.document else { return }
        
        self.encoding = String.localizedName(of: document.encoding, withUTF8BOM: document.hasUTF8BOM)
        self.charsetName = document.encoding.ianaCharSetName
        self.lineEndings = document.lineEnding.name
        
        NotificationCenter.default.post(name: .AnalyzerDidUpdateModeInfo, object: self)
    }
    
    
    /// update editor info (only if really needed)
    func invalidateEditorInfo() {
        
        guard self.needsUpdateEditorInfo || self.needsUpdateStatusEditorInfo else { return }
        
        self.editorUpdateTask.schedule()
    }
    
    
    
    // MARK: Private Methods
    
    /// update editor info (only if really needed)
    private func updateEditorInfo() {
        
        guard
            let document = self.document,
            let textView = document.viewController?.focusedTextView,
            !textView.hasMarkedText() else { return }
        
        let needsAll = self.needsUpdateEditorInfo
        let defaults = UserDefaults.standard
        
        let string = NSString(string: document.textStorage.string) as String
        let lineEnding = document.lineEnding
        let selectedRange = textView.selectedRange
        
        // calculate on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let countsLineEnding = defaults[.countLineEndingAsChar]
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
                if needsAll || defaults[.showStatusBarLength] {
                    let isSingleLineEnding = (String(lineEnding.rawValue).unicodeScalars.count == 1)
                    let stringForCounting = isSingleLineEnding ? string : string.replacingLineEndings(with: lineEnding)
                    length = stringForCounting.utf16.count
                    
                    if hasSelection {
                        let stringForCounting = isSingleLineEnding ? selectedString : selectedString.replacingLineEndings(with: lineEnding)
                        selectedLength = stringForCounting.utf16.count
                    }
                }
                
                // count characters
                if needsAll || defaults[.showStatusBarChars] {
                    let stringForCounting = countsLineEnding ? string : string.removingLineEndings
                    numberOfChars = stringForCounting.numberOfComposedCharacters
                    
                    if hasSelection {
                        let stringForCounting = countsLineEnding ? selectedString : selectedString.removingLineEndings
                        numberOfSelectedChars = stringForCounting.numberOfComposedCharacters
                    }
                }
                
                // count lines
                if needsAll || defaults[.showStatusBarLines] {
                    numberOfLines = string.numberOfLines
                    if hasSelection {
                        numberOfSelectedLines = selectedString.numberOfLines
                    }
                }
                
                // count words
                if needsAll || defaults[.showStatusBarWords] {
                    numberOfWords = string.numberOfWords
                    if hasSelection {
                        numberOfSelectedWords = selectedString.numberOfWords
                    }
                }
                
                // calculate current location
                if needsAll || defaults[.showStatusBarLocation] {
                    let locString = (string as NSString).substring(to: selectedRange.location)
                    let stringForCounting = countsLineEnding ? locString : locString.removingLineEndings
                    location = stringForCounting.numberOfComposedCharacters
                }
                
                // calculate current line
                if needsAll || defaults[.showStatusBarLine] {
                    line = string.lineNumber(at: selectedRange.location)
                    
                }
                
                // calculate current column
                if needsAll || defaults[.showStatusBarColumn] {
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
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                
                strongSelf.length = CountFormatter.format(length, selected: selectedLength)
                strongSelf.chars = CountFormatter.format(numberOfChars, selected: numberOfSelectedChars)
                strongSelf.lines = CountFormatter.format(numberOfLines, selected: numberOfSelectedLines)
                strongSelf.words = CountFormatter.format(numberOfWords, selected: numberOfSelectedWords)
                strongSelf.location = CountFormatter.format(location)
                strongSelf.line = CountFormatter.format(line)
                strongSelf.column = CountFormatter.format(column)
                strongSelf.unicode = unicode
                
                NotificationCenter.default.post(name: .AnalyzerDidUpdateEditorInfo, object: strongSelf)
            }
        }
    }
    
}



private struct CountFormatter {
    
    private init() { }
    
    
    /// format count number with selection
    static func format(_ count: Int, selected selectedCount: Int? = nil) -> String {
        
        if let selectedCount = selectedCount, selectedCount > 0 {
            return String.localizedStringWithFormat("%li (%li)", count, selectedCount)
        }
        
        return String.localizedStringWithFormat("%li", count)
    }
    
}
