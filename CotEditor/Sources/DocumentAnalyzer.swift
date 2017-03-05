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
        
        let requiredInfo: EditorInfoTypes = {
            if self.needsUpdateEditorInfo { return .all }
            
            var types = EditorInfoTypes()
            if UserDefaults.standard[.showStatusBarLength]   { types.update(with: .length) }
            if UserDefaults.standard[.showStatusBarChars]    { types.update(with: .characters) }
            if UserDefaults.standard[.showStatusBarLines]    { types.update(with: .lines) }
            if UserDefaults.standard[.showStatusBarWords]    { types.update(with: .words) }
            if UserDefaults.standard[.showStatusBarLocation] { types.update(with: .location) }
            if UserDefaults.standard[.showStatusBarLine]     { types.update(with: .line) }
            if UserDefaults.standard[.showStatusBarColumn]   { types.update(with: .column) }
            return types
        }()
        
        let operation = EditorInfoCountOperation(string: NSString(string: document.textStorage.string) as String,
                                                 lineEnding: document.lineEnding,
                                                 selectedRange: textView.selectedRange,
                                                 requiredInfo: requiredInfo,
                                                 countsLineEnding: UserDefaults.standard[.countLineEndingAsChar])
        
        operation.completionBlock = { [weak self, weak operation] in
            guard
                let operation = operation, !operation.isCancelled,
                let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                strongSelf.length = CountFormatter.format(operation.length, selected: operation.selectedLength)
                strongSelf.chars = CountFormatter.format(operation.chars, selected: operation.selectedChars)
                strongSelf.lines = CountFormatter.format(operation.lines, selected: operation.selectedLines)
                strongSelf.words = CountFormatter.format(operation.words, selected: operation.selectedWords)
                strongSelf.location = CountFormatter.format(operation.location)
                strongSelf.line = CountFormatter.format(operation.line)
                strongSelf.column = CountFormatter.format(operation.column)
                strongSelf.unicode = operation.unicode
                
                NotificationCenter.default.post(name: .AnalyzerDidUpdateEditorInfo, object: strongSelf)
            }
        }
        
        // cancel waiting operations to avoid stacking large operations
        self.editorInfoCountOperationQueue.operations
            .filter { !$0.isExecuting }
            .forEach { $0.cancel() }
        
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
