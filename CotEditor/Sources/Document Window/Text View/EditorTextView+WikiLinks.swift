//
//  EditorTextView+WikiLinks.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by Claude Code on 2025-01-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 CotEditor Project
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
import Foundation

// MARK: - Wiki Link Support

extension EditorTextView {
    
    // MARK: - Wiki Link Navigation
    
    
    /// Follows a wiki link by attempting to open the referenced note
    /// - Parameter wikiLink: The wiki link to follow
    func openWikiLink(_ wikiLink: WikiLink) {
        print("📖 Opening wiki link: '\(wikiLink.title)'")
        
        // Get the current document's directory
        guard let window = self.window,
              let windowController = window.windowController,
              let currentDocument = windowController.document as? Document else {
            print("❌ No current document available")
            showWikiLinkError("Cannot determine current document")
            return
        }
        
        guard let currentFileURL = currentDocument.fileURL else {
            print("❌ Document has no file URL - document needs to be saved first")
            showWikiLinkError("Please save the current document first before creating wiki links")
            return
        }
        
        let currentDirectory = currentFileURL.deletingLastPathComponent()
        let targetFileName = "\(wikiLink.title).md"
        let targetFileURL = currentDirectory.appendingPathComponent(targetFileName)
        
        // Check if we have write access to the directory
        let fileManager = FileManager.default
        if !fileManager.isWritableFile(atPath: currentDirectory.path) {
            print("❌ No write permission to directory: \(currentDirectory.path)")
            showWikiLinkError("No permission to create files in '\(currentDirectory.lastPathComponent)'. Try saving the current document first.")
            return
        }
        
        print("📁 Target file: \(targetFileURL.path)")
        
        // Check if target file exists
        if fileManager.fileExists(atPath: targetFileURL.path) {
            print("✅ File exists, opening: \(targetFileURL.path)")
            openExistingFile(at: targetFileURL)
        } else {
            print("📝 File doesn't exist, creating: \(targetFileURL.path)")
            createAndOpenNewFile(at: targetFileURL, title: wikiLink.title)
        }
    }
    
    /// Opens an existing file in a new document window
    /// - Parameter fileURL: The file to open
    private func openExistingFile(at fileURL: URL) {
        DispatchQueue.main.async {
            NSDocumentController.shared.openDocument(withContentsOf: fileURL, display: true) { document, wasAlreadyOpen, error in
                if let error = error {
                    print("❌ Error opening file: \(error)")
                    self.showWikiLinkError("Failed to open '\(fileURL.lastPathComponent)': \(error.localizedDescription)")
                } else if let document = document {
                    print("✅ Successfully opened: \(fileURL.lastPathComponent)")
                } else {
                    print("⚠️ Document opened but no document object returned")
                }
            }
        }
    }
    
    /// Creates a new note file and opens it
    /// - Parameters:
    ///   - fileURL: The location to create the file
    ///   - title: The title of the note
    private func createAndOpenNewFile(at fileURL: URL, title: String) {
        // Create basic note content
        let noteContent = "# \(title)\n\n"
        
        // Use NSDocument's creation method which handles sandboxing properly
        DispatchQueue.main.async {
            do {
                // Try to create the document through the document controller
                let documentController = NSDocumentController.shared
                let document = try documentController.makeUntitledDocument(ofType: "public.plain-text")
                
                // Set the content
                if let textDocument = document as? Document {
                    textDocument.textStorage.replaceCharacters(in: NSRange(location: 0, length: textDocument.textStorage.length), with: noteContent)
                    
                    // Save to the target location
                    textDocument.save(to: fileURL, ofType: "public.plain-text", for: .saveAsOperation) { error in
                        if let error = error {
                            print("❌ Error saving new document: \(error)")
                            self.showWikiLinkError("Failed to create '\(title).md': \(error.localizedDescription)")
                        } else {
                            print("✅ Created new note file: \(fileURL.path)")
                            // Document is automatically displayed after save
                        }
                    }
                } else {
                    self.fallbackCreateFile(at: fileURL, content: noteContent, title: title)
                }
                
            } catch {
                print("❌ Error creating document: \(error)")
                // Fallback to direct file creation
                self.fallbackCreateFile(at: fileURL, content: noteContent, title: title)
            }
        }
    }
    
    /// Fallback method for direct file creation
    /// - Parameters:
    ///   - fileURL: The location to create the file
    ///   - content: The content to write
    ///   - title: The title for error messages
    private func fallbackCreateFile(at fileURL: URL, content: String, title: String) {
        do {
            // Write the file directly
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Created new note file (fallback): \(fileURL.path)")
            
            // Open the newly created file
            openExistingFile(at: fileURL)
            
        } catch {
            print("❌ Error creating file (fallback): \(error)")
            showWikiLinkError("Failed to create '\(title).md': \(error.localizedDescription)")
        }
    }
    
    /// Shows an error message for wiki link operations
    /// - Parameter message: The error message to display
    private func showWikiLinkError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Wiki Link Error"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            
            if let window = self.window {
                alert.beginSheetModal(for: window)
            } else {
                alert.runModal()
            }
        }
    }
    
    /// Shows information about a wiki link
    /// - Parameter wikiLink: The wiki link to show info for
    private func showWikiLinkInfo(_ wikiLink: WikiLink) {
        // For now, just show a simple message
        // This could be enhanced with a proper popover in the future
        print("ℹ️ Wiki Link Info: '\(wikiLink.title)'")
        
        // Could implement tooltip or popover here in the future
        let alert = NSAlert()
        alert.messageText = "Wiki Link"
        alert.informativeText = "Link to: \(wikiLink.title)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        if let window = self.window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
    
    // MARK: - Menu Actions
    
    /// Action to follow the wiki link at the current cursor position
    @IBAction func followWikiLink(_ sender: Any?) {
        let cursorPosition = self.selectedRange.location
        if let wikiLink = WikiLinkParser.wikiLink(at: cursorPosition, in: self.string) {
            openWikiLink(wikiLink)
        }
    }
    
    /// Action to create a new wiki link from selected text
    @IBAction func createWikiLink(_ sender: Any?) {
        guard !self.selectedRange.isEmpty else { return }
        
        let selectedText = (self.string as NSString).substring(with: self.selectedRange)
        let trimmedText = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard WikiLinkParser.isValidNoteTitle(trimmedText) else {
            NSSound.beep()
            return
        }
        
        if let wikiLinkText = WikiLinkParser.createWikiLink(title: trimmedText) {
            self.insertText(wikiLinkText, replacementRange: self.selectedRange)
        }
    }
    
    /// Validates menu items for wiki link actions
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
            case #selector(EditorTextView.followWikiLink(_:)):
                let cursorPosition = self.selectedRange.location
                return WikiLinkParser.wikiLink(at: cursorPosition, in: self.string) != nil
                
            case #selector(EditorTextView.createWikiLink(_:)):
                return !self.selectedRange.isEmpty
                
            default:
                return super.validateMenuItem(menuItem)
        }
    }
}