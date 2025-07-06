//
//  WikiLink.swift
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

import Foundation

/// Represents a wiki-style link in the format [[Note Title]]
struct WikiLink: Hashable, Codable {
    
    /// The title of the linked note
    let title: String
    
    /// The range of the complete wiki link in the source text (including [[ and ]])
    let range: NSRange
    
    /// The range of just the title text (excluding [[ and ]])
    let titleRange: NSRange
    
    /// Whether this link is valid (i.e., the target note exists)
    var isValid: Bool = false
    
    /// Creates a new WikiLink instance
    /// - Parameters:
    ///   - title: The note title
    ///   - range: Complete range including brackets
    ///   - titleRange: Range of just the title text
    init(title: String, range: NSRange, titleRange: NSRange) {
        self.title = title
        self.range = range
        self.titleRange = titleRange
    }
}

/// Utility class for parsing and managing wiki links
final class WikiLinkParser {
    
    /// Regular expression pattern for matching [[Note Title]] format
    /// Supports:
    /// - Basic titles: [[My Note]]
    /// - Titles with spaces: [[Note with Spaces]]
    /// - Titles with special characters: [[Note-123_test]]
    /// - Unicode characters: [[📝 Note]]
    private static let wikiLinkPattern = #"\[\[([^\[\]]+)\]\]"#
    
    /// Compiled regex for performance
    private static let regex: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: wikiLinkPattern, options: [])
        } catch {
            fatalError("Invalid wiki link regex pattern: \(error)")
        }
    }()
    
    /// Finds all wiki links in the given text
    /// - Parameter text: The text to search for wiki links
    /// - Returns: Array of WikiLink objects found in the text
    static func findWikiLinks(in text: String) -> [WikiLink] {
        let nsString = text as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        let matches = regex.matches(in: text, options: [], range: range)
        
        return matches.compactMap { match in
            guard match.numberOfRanges >= 2 else { return nil }
            
            let fullRange = match.range(at: 0) // Complete [[title]] range
            let titleRange = match.range(at: 1) // Just the title part
            
            let fullText = nsString.substring(with: fullRange)
            let title = nsString.substring(with: titleRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Debug: Check what we're actually matching
            print("🔍 WikiLink regex matched: '\(fullText)' -> title: '\(title)' at range \(fullRange)")
            
            // Validate title is not empty
            guard !title.isEmpty else { return nil }
            
            return WikiLink(title: title, range: fullRange, titleRange: titleRange)
        }
    }
    
    /// Finds wiki links within a specific range of text
    /// - Parameters:
    ///   - text: The text to search
    ///   - searchRange: The range within the text to search
    /// - Returns: Array of WikiLink objects found in the specified range
    static func findWikiLinks(in text: String, range searchRange: NSRange) -> [WikiLink] {
        let nsString = text as NSString
        
        // Ensure search range is valid
        guard searchRange.location >= 0,
              searchRange.upperBound <= nsString.length else {
            return []
        }
        
        let matches = regex.matches(in: text, options: [], range: searchRange)
        
        return matches.compactMap { match in
            guard match.numberOfRanges >= 2 else { return nil }
            
            let fullRange = match.range(at: 0)
            let titleRange = match.range(at: 1)
            
            let title = nsString.substring(with: titleRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !title.isEmpty else { return nil }
            
            return WikiLink(title: title, range: fullRange, titleRange: titleRange)
        }
    }
    
    /// Checks if the given text position is within a wiki link
    /// - Parameters:
    ///   - text: The text to check
    ///   - position: The character position to check
    /// - Returns: The WikiLink containing this position, or nil if not in a link
    static func wikiLink(at position: Int, in text: String) -> WikiLink? {
        let links = findWikiLinks(in: text)
        return links.first { link in
            NSLocationInRange(position, link.range)
        }
    }
    
    /// Validates if a note title is valid for wiki links
    /// - Parameter title: The title to validate
    /// - Returns: True if the title is valid for use in wiki links
    static func isValidNoteTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Title must not be empty
        guard !trimmed.isEmpty else { return false }
        
        // Title must not contain brackets (to avoid nested links)
        guard !trimmed.contains("[") && !trimmed.contains("]") else { return false }
        
        // Title should not be excessively long
        guard trimmed.count <= 255 else { return false }
        
        return true
    }
    
    /// Creates a wiki link string from a note title
    /// - Parameter title: The note title
    /// - Returns: Formatted wiki link string like [[title]] or nil if title is invalid
    static func createWikiLink(title: String) -> String? {
        guard isValidNoteTitle(title) else { return nil }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return "[[\(trimmed)]]"
    }
}

// MARK: - Extensions for Integration

extension String {
    
    /// Convenience method to find wiki links in this string
    var wikiLinks: [WikiLink] {
        return WikiLinkParser.findWikiLinks(in: self)
    }
    
    /// Checks if this string contains any wiki links
    var containsWikiLinks: Bool {
        return !wikiLinks.isEmpty
    }
}