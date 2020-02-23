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
//  © 2014-2020 1024jp
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
    
    final class FileInfo: NSObject {
        
        @objc dynamic var creationDate: Date?
        @objc dynamic var modificationDate: Date?
        @objc dynamic var fileSize: NSNumber?
        @objc dynamic var filePath: URL?
        @objc dynamic var owner: String?
        @objc dynamic var permission: NSNumber?
        @objc dynamic var isReadOnly = false
    }
    
    final class ModeInfo: NSObject {
        
        @objc dynamic var encoding: String?
        @objc dynamic var lineEndings: String?
    }
    
    final class EditorInfo: NSObject {
        
        @objc dynamic var lines: String?
        @objc dynamic var chars: String?
        @objc dynamic var words: String?
        @objc dynamic var length: String?    // character length as UTF-16 string
        @objc dynamic var location: String?  // caret location from the beginning of document
        @objc dynamic var line: String?      // current line
        @objc dynamic var column: String?    // caret location from the beginning of line
        @objc dynamic var unicode: String?   // Unicode of selected single character (or surrogate-pair)
    }
    
    
    @objc dynamic var file = FileInfo()
    @objc dynamic var mode = ModeInfo()
    @objc dynamic var editor = EditorInfo()
}



// MARK: -

final class DocumentAnalyzer: NSObject {
    
    // MARK: Notification Names
    
    static let didUpdateFileInfoNotification = Notification.Name("DocumentAnalyzerDidUpdateFileInfo")
    static let didUpdateModeInfoNotification = Notification.Name("DocumentAnalyzerDidUpdateModeInfo")
    static let didUpdateEditorInfoNotification = Notification.Name("DocumentAnalyzerDidUpdateEditorInfo")
    
    
    // MARK: Public Properties
    
    var shouldUpdateEditorInfo = false  // need to update all editor info
    var shouldUpdateStatusEditorInfo = false  // need only to update editor info in satus bar
    var needsCountWholeText = true
    
    @objc private(set) dynamic var info = DocumentInfo()
    
    
    // MARK: Private Properties
    
    private weak var document: Document?  // weak to avoid cycle retain
    private var lastEidorCountResult = EditorCountResult()
    
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
        
        guard let document = self.document else { return assertionFailure() }
        
        self.info.file = document.fileInfo
        
