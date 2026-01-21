//
//  String+Commenting.swift
//  TextEditing
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2026 1024jp
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

public import Foundation
public import StringUtils

public protocol CommentDelimiters {
    
    var inline: String? { get }
    var blocks: [Pair<String>] { get }
}


public struct CommentTypes: OptionSet, Sendable {
    
    public var rawValue: Int
    
    public static let inline = Self(rawValue: 1 << 0)
    public static let block = Self(rawValue: 1 << 1)
    
    public static let both: Self = [.inline, .block]
    
    
    public init(rawValue: Int) {
        
        self.rawValue = rawValue
    }
}


public enum CommentOutLocation: Sendable {
    
    /// Inserts delimiters for the selections.
    case selection
    
    /// Inserts delimiters at the beginning of lines.
    case line
    
    /// Inserts the delimiter after the common minimal visual indentation across the targeted lines.
    case afterIndent(tabWidth: Int)
}


public extension String {
    
    /// Comments out the selections by appending comment delimiters.
    ///
    /// - Parameters:
    ///   - types: The commenting style to apply. If `.both` is specified, inline comments take precedence over block comments.
    ///   - delimiters: The comment delimiters to apply.
    ///   - spacer: The spacer between delimiter and string.
    ///   - selectedRanges: The current selected ranges in the editor.
    ///   - location: The location type to insert comment delimiters.
    func commentOut(types: CommentTypes, delimiters: any CommentDelimiters, spacer: String, in selectedRanges: [NSRange], at location: CommentOutLocation) -> EditingContext? {
        
        guard !delimiters.isEmpty else { return nil }
        
        let items: [NSRange.InsertionItem] = {
            if types.contains(.inline), let delimiter = delimiters.inline {
                return self.inlineCommentOut(delimiter: delimiter, spacer: spacer, ranges: selectedRanges, at: location)
            }
            if types.contains(.block), let delimiters = delimiters.blocks.first {
                return self.blockCommentOut(delimiters: delimiters, spacer: spacer, ranges: selectedRanges, at: location)
            }
            return []
        }()
        
        guard !items.isEmpty else { return nil }
        
        let newStrings = items.map(\.string)
        let replacementRanges = items.map { NSRange(location: $0.location, length: 0) }
        let newSelectedRanges = selectedRanges.map { $0.inserted(items: items) }
        
        return EditingContext(strings: newStrings, ranges: replacementRanges, selectedRanges: newSelectedRanges)
    }
    
    
    /// Uncomments the selections by removing comment delimiters.
    ///
    /// - Parameters:
    ///   - delimiters: The comment delimiters to remove.
    ///   - selectedRanges: The current selected ranges in the editor.
    func uncomment(delimiters: any CommentDelimiters, spacer: String, in selectedRanges: [NSRange]) -> EditingContext? {
        
        guard !delimiters.isEmpty else { return nil }
        
        let deletionRanges: [NSRange] = {
            
            if let delimiters = delimiters.blocks.first {
                let targetRanges = selectedRanges.map { $0.isEmpty ? self.lineContentsRange(for: $0) : $0 }.uniqued
                if let ranges = self.rangesOfBlockDelimiters(delimiters, spacer: spacer, ranges: targetRanges) {
                    return ranges
                }
            }
            if let delimiter = delimiters.inline {
                let targetRanges = selectedRanges.map(self.lineContentsRange(for:)).uniqued
                if let ranges = self.rangesOfInlineDelimiter(delimiter, spacer: spacer, ranges: targetRanges) {
                    return ranges
                }
            }
            return []
        }()
        
        guard !deletionRanges.isEmpty else { return nil }
        
        let newStrings = [String](repeating: "", count: deletionRanges.count)
        let newSelectedRanges = selectedRanges.map { $0.removed(ranges: deletionRanges) }
        
        return EditingContext(strings: newStrings, ranges: deletionRanges, selectedRanges: newSelectedRanges)
    }
    
    
    /// Returns whether the selected ranges can be uncommented.
    ///
    /// - Parameters:
    ///   - partly: If `true`, returns `true` when any part of the selection can be uncommented.;
    ///             otherwise, returns `true` only when the entire selection can be uncommented.
    ///   - delimiters: The comment delimiters to detect.
    ///   - selectedRanges: The current selected ranges in the editor.
    /// - Returns: `true` if uncommenting is possible.
    func canUncomment(partly: Bool, delimiters: any CommentDelimiters, in selectedRanges: [NSRange]) -> Bool {
        
        guard !delimiters.isEmpty else { return false }
        
        let targetRanges = selectedRanges
            .map(self.lineContentsRange(for:))
            .filter({ !$0.isEmpty })
            .uniqued
        
        guard !targetRanges.isEmpty else { return false }
        
        if let delimiters = delimiters.blocks.first,
           let ranges = self.rangesOfBlockDelimiters(delimiters, spacer: "", ranges: targetRanges)
        {
            return partly ? true : (ranges.count == (2 * targetRanges.count))
        }
        
        if let delimiter = delimiters.inline,
           let ranges = self.rangesOfInlineDelimiter(delimiter, spacer: "", ranges: targetRanges)
        {
            let lineRanges = targetRanges.flatMap(self.lineContentsRanges(for:)).uniqued
            return partly ? true : (ranges.count == lineRanges.count)
        }
        
        return false
    }
}


extension CommentDelimiters {
    
    var isEmpty: Bool { self.inline == nil && self.blocks.isEmpty }
}


extension String {
    
    /// Returns the editing information to comment out the given `ranges` by appending inline-style comment delimiters.
    ///
    /// - Parameters:
    ///   - delimiter: The inline comment delimiter to insert.
    ///   - spacer: The spacer between delimiter and string.
    ///   - ranges: The ranges whose lines should be commented out.
    ///   - location: The location type to insert comment delimiters.
    /// - Returns: Items that contain editing information to insert comment delimiters.
    func inlineCommentOut(delimiter: String, spacer: String = "", ranges: [NSRange], at location: CommentOutLocation) -> [NSRange.InsertionItem] {
        
        let locations = switch location {
            case .selection:
                ranges
                    .flatMap(self.lineContentsRanges(for:))
                    .map(\.location)
            case .line:
                ranges
                    .map { (self as NSString).lineRange(for: $0) }
                    .flatMap(self.lineContentsRanges(for:))
                    .map(\.location)
                    .uniqued
            case .afterIndent(let tabWidth):
                self.minimumCommonIndentationLocations(for: ranges, tabWidth: tabWidth)
        }
        
        return locations.map { NSRange.InsertionItem(string: delimiter + spacer, location: $0, forward: true) }
    }
    
    
    /// Returns the editing information to comment out the given `ranges` by appending block-style comment delimiters.
    ///
    /// - Parameters:
    ///   - delimiters: The pair of block comment delimiters to insert.
    ///   - spacer: The spacer between delimiter and string.
    ///   - ranges: The ranges where to comment out.
    ///   - location: The location type to insert comment delimiters.
    /// - Returns: Items that contain editing information to insert comment delimiters.
    func blockCommentOut(delimiters: Pair<String>, spacer: String = "", ranges: [NSRange], at location: CommentOutLocation) -> [NSRange.InsertionItem] {
        
        let targetRanges = switch location {
            case .selection:
                ranges
            case .line:
                ranges
                    .map(self.lineContentsRange(for:))
                    .merged
            case .afterIndent:
                ranges
                    .map(self.lineContentsRange(for:))
                    .map {
                        let range = (self as NSString).range(of: "[ \\t]*", options: [.regularExpression, .anchored], range: $0)
                        return range.isNotFound ? range : NSRange(range.upperBound..<$0.upperBound)
                    }
                    .merged
        }
        
        return targetRanges.flatMap {
            [NSRange.InsertionItem(string: delimiters.begin + spacer, location: $0.lowerBound, forward: true),
             NSRange.InsertionItem(string: spacer + delimiters.end, location: $0.upperBound, forward: false)]
        }
    }
    
    
    /// Finds inline-style delimiters in `ranges`.
    ///
    /// - Parameters:
    ///   - delimiter: The inline delimiter to find.
    ///   - spacer: The spacer between delimiter and string.
    ///   - ranges: The ranges where to find.
    /// - Returns: Ranges where delimiters and spacers are, or `nil` when no delimiters was found.
    func rangesOfInlineDelimiter(_ delimiter: String, spacer: String, ranges: [NSRange]) -> [NSRange]? {
        
        let ranges = ranges.filter { !$0.isEmpty }
        
        guard !ranges.isEmpty, !self.isEmpty else { return [] }
        
        let delimiterPattern = NSRegularExpression.escapedPattern(for: delimiter)
        let spacerPattern = spacer.isEmpty ? "" : "(?:\(spacer))?"
        let pattern = "^[ \t]*(\(delimiterPattern + spacerPattern))"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        
        let delimiterRanges = ranges
            .flatMap { regex.matches(in: self, range: $0) }
            .map { $0.range(at: 1) }
            .uniqued
        
        return delimiterRanges.isEmpty ? nil : delimiterRanges
    }
    
    
    /// Finds block-style delimiters in `ranges`.
    ///
    /// - Note: This method matches a block only when one of the given `ranges` fits exactly.
    ///
    /// - Parameters:
    ///   - delimiters: The pair of block delimiters to find.
    ///   - spacer: The spacer between delimiter and string.
    ///   - ranges: The ranges where to find.
    /// - Returns: Ranges where delimiters and spacers are, or `nil` when no delimiters was found.
    func rangesOfBlockDelimiters(_ delimiters: Pair<String>, spacer: String, ranges: [NSRange]) -> [NSRange]? {
        
        let ranges = ranges.filter { !$0.isEmpty }
        
        guard !ranges.isEmpty, !self.isEmpty else { return [] }
        
        let beginPattern = NSRegularExpression.escapedPattern(for: delimiters.begin)
        let endPattern = NSRegularExpression.escapedPattern(for: delimiters.end)
        let spacerPattern = spacer.isEmpty ? "" : "(?:\(spacer))?"
        let pattern = "\\A[ \t]*(\(beginPattern + spacerPattern)).*?(\(spacerPattern + endPattern))[ \t]*\\Z"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        let delimiterRanges = ranges
            .flatMap { regex.matches(in: self, range: $0) }
            .flatMap { [$0.range(at: 1), $0.range(at: 2)] }
        
        return delimiterRanges.isEmpty ? nil : delimiterRanges
    }
    
    
    // MARK: Private Methods
    
