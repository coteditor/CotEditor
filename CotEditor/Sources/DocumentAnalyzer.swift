//
//  DocumentAnalyzer.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-12-18.
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

final class DocumentInfo: NSObject {
    
    // file info
    @objc dynamic var creationDate: Date?
    @objc dynamic var modificationDate: Date?
    @objc dynamic var fileSize: NSNumber?
    @objc dynamic var filePath: URL?
    @objc dynamic var owner: String?
    @objc dynamic var permission: NSNumber?
    @objc dynamic var isReadOnly = false
    
    // mode info
    @objc dynamic var encoding: String?
    @objc dynamic var charsetName: String?
    @objc dynamic var lineEndings: String?
    
    // editor info
    @objc dynamic var lines: String?
    @objc dynamic var chars: String?
    @objc dynamic var words: String?
    @objc dynamic var length: String?    // character length as UTF-16 string
    @objc dynamic var location: String?  // caret location from the beginning of document
    @objc dynamic var line: String?      // current line
    @objc dynamic var column: String?    // caret location from the beginning of line
    @objc dynamic var unicode: String?   // Unicode of selected single character (or surrogate-pair)
}



// MARK: -

final class DocumentAnalyzer: NSObject {
    
    // MARK: Notification Names
    
    static let didUpdateFileInfoNotification = Notification.Name("DocumentAnalyzerDidUpdateFileInfo")
    static let didUpdateModeInfoNotification = Notification.Name("DocumentAnalyzerDidUpdateModeInfo")
    static let didUpdateEditorInfoNotification = Notification.Name("DocumentAnalyzerDidUpdateEditorInfo")
    
    
    // MARK: Public Properties
    
    var needsUpdateEditorInfo = false  // need to update all editor info
    var needsUpdateStatusEditorInfo = false  // need only to update editor info in satus bar
    
    @objc private(set) dynamic var info = DocumentInfo()
    
    
    // MARK: Private Properties
    
    private weak var document: Document?  // weak to avoid cycle retain
    
    private lazy var editorUpdateTask = Debouncer(delay: .milliseconds(200)) { [weak self] in self?.updateEditorInfo() }
    private let editorInfoCountOperationQueue = OperationQueue(name: "com.coteditor.CotEditor.EditorInfoCountOperationQueue",
                                                               qos: .userInitiated)
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
        
        super.init()
        
        self.editorInfoCountOperationQueue.maxConcurrentOperationCount = 1
    }
    
    
    deinit {
        self.editorInfoCountOperationQueue.cancelAllOperations()
    }
    
    
    
    // MARK: Public Methods
    
    /// update file info
    func invalidateFileInfo() {
        
        guard let document = self.document else { return }
        
        let attrs = document.fileAttributes
        
        self.info.creationDate = attrs?[.creationDate] as? Date
        self.info.modificationDate = attrs?[.modificationDate] as? Date
        self.info.fileSize = attrs?[.size] as? NSNumber
        self.info.filePath = document.fileURL
        self.info.owner = attrs?[.ownerAccountName] as? String
        self.info.permission = attrs?[.posixPermissions] as? NSNumber
        self.info.isReadOnly = {
            guard !document.isInViewingMode else { return false }
            guard let posix = attrs?[.posixPermissions] as? UInt16 else { return false }
            
            return !FilePermissions(mask: posix).user.contains(.write)
        }()
        
        NotificationCenter.default.post(name: DocumentAnalyzer.didUpdateFileInfoNotification, object: self)
    }
    
    
    /// update current encoding and line endings
    func invalidateModeInfo() {
        
        guard let document = self.document else { return }
        
        self.info.encoding = String.localizedName(of: document.encoding, withUTF8BOM: document.hasUTF8BOM)
        self.info.charsetName = document.encoding.ianaCharSetName
        self.info.lineEndings = document.lineEnding.name
        
        NotificationCenter.default.post(name: DocumentAnalyzer.didUpdateModeInfoNotification, object: self)
    }
    
    
    /// update editor info (only if really needed)
    func invalidateEditorInfo() {
        
        guard self.needsUpdateEditorInfo || self.needsUpdateStatusEditorInfo else { return }
        
        self.editorUpdateTask.schedule()
    }
    
    
    
    // MARK: Private Methods
    
    /// info types needed to be calculated
    private var requiredInfoTypes: EditorInfoTypes {
        
        if self.needsUpdateEditorInfo { return .all }
        
        var types = EditorInfoTypes()
        if UserDefaults.standard[.showStatusBarChars]    { types.update(with: .characters) }
        if UserDefaults.standard[.showStatusBarLines]    { types.update(with: .lines) }
        if UserDefaults.standard[.showStatusBarWords]    { types.update(with: .words) }
        if UserDefaults.standard[.showStatusBarLocation] { types.update(with: .location) }
        if UserDefaults.standard[.showStatusBarLine]     { types.update(with: .line) }
        if UserDefaults.standard[.showStatusBarColumn]   { types.update(with: .column) }
        return types
    }
    
    
    /// update editor info (only if really needed)
    private func updateEditorInfo() {
        
        guard
            let document = self.document,
            let textView = document.viewController?.focusedTextView,
            !textView.hasMarkedText() else { return }
        
        let string = textView.string.immutable
        let selectedRange = Range(textView.selectedRange, in: string) ?? string.startIndex..<string.startIndex
        let operation = EditorInfoCountOperation(string: string,
                                                 lineEnding: document.lineEnding,
                                                 selectedRange: selectedRange,
                                                 requiredInfo: self.requiredInfoTypes,
                                                 countsLineEnding: UserDefaults.standard[.countLineEndingAsChar])
        operation.qualityOfService = .utility
        
        operation.completionBlock = { [weak self, weak operation] in
            guard let operation = operation, !operation.isCancelled else { return }
            
            let result = operation.result
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.info.length = CountFormatter.format(result.length, selected: result.selectedLength)
                self.info.chars = CountFormatter.format(result.characters, selected: result.selectedCharacters)
                self.info.lines = CountFormatter.format(result.lines, selected: result.selectedLines)
                self.info.words = CountFormatter.format(result.words, selected: result.selectedWords)
                self.info.location = CountFormatter.format(result.location)
                self.info.line = CountFormatter.format(result.line)
                self.info.column = CountFormatter.format(result.column)
                self.info.unicode = result.unicode
                
                NotificationCenter.default.post(name: DocumentAnalyzer.didUpdateEditorInfoNotification, object: self)
            }
        }
        
        // cancel waiting operations to avoid stuck large operations
        self.editorInfoCountOperationQueue.cancelAllOperations()
        
        self.editorInfoCountOperationQueue.addOperation(operation)
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
