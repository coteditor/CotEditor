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
        
        get {
            guard let document = self.scriptDocument() else { return NSTextStorage(string: "") }
            return document.scriptTextStorage
        }
        
        set {
            guard let document = self.scriptDocument() else { return }
            document.scriptTextStorage = newValue
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
    
    
    /// Selection-object (`TextSelection`).
    @objc var selectionObject: TextSelection? {
        
        guard let document = self.scriptDocument() else { return nil }
        
        return document.selectionObject
    }
    
    
    /// Current document of the folder document (optional).
    @objc var scriptCurrentDocument: Document? {
        
        self.currentDocument as? Document
    }
    
    
    /// Length of the document in UTF-16 (integer).
    @objc var length: Int {
        
        guard let document = self.scriptDocument() else { return 0 }
        
        return document.length
    }
    
    
    /// New line code (enum type).
    @objc var lineEndingChar: FourCharCode {
        
        get {
            guard let document = self.scriptDocument() else { return FourCharCode(code: "leLF") }
            
            return document.lineEndingChar
        }
        
        set {
            guard let document = self.scriptDocument() else { return }
            
            document.lineEndingChar = newValue
        }
    }
    
    
    /// Encoding name (Unicode text).
    @objc var encodingName: String {
        
        guard let document = self.scriptDocument() else { return "" }
        
        return document.encodingName
    }
    
    
    /// Encoding in IANA CharSet name (Unicode text).
    @objc var IANACharSetName: String {
        
        guard let document = self.scriptDocument() else { return "" }
        
        return document.IANACharSetName
    }
    
    
    /// Whether the document has an encoding BOM.
    @objc var hasBOM: Bool {
        
        guard let document = self.scriptDocument() else { return false }
        
        return document.hasBOM
    }
    
    
    /// Whether the document is editable.
    @objc var isEditable: Bool {
        
        get {
            guard let document = self.scriptDocument() else { return false }
            
            return document.isEditable
        }
        
        set {
            guard let document = self.scriptDocument() else { return }
            
            document.isEditable = newValue
        }
    }
    
    
    /// Syntax name (Unicode text).
    @objc var coloringStyle: String {
        
        get {
            guard let document = self.scriptDocument() else { return "" }
            
            return document.coloringStyle
        }
        
        set {
            guard let document = self.scriptDocument() else { return }
            
            document.coloringStyle = newValue
        }
    }
    
    
    /// State of text wrapping (bool).
    @objc var wrapsLines: Bool {
        
        get {
            guard let document = self.scriptDocument() else { return false }
            
            return document.wrapsLines
        }
        
        set {
            guard let document = self.scriptDocument() else { return }
            
            document.wrapsLines = newValue
        }
    }
    
    
    /// Tab width (integer).
    @objc var tabWidth: Int {
        
        get {
            guard let document = self.scriptDocument() else { return 0 }
            
            return document.tabWidth
        }
        
        set {
            guard let document = self.scriptDocument() else { return }
            
            document.tabWidth = newValue
        }
    }
    
    
    /// Whether replace tab with spaces.
    @objc var expandsTab: Bool {
        
        get {
            guard let document = self.scriptDocument() else { return false }
            
            return document.expandsTab
        }
        
        set {
            guard let document = self.scriptDocument() else { return }
            
            document.expandsTab = newValue
        }
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
    
    private func scriptDocument(for command: NSScriptCommand? = nil) -> Document? {
        
        guard let document = self.currentDocument as? Document else {
            self.reportNoCurrentDocument(command)
            return nil
        }
        
        return document
    }
    
    
    private func reportNoCurrentDocument(_ command: NSScriptCommand?) {
        
        let command = command ?? NSScriptCommand.current()
        command?.scriptErrorNumber = errOSAGeneralError
        command?.scriptErrorString = DirectoryDocument.ScriptError.noCurrentDocumentError.localizedDescription
    }
}


private extension DirectoryDocument.ScriptError {
    
    var description: String {
        
        switch self {
            case .noCurrentDocumentError: "No current document."
        }
    }
}
