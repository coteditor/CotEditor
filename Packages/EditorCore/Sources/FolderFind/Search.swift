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

import Foundation
import UniformTypeIdentifiers
import LineEnding
import StringUtils
import TextFind

struct Search {
    
    var rootURL: URL
    var query: FolderFind.Query
    var options: FolderFind.Options
    var isIncluded: @Sendable (FolderFind.Candidate) -> Bool
    
    var files: [FolderFind.FileResult] = []
    var searchedFileCount = 0
    var skippedFileCount = 0
    
    
    /// Runs the folder search.
    ///
    /// - Returns: The search summary.
    /// - Throws: `CancellationError` if the task is cancelled.
    mutating func run() async throws -> FolderFind.Summary {
        
        try await self.searchDirectory(at: self.rootURL)
        
        return FolderFind.Summary(files: self.files,
                                  searchedFileCount: self.searchedFileCount,
                                  skippedFileCount: self.skippedFileCount)
    }
    
    
    // MARK: Private Methods
    
    /// Searches a directory recursively.
    ///
    /// - Parameter directoryURL: The directory URL to search.
    /// - Throws: `CancellationError` if the task is cancelled.
    private mutating func searchDirectory(at directoryURL: URL) async throws {
        
        try Task.checkCancellation()
        await Task.yield()
        
        guard let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: Array(FolderFind.Candidate.metadataResourceKeys)) else { return }
        
        var candidates: [FolderFind.Candidate] = []
        for url in urls {
            do {
                let candidate = try FolderFind.Candidate(at: url)
                candidates.append(candidate)
            } catch {
                self.skippedFileCount += 1
            }
        }
        candidates.sort { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                lhs.isDirectory && !rhs.isDirectory
            } else {
                lhs.fileURL.lastPathComponent.localizedStandardCompare(rhs.fileURL.lastPathComponent) == .orderedAscending
            }
        }
        
        for candidate in candidates {
            try Task.checkCancellation()
            
            guard
                !self.options.excludedNames.contains(candidate.fileURL.lastPathComponent),
                self.options.includesHiddenItems || !candidate.isHidden
            else { continue }
            
            if candidate.isDirectory {
                try await self.searchDirectory(at: candidate.fileURL)
            } else if self.isIncluded(candidate) {
                try self.searchFile(candidate)
            }
        }
    }
    
    
    /// Searches a file.
    ///
    /// - Parameter candidate: The file candidate to search.
    /// - Throws: `CancellationError` if the task is cancelled.
    private mutating func searchFile(_ candidate: FolderFind.Candidate) throws {
        
        guard !candidate.contentType.conforms(to: .propertyList) || !Self.isBinaryPropertyList(at: candidate.fileURL) else {
            self.skippedFileCount += 1
            return
        }
        
        let string: String
        do {
            string = try String(contentsOf: candidate.fileURL, decodingOptions: self.options.decodingOptions)
        } catch {
            self.skippedFileCount += 1
            return
        }
        
        self.searchedFileCount += 1
        
        let textFind: TextFind
        do {
            textFind = try TextFind(for: string, findString: self.query.findString, mode: self.query.mode)
        } catch {
            assertionFailure("The query should have been already validated.")
            return
        }
        
        let matches = try self.matches(in: string, using: textFind)
        
        guard !matches.isEmpty else { return }
        
        let rootPathComponents = self.rootURL.standardizedFileURL.pathComponents
        let directoryPathComponents = candidate.fileURL.deletingLastPathComponent().standardizedFileURL.pathComponents
        
        guard directoryPathComponents.starts(with: rootPathComponents) else { return assertionFailure() }
        
        self.files.append(FolderFind.FileResult(fileURL: candidate.fileURL,
                                                filename: candidate.fileURL.lastPathComponent,
                                                directoryPathComponents: Array(directoryPathComponents.dropFirst(rootPathComponents.count)),
                                                matches: matches))
    }
    
    
    /// Builds result matches in a string.
    ///
    /// - Parameters:
    ///   - string: The searched string.
    ///   - textFind: The text find instance.
    /// - Returns: Matches for display.
    /// - Throws: `CancellationError` if the task is cancelled.
    private func matches(in string: String, using textFind: TextFind) throws -> [FolderFind.Match] {
        
        let lineCounter = LineCounter(string: string)
        let nsString = string as NSString
        var matches: [FolderFind.Match] = []
        
        textFind.findAll { ranges, stop in
            guard !Task.isCancelled else {
                stop = true
                return
            }
            
            let range = ranges[0]
            let lineRange = lineCounter.lineContentsRange(for: range)
                .clamped(around: range, maxLength: self.options.maximumLineLength)
            let line = nsString.substring(with: lineRange)
            let rangeInLine = range.shifted(by: -lineRange.location)
            
            matches.append(FolderFind.Match(range: range, line: line, rangeInLine: rangeInLine))
        }
        try Task.checkCancellation()
        
        return matches
    }
    
    
    /// Returns whether the given property list file is binary.
    ///
    /// - Parameter url: The file URL to inspect.
    /// - Returns: `true` if the property list is binary.
    private static func isBinaryPropertyList(at url: URL) -> Bool {
        
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return false }
        
        return data.starts(with: Data("bplist".utf8))
    }
}
