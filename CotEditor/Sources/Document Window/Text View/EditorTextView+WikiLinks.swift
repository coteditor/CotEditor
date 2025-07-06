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
    
    /// Notification posted when wiki links are detected or updated
    static let wikiLinksDidUpdateNotification = Notification.Name("EditorTextViewWikiLinksDidUpdate")
    
    /// User info key for the updated wiki links array
    static let wikiLinksKey = "wikiLinks"
    
    /// User info key for the affected range
    static let affectedRangeKey = "affectedRange"
    
    // MARK: - Wiki Link Detection
    
    /// Detects wiki links in the vicinity of a text change and updates syntax highlighting
    /// - Parameter range: The range of text that was modified
    func detectWikiLinksAfterTextChange(in range: NSRange) {
        // Expand the search range to include potential partial links
        let expandedRange = expandedRangeForWikiLinkDetection(around: range)
        
        // Find wiki links in the expanded range
        let text = self.string
        let wikiLinks = WikiLinkParser.findWikiLinks(in: text, range: expandedRange)
        
        // Update syntax highlighting for the detected links
        updateWikiLinkHighlighting(for: wikiLinks, in: expandedRange)
        
        // Post notification about the wiki link updates
        NotificationCenter.default.post(
            name: Self.wikiLinksDidUpdateNotification,
            object: self,
            userInfo: [
                Self.wikiLinksKey: wikiLinks,
                Self.affectedRangeKey: NSValue(range: expandedRange)
            ]
        )
    }
    
    /// Expands a range to include complete lines and potential partial wiki links
    /// - Parameter range: The original range
    /// - Returns: Expanded range that ensures complete wiki link detection
    private func expandedRangeForWikiLinkDetection(around range: NSRange) -> NSRange {
        let text = self.string as NSString
        
        // Start from the beginning of the line containing the range start
        let startLineRange = text.lineRange(for: NSRange(location: range.location, length: 0))
        
        // End at the end of the line containing the range end
        let endLocation = min(range.upperBound, text.length)
        let endLineRange = text.lineRange(for: NSRange(location: endLocation, length: 0))
        
        // Create the expanded range
        let expandedRange = NSRange(
            location: startLineRange.location,
            length: endLineRange.upperBound - startLineRange.location
        )
        
        // Further expand to catch potential partial links at boundaries
        let buffer = 10 // characters to look beyond line boundaries
        let finalStart = max(0, expandedRange.location - buffer)
        let finalEnd = min(text.length, expandedRange.upperBound + buffer)
        
        return NSRange(location: finalStart, length: finalEnd - finalStart)
    }
    
    /// Updates syntax highlighting for wiki links in the specified range
    /// - Parameters:
    ///   - wikiLinks: The wiki links to highlight
    ///   - range: The range to update highlighting in
    private func updateWikiLinkHighlighting(for wikiLinks: [WikiLink], in range: NSRange) {
        guard let textStorage = self.textStorage else { return }
        
        // Remove existing wiki link attributes in the range
        textStorage.removeAttribute(.wikiLink, range: range)
        textStorage.removeAttribute(.wikiLinkTitle, range: range)
        
        // Apply wiki link attributes
        for wikiLink in wikiLinks {
            // Highlight the complete link with brackets
            textStorage.addAttribute(.wikiLink, value: wikiLink, range: wikiLink.range)
            
            // Highlight just the title portion differently
            textStorage.addAttribute(.wikiLinkTitle, value: wikiLink.title, range: wikiLink.titleRange)
        }
        
        // Request display update for the affected range
        self.layoutManager?.invalidateDisplay(forCharacterRange: range)
    }
    
    // MARK: - Wiki Link Interaction
    
    /// Handles mouse clicks on wiki links
    /// - Parameter event: The mouse event
    /// - Returns: True if the click was handled as a wiki link navigation
    @discardableResult
    func handleWikiLinkClick(with event: NSEvent) -> Bool {
        let point = self.convert(event.locationInWindow, from: nil)
        let clickedIndex = self.characterIndexForInsertion(at: point)
        
        guard clickedIndex < self.string.count else { return false }
        
        // Check if click is on a wiki link
        if let wikiLink = WikiLinkParser.wikiLink(at: clickedIndex, in: self.string) {
            // Handle modifier keys
            if event.modifierFlags.contains(.command) {
                // Command+click: Follow link
                openWikiLink(wikiLink)
                return true
            } else if event.modifierFlags.contains(.option) {
                // Option+click: Show link preview or info
                showWikiLinkInfo(wikiLink)
                return true
            }
        }
        
        return false
    }
    
    /// Follows a wiki link by attempting to open the referenced note
    /// - Parameter wikiLink: The wiki link to follow
    private func openWikiLink(_ wikiLink: WikiLink) {
        // Post notification that a wiki link should be followed
        // The document controller or window controller will handle the actual navigation
        NotificationCenter.default.post(
            name: .followWikiLink,
            object: self,
            userInfo: [
                "wikiLink": wikiLink,
                "noteTitle": wikiLink.title
            ]
        )
    }
    
    /// Shows information about a wiki link
    /// - Parameter wikiLink: The wiki link to show info for
    private func showWikiLinkInfo(_ wikiLink: WikiLink) {
        // For now, just show a simple tooltip
        // This could be enhanced with a proper popover in the future
        let message = "Wiki Link: \(wikiLink.title)"
        let rect = self.boundingRect(for: NSRange(location: wikiLink.range.location, length: wikiLink.range.length)) ?? .zero
        
        // You could show a tooltip or popover here
        // For now, we'll just post a notification
        NotificationCenter.default.post(
            name: .showWikiLinkInfo,
            object: self,
            userInfo: [
                "wikiLink": wikiLink,
                "noteTitle": wikiLink.title,
                "rect": NSValue(rect: rect)
            ]
        )
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

// MARK: - NSAttributedString.Key Extensions

extension NSAttributedString.Key {
    
    /// Attribute key for marking complete wiki links (including brackets)
    static let wikiLink = NSAttributedString.Key("wikiLink")
    
    /// Attribute key for marking wiki link titles (excluding brackets)
    static let wikiLinkTitle = NSAttributedString.Key("wikiLinkTitle")
}

// MARK: - Notification Names

extension Notification.Name {
    
    /// Posted when a wiki link should be followed
    static let followWikiLink = Notification.Name("followWikiLink")
    
    /// Posted when wiki link info should be shown
    static let showWikiLinkInfo = Notification.Name("showWikiLinkInfo")
}