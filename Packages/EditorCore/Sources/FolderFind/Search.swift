//
//  Search.swift
//  FolderFind
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-17.
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

public import Foundation
public import TextFind
import UniformTypeIdentifiers
import LineEnding
import StringUtils

/// A folder search configured with a compiled text find pattern.
public struct Search: Sendable {
    
    var rootURL: URL
    var pattern: TextFind.Pattern
    var options: FolderFind.Options
    var progress: FolderFindProgress?
    var isIncluded: (@Sendable (FolderFind.Candidate) -> Bool)?
    
    private var fileScopeMatcher: FileScope.Matcher?
    private var metrics: FolderFind.Metrics
    private var files: [FolderFind.FileResult] = []
    
    
    /// Initializes a folder find search.
    ///
    /// - Parameters:
    ///   - rootURL: The folder URL to search.
    ///   - pattern: The compiled text find pattern.
    ///   - options: The folder search options.
    ///   - progress: The progress object to update while searching.
    ///   - isIncluded: An additional predicate to include file candidates that the default file type check excludes.
    /// - Throws: `FileScope.Error` if the file scope is invalid.
    public init(rootURL: URL, pattern: TextFind.Pattern, options: FolderFind.Options = .init(), progress: FolderFindProgress? = nil, isIncluded: (@Sendable (FolderFind.Candidate) -> Bool)? = nil) throws(FileScope.Error) {
        
        self.rootURL = rootURL
        self.pattern = pattern
        self.options = options
        self.progress = progress
        self.isIncluded = isIncluded
        self.fileScopeMatcher = if let fileScope = options.fileScope {
            try FileScope.Matcher(fileScope)
        } else {
            nil
        }
        self.metrics = FolderFind.Metrics(findString: pattern.findString)
    }
    
    
    /// Runs the configured folder search.
    ///
    /// - Returns: The search summary.
    /// - Throws: `CancellationError` if the task is cancelled.
    public mutating func run() async throws(CancellationError) -> FolderFind.Summary {
        
        try await self.searchDirectory(at: self.rootURL)
        
        return FolderFind.Summary(metrics: self.metrics, files: self.files)
    }
    
    
    // MARK: Private Methods
    
    /// Searches a directory recursively.
    ///
    /// - Parameter directoryURL: The directory URL to search.
    /// - Throws: `CancellationError` if the task is cancelled.
    private mutating func searchDirectory(at directoryURL: URL) async throws(CancellationError) {
        
        guard !Task.isCancelled else { throw CancellationError() }
        
        await Task.yield()
        
        let enumerationOptions: FileManager.DirectoryEnumerationOptions = self.options.includesHiddenFiles ? [] : [.skipsHiddenFiles]
        guard let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: Array(FolderFind.Candidate.metadataResourceKeys), options: enumerationOptions) else { return }
        
        var candidates: [FolderFind.Candidate] = []
        for url in urls {
            guard !Task.isCancelled else { throw CancellationError() }
            
            guard
                !self.options.excludedNames.contains(url.lastPathComponent),
                let candidate = try? FolderFind.Candidate(at: url),
                !candidate.contentType.conforms(to: .resolvable),  // never follow aliases and symbolic links
                candidate.isDirectory || self.includes(candidate)
            else { continue }
            
            candidates.append(candidate)
        }
        
        candidates.sort { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                lhs.isDirectory
            } else {
                lhs.fileURL.lastPathComponent.localizedStandardCompare(rhs.fileURL.lastPathComponent) == .orderedAscending
            }
        }
        
        for candidate in candidates {
            guard !Task.isCancelled else { throw CancellationError() }
            
            if candidate.isDirectory {
                try await self.searchDirectory(at: candidate.fileURL)
            } else {
                try self.searchFile(candidate)
            }
        }
    }
    
    
    /// Searches a file.
    ///
    /// - Parameter candidate: The file candidate to search.
    /// - Throws: `CancellationError` if the task is cancelled.
    private mutating func searchFile(_ candidate: FolderFind.Candidate) throws(CancellationError) {
        
        guard
            candidate.fileSize <= self.options.maximumFileSize,
            (try? candidate.fileURL.isBinary) == false
        else { return }
        
        guard
            let string = try? String(contentsOf: candidate.fileURL, decodingOptions: self.options.decodingOptions)
        else { return }
        
        let textFind = TextFind(for: string, pattern: self.pattern)
        let matches = try self.matches(in: string, using: textFind)
        
        guard !matches.isEmpty else { return }
        
        self.recordSearchedFile(matchCount: matches.count)
        
        let rootPathComponents = self.rootURL.standardizedFileURL.pathComponents
        let directoryPathComponents = candidate.fileURL.deletingLastPathComponent().standardizedFileURL.pathComponents
        
        guard directoryPathComponents.starts(with: rootPathComponents) else { return assertionFailure() }
        
        self.files.append(FolderFind.FileResult(fileURL: candidate.fileURL,
                                                directoryPathComponents: Array(directoryPathComponents.dropFirst(rootPathComponents.count)),
                                                matches: matches))
    }
    
    
    /// Returns whether the candidate should be searched.
    ///
    /// - Parameter candidate: The file candidate to evaluate.
    /// - Returns: `true` if the candidate should be searched.
    private func includes(_ candidate: FolderFind.Candidate) -> Bool {
        
        let includesFileType = self.options.includesOtherFileTypes
            || FolderFind.isSearchableText(candidate)
            || self.isIncluded?(candidate) == true
        
        return includesFileType && (self.fileScopeMatcher?.contains(candidate, relativeTo: self.rootURL) ?? true)
    }
    
    
    /// Builds result matches in a string.
    ///
    /// - Parameters:
    ///   - string: The searched string.
    ///   - textFind: The text find instance.
    ///   - maximumLineLength: The preferred maximum UTF-16 length of each line fragment, extended to preserve whole grapheme clusters.
    /// - Returns: Matches for display.
    /// - Throws: `CancellationError` if the task is cancelled.
    private func matches(in string: String, using textFind: TextFind, maximumLineLength: Int = 512) throws(CancellationError) -> [FolderFind.Match] {
        
        assert(maximumLineLength > 0)
        
        let lineCounter = LineCounter(string: string)
        let nsString = string as NSString
        var matches: [FolderFind.Match] = []
        
        try textFind.findAll { ranges, _ in
            let range = ranges[0]
            let clampedLineRange = lineCounter.lineContentsRange(for: range)
                .clamped(around: range, maxLength: maximumLineLength)
            let lineRange = nsString.rangeOfComposedCharacterSequences(for: clampedLineRange)
            let line = nsString.substring(with: lineRange)
            let rangeInLine = NSRange(location: range.location - lineRange.location,
                                      length: min(range.upperBound, lineRange.upperBound) - range.location)
            
            matches.append(FolderFind.Match(range: range, line: line, rangeInLine: rangeInLine))
        }
        
        return matches
    }
    
    
    /// Records a searched file.
    ///
    /// - Parameter matchCount: The number of matches found in the file.
    private mutating func recordSearchedFile(matchCount: Int) {
        
        assert(matchCount > 0)
        
        self.metrics.matchCount += matchCount
        self.metrics.matchedFileCount += 1
        
        self.progress?.update(snapshot: self.metrics)
    }
}