        NotificationCenter.default.post(name: DocumentAnalyzer.didUpdateFileInfoNotification, object: self)
    }
    
    
    /// update current encoding and line endings
    func invalidateModeInfo() {
        
        guard let document = self.document else { return assertionFailure() }
        
        self.info.mode = document.modeInfo
        
        NotificationCenter.default.post(name: DocumentAnalyzer.didUpdateModeInfoNotification, object: self)
    }
    
    
    /// update editor info (only if really needed)
    func invalidateEditorInfo(onlySelection: Bool = false) {
        
        if !onlySelection {
            self.needsCountWholeText = true
        }
        
        guard self.shouldUpdateEditorInfo || self.shouldUpdateStatusEditorInfo else { return }
        
        self.editorUpdateTask.schedule()
    }
    
    
    
    // MARK: Private Methods
    
    /// info types needed to be calculated
    private var requiredInfoTypes: EditorInfoTypes {
        
        if self.shouldUpdateEditorInfo { return .all }
        
        var types = EditorInfoTypes()
        if UserDefaults.standard[.showStatusBarChars]    { types.formUnion(.characters) }
        if UserDefaults.standard[.showStatusBarLines]    { types.formUnion(.lines) }
        if UserDefaults.standard[.showStatusBarWords]    { types.formUnion(.words) }
        if UserDefaults.standard[.showStatusBarLocation] { types.formUnion(.location) }
        if UserDefaults.standard[.showStatusBarLine]     { types.formUnion(.line) }
        if UserDefaults.standard[.showStatusBarColumn]   { types.formUnion(.column) }
        
        return types
    }
    
    
    /// update editor info (only if really needed)
    private func updateEditorInfo() {
        
        guard
            let document = self.document,
            let textView = document.viewController?.focusedTextView,
            !textView.hasMarkedText()
            else { return }
        
        let requiredInfoTypes = self.requiredInfoTypes
        
        // do nothing if only cursor is moved but no need to calculate the cursor location.
        if !self.needsCountWholeText,
            requiredInfoTypes.isDisjoint(with: [.location, .line, .column]),
            textView.selectedRange.isEmpty,
            self.lastEidorCountResult.selectedCount.isEmpty
            { return }
        
        let string = textView.string.immutable
        let selectedRange = Range(textView.selectedRange, in: string) ?? string.startIndex..<string.startIndex
        let operation = EditorInfoCountOperation(string: string,
                                                 lineEnding: document.lineEnding,
                                                 selectedRange: selectedRange,
                                                 requiredInfo: requiredInfoTypes,
                                                 countsLineEnding: UserDefaults.standard[.countLineEndingAsChar],
                                                 countsWholeText: self.needsCountWholeText)
        operation.qualityOfService = .utility
        
        operation.completionBlock = { [weak self, weak operation] in
            guard let operation = operation, !operation.isCancelled else { return }
            
            let result = operation.result
            let didCountWholeText = operation.countsWholeText
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                var result = result
                if didCountWholeText {
                    self.needsCountWholeText = false
                } else {
                    result.count = self.lastEidorCountResult.count
                }
                self.lastEidorCountResult = result
                self.info.editor = result.info
                
                NotificationCenter.default.post(name: DocumentAnalyzer.didUpdateEditorInfoNotification, object: self)
            }
        }
        
        // cancel waiting operations to avoid stuck large operations
        self.editorInfoCountOperationQueue.cancelAllOperations()
        
        self.editorInfoCountOperationQueue.addOperation(operation)
    }
    
}



// MARK: -

private extension Document {
    
    var fileInfo: DocumentInfo.FileInfo {
        
        let attrs = self.fileAttributes
        
        let info = DocumentInfo.FileInfo()
        info.creationDate = attrs?[.creationDate] as? Date
        info.modificationDate = attrs?[.modificationDate] as? Date
        info.fileSize = attrs?[.size] as? NSNumber
        info.filePath = self.fileURL
        info.owner = attrs?[.ownerAccountName] as? String
        info.permission = attrs?[.posixPermissions] as? NSNumber
        info.isReadOnly = {
            guard !self.isInViewingMode else { return false }
            guard let posix = attrs?[.posixPermissions] as? UInt16 else { return false }
            
            return !FilePermissions(mask: posix).user.contains(.write)
        }()
        
        return info
    }
    
    
    var modeInfo: DocumentInfo.ModeInfo {
        
        let info = DocumentInfo.ModeInfo()
        info.encoding = String.localizedName(of: self.encoding, withUTF8BOM: self.hasUTF8BOM)
        info.lineEndings = self.lineEnding.name
        
        return info
    }
    
}



private extension EditorCountResult {
    
    var info: DocumentInfo.EditorInfo {
        
        let info = DocumentInfo.EditorInfo()
        info.length = self.format(\.length)
        info.chars = self.format(\.characters)
        info.lines = self.format(\.lines)
        info.words = self.format(\.words)
        info.location = self.format(\.location)
        info.line = self.format(\.line)
        info.column = self.format(\.column)
        info.unicode = self.unicode
        
        return info
    }
    
    
    private func format(_ keyPath: KeyPath<Count, Int>) -> String {
        
        let count = self.count[keyPath: keyPath]
        let selectedCount = self.selectedCount[keyPath: keyPath]
        
        if selectedCount > 0 {
            return String.localizedStringWithFormat("%li (%li)", count, selectedCount)
        }
        
        return String.localizedStringWithFormat("%li", count)
    }
    
    
    private func format(_ keyPath: KeyPath<Cursor, Int>) -> String {
        
        let count = self.cursor[keyPath: keyPath]
        
        return String.localizedStringWithFormat("%li", count)
    }
    
}