    /// Computes insertion locations at the minimal common visual indentation for the given ranges.
    ///
    /// - Parameters:
    ///   - ranges: The ranges whose corresponding line starts are evaluated.
    ///   - tabWidth: The visual width to treat a tab character as when computing indentation.
    /// - Returns: The UTF16-based character indexes.
    private func minimumCommonIndentationLocations(for ranges: [NSRange], tabWidth: Int) -> [Int] {
        
        let lines = (self as NSString).lineRanges(for: ranges, includingLastEmptyLine: true)
            .map { (string: (self as NSString).substring(with: $0), range: $0) }
        
        // find minimal visual indentation among non-empty lines
        let minVisualOffset = lines
            .map(\.string)
            .compactMap { line in
                var visualOffset = 0
                for character in line {
                    switch character {
                        case "\t":
                            visualOffset += tabWidth
                        case " ":
                            visualOffset += 1
                        case "\n", "\r", "\u{0085}", "\u{2028}", "\u{2029}":  // line breaks
                            return nil
                        default:
                            return visualOffset
                    }
                }
                return  nil
            }
            .min() ?? 0
        
        return lines
            .map { line in
                // find the character index where visual width reaches target visual indent
                var charOffset = 0
                var visualOffset = 0
                scan: for character in line.string {
                    switch character {
                        case "\t":
                            visualOffset += tabWidth
                        case " ":
                            visualOffset += 1
                        default:
                            break scan
                    }
                    if visualOffset > minVisualOffset { break scan }
                    
                    charOffset += 1
                }
                
                return min(line.range.location + charOffset, line.range.upperBound)
            }
    }
}
