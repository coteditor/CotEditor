//
//  DirectoryDocument+ScriptingSupport.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

extension DirectoryDocument {
    
    enum ScriptError: Error {
        
        case noCurrentDocumentError
    }
    
    
    // MARK: AppleScript Accessors
    
    /// Whole document string (text (NSTextStorage)).
    @objc var scriptTextStorage: Any {
        
        get { self.scriptDocument()?.scriptTextStorage ?? NSTextStorage(string: "") }
        set { self.scriptDocument()?.scriptTextStorage = newValue }
    }
    
    
    /// The document string (text (NSTextStorage)).
    @objc var contents: Any {
        
        get { self.scriptTextStorage }
        set { self.scriptTextStorage = newValue }
    }
    
    
    /// Selection-object (`TextSelection`).
    @objc var selectionObject: TextSelection? {
        
        self.scriptDocument()?.selectionObject
    }
    
    
    /// Current document of the folder document (optional).
    @objc var scriptCurrentDocument: Document? {
        
        self.currentDocument as? Document
    }
    
    
    /// Length of the document in UTF-16 (integer).
    @objc var length: Int {
        
        self.scriptDocument()?.length ?? 0
    }
    
    
    /// New line code (enum type).
    @objc var lineEndingChar: FourCharCode {
        
        get { self.scriptDocument()?.lineEndingChar ?? FourCharCode(code: "leLF") }
        set { self.scriptDocument()?.lineEndingChar = newValue }
    }
    
    
    /// Encoding name (Unicode text).
    @objc var encodingName: String {
        
        self.scriptDocument()?.encodingName ?? ""
    }
    
    
    /// Encoding in IANA CharSet name (Unicode text).
    @objc var IANACharSetName: String {
        
        self.scriptDocument()?.IANACharSetName ?? ""
    }
    
    
    /// Whether the document has an encoding BOM.
    @objc var hasBOM: Bool {
        
        self.scriptDocument()?.hasBOM ?? false
    }
    
    
    /// Whether the document is editable.
    @objc var isEditable: Bool {
        
        get { self.scriptDocument()?.isEditable ?? false }
        set { self.scriptDocument()?.isEditable = newValue }
    }
    
    
    /// Syntax name (Unicode text).
    @objc var coloringStyle: String {
        
        get { self.scriptDocument()?.coloringStyle ?? "" }
        set { self.scriptDocument()?.coloringStyle = newValue }
    }
    
    
    /// State of text wrapping (bool).
    @objc var wrapsLines: Bool {
        
        get { self.scriptDocument()?.wrapsLines ?? false }
        set { self.scriptDocument()?.wrapsLines = newValue }
    }
    
    
    /// Tab width (integer).
    @objc var tabWidth: Int {
        
        get { self.scriptDocument()?.tabWidth ?? 0 }
        set { self.scriptDocument()?.tabWidth = newValue }
    }
    
    
    /// Whether replace tab with spaces.
    @objc var expandsTab: Bool {
        
        get { self.scriptDocument()?.expandsTab ?? false }
        set { self.scriptDocument()?.expandsTab = newValue }
    }
    
    
    // MARK: AppleScript Handlers
    
    /// Handles the Convert AppleScript by changing the text encoding and converting the text.
    @objc func handleConvert(_ command: NSScriptCommand) -> NSNumber {
        
        guard let document = self.scriptDocument(for: command) else { return false }
        
        return document.handleConvert(command)
    }
    
    
    /// Handles the Find AppleScript command.
    @objc func handleFind(_ command: NSScriptCommand) -> NSNumber {
        
        guard let document = self.scriptDocument(for: command) else { return false }
        
        return document.handleFind(command)
    }
    
    
    /// Handles the Convert AppleScript by changing the text encoding and reinterpreting the text.
    @objc func handleReinterpret(_ command: NSScriptCommand) -> NSNumber {
        
        guard let document = self.scriptDocument(for: command) else { return false }
        
        return document.handleReinterpret(command)
    }
    
    
    /// Handles the Replace AppleScript command.
    @objc func handleReplace(_ command: NSScriptCommand) -> NSNumber {
        
        guard let document = self.scriptDocument(for: command) else { return 0 }
        
        return document.handleReplace(command)
    }
    
    
    /// Handles the Scroll AppleScript command by scrolling the text view to make selection visible.
    @objc func handleScroll(_ command: NSScriptCommand) {
        
        guard let document = self.scriptDocument(for: command) else { return }
        
        document.handleScroll(command)
    }
    
    
    /// Handles the Jump AppleScript command by moving the cursor to the specified line and scrolling the text view to make it visible.
    @objc func handleJump(_ command: NSScriptCommand) {
        
        guard let document = self.scriptDocument(for: command) else { return }
        
        document.handleJump(command)
    }
    
    
    /// Returns string in the specified range.
    @objc func handleString(_ command: NSScriptCommand) -> String? {
        
        guard let document = self.scriptDocument(for: command) else { return nil }
        
        return document.handleString(command)
    }
    
    
    // MARK: Private Methods
    
    /// Returns the current text document for the AppleScript command.
    ///
    /// - Parameter command: The AppleScript command that requires the current document.
    /// - Returns: The current text document, or `nil` if no text document is selected.
    private func scriptDocument(for command: NSScriptCommand? = nil) -> Document? {
        
        guard let document = self.currentDocument as? Document else {
            // report an AppleScript error
            let command = command ?? NSScriptCommand.current()
            command?.scriptErrorNumber = errOSAGeneralError
            command?.scriptErrorString = DirectoryDocument.ScriptError.noCurrentDocumentError.localizedDescription
            return nil
        }
        
        return document
    }
}


extension DirectoryDocument.ScriptError: LocalizedError {
    
    var errorDescription: String? {
        
        switch self {
            case .noCurrentDocumentError: "No current document."
        }
    }
}
