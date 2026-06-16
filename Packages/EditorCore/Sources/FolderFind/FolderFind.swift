//
//  FolderFind.swift
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
public import FileEncoding
public import TextFind
public import UniformTypeIdentifiers

public enum FolderFind {
    
    public struct Query: Equatable, Sendable {
        
        public var findString: String
        public var mode: TextFind.Mode
        
        
        /// Initializes a folder find query.
        ///
        /// - Parameters:
        ///   - findString: The string to search for.
        ///   - mode: The find mode.
        public init(findString: String, mode: TextFind.Mode) {
            
            self.findString = findString
            self.mode = mode
        }
        
        
        /// Validates the query.
        ///
        /// - Throws: `TextFind.Error` if the query is invalid.
        public func validate() throws(TextFind.Error) {
            
            _ = try TextFind(for: "", findString: self.findString, mode: self.mode)
        }
    }
    
    
    public struct Options: Sendable {
        
        public var includesOtherFileTypes: Bool
        public var includesHiddenFiles: Bool
        public var excludedNames: Set<String>
        public var fileScope: FileScope
        public var decodingOptions: String.DetectionOptions
        
        
        /// Initializes folder find options.
        ///
        /// - Parameters:
        ///   - includesOtherFileTypes: Whether files that do not look like plain text should also be searched.
        ///   - includesHiddenFiles: Whether hidden files should be included.
        ///   - excludedNames: File or folder names to exclude from traversal.
        ///   - fileScope: The file scope to search.
        ///   - decodingOptions: The text decoding options to use for reading files.
        public init(
            includesOtherFileTypes: Bool = false,
            includesHiddenFiles: Bool = false,
            excludedNames: Set<String> = [".DS_Store", ".git"],
            fileScope: FileScope = .init(),
            decodingOptions: String.DetectionOptions = .init(candidates: [.utf8])
        ) {
            
            self.includesOtherFileTypes = includesOtherFileTypes
            self.includesHiddenFiles = includesHiddenFiles
            self.excludedNames = excludedNames
            self.fileScope = fileScope
            self.decodingOptions = decodingOptions
        }
    }
    
    
    public struct Candidate: Equatable, Sendable {
        
        public var fileURL: URL
        public var contentType: UTType
        public var isDirectory: Bool
        public var isHidden: Bool
        
        static let metadataResourceKeys: Set<URLResourceKey> = [.contentTypeKey, .isDirectoryKey, .isHiddenKey]
        
        
        /// Initializes by reading a candidate at the given URL.
        ///
        /// - Parameter url: The URL to read.
        /// - Throws: An error if file metadata cannot be read.
        init(at url: URL) throws {
            
            let resourceValues = try url.resourceValues(forKeys: Self.metadataResourceKeys)
            
            self.fileURL = url.standardizedFileURL
            self.contentType = resourceValues.contentType ?? .data
            self.isDirectory = resourceValues.isDirectory ?? false
            self.isHidden = resourceValues.isHidden ?? false
        }
    }
    
    
    public struct Metrics: Equatable, Sendable {
        
        public var findString: String
        public var matchCount: Int = 0
        public var matchedFileCount: Int = 0
        public var searchedFileCount: Int = 0
        public var skippedFileCount: Int = 0
    }
    
    
    public struct Summary: Equatable, Sendable {
        
        public var metrics: Metrics
        public var files: [FileResult]  { didSet { self.updateMatchCounts() } }
        
        /// Initializes a folder find summary.
        ///
        /// - Parameters:
        ///   - metrics: The result metrics.
        ///   - files: The file results.
        init(metrics: Metrics, files: [FileResult]) {
            
            self.metrics = metrics
            self.files = files
            
            self.updateMatchCounts()
        }
        
        
        /// Updates the match-related metrics from the current files.
        private mutating func updateMatchCounts() {
            
            self.metrics.matchCount = self.files.map(\.matches.count).reduce(0, +)
            self.metrics.matchedFileCount = self.files.count
        }
    }
    
    
    public struct FileResult: Equatable, Identifiable, Sendable {
        
        public var fileURL: URL
        public var directoryPathComponents: [String]
        public var matches: [Match]
        
        /// The stable identity of the file result.
        public var id: URL  { self.fileURL }
        
        /// The filename.
        public var filename: String  { self.fileURL.lastPathComponent }
    }
    
    
    public struct Match: Equatable, Identifiable, Sendable {
        
        public var id = UUID()
        public var range: NSRange
        public var line: String
        public var rangeInLine: NSRange
    }
    
    
    /// The identity of a row in search results.
    public enum ResultID: Hashable, Sendable {
        
        case file(FileResult.ID)
        case match(fileID: FileResult.ID, matchID: Match.ID)
    }
    
    
    /// A resolved search result row.
    public struct Result: Equatable, Sendable {
        
        public var file: FileResult
        public var match: Match?
    }
    
    
    /// Finds text in files in a folder.
    ///
    /// - Parameters:
    ///   - rootURL: The folder URL to search.
    ///   - query: The search query.
    ///   - options: The folder search options.
    ///   - progress: The progress object to update while searching.
    ///   - isIncluded: The predicate to determine whether a file candidate should be searched. If `nil`, the file type option is used.
    /// - Returns: The search summary.
    /// - Throws: `TextFind.Error` for invalid queries, `FileScope.Error` for invalid file scopes, or `CancellationError` if the task is cancelled.
    public static func find(in rootURL: URL, query: Query, options: Options = .init(), progress: FolderFindProgress? = nil, isIncluded: (@Sendable (Candidate) -> Bool)? = nil) async throws -> Summary {
        
        // validate search conditions before traversing the folder
        try query.validate()
        
        var search = try Search(rootURL: rootURL, query: query, options: options, progress: progress, isIncluded: isIncluded)
        return try await search.run()
    }
    
    
    /// Returns whether the given file candidate is searchable as text by default.
    ///
    /// - Parameter candidate: The file candidate to evaluate.
    /// - Returns: `true` if the candidate should be searched.
    public static func isSearchableText(_ candidate: Candidate) -> Bool {
        
        guard !candidate.isDirectory else { return false }
        
        if candidate.contentType.conforms(to: .text) { return true }
        if candidate.contentType.conforms(to: .resolvable) { return false }
        if candidate.contentType.conforms(to: .propertyList) { return true }
        
        return candidate.fileURL.pathExtension.isEmpty
    }
}


public extension FolderFind.Summary {
    
    /// Returns the search result for the given ID.
    ///
    /// - Parameter id: The result ID to resolve.
    /// - Returns: The resolved search result, or `nil` if not found.
    func result(for id: FolderFind.ResultID) -> FolderFind.Result? {
        
        switch id {
            case .file(let fileID):
                guard let file = self.files.first(where: { $0.id == fileID }) else { return nil }
                
                return FolderFind.Result(file: file, match: nil)
                
            case .match(let fileID, let matchID):
                guard
                    let file = self.files.first(where: { $0.id == fileID }),
                    let match = file.matches.first(where: { $0.id == matchID })
                else { return nil }
                
                return FolderFind.Result(file: file, match: match)
        }
    }
    
    
    /// Removes the search result for the given ID.
    ///
    /// - Parameter id: The result ID to remove.
    mutating func removeResult(for id: FolderFind.ResultID) {
        
        switch id {
            case .file(let fileID):
                self.files.removeAll { $0.id == fileID }
                
            case .match(let fileID, let matchID):
                guard let fileIndex = self.files.firstIndex(where: { $0.id == fileID }) else { return }
                
                self.files[fileIndex].matches.removeAll { $0.id == matchID }
                
                if self.files[fileIndex].matches.isEmpty {
                    self.files.remove(at: fileIndex)
                }
        }
    }
    
    
    /// Updates match ranges in the file after text editing.
    ///
    /// This method updates only the ranges used to reveal matches. The display line snapshots are intentionally kept unchanged.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the edited file.
    ///   - editedRange: The range edited in the current text.
    ///   - changeInLength: The length delta from the text edit.
    ///   - length: The current text length after editing.
    /// - Returns: `true` if at least one match range was updated.
    @discardableResult mutating func updateMatchRanges(in fileURL: URL, editedRange: NSRange, changeInLength: Int, length: Int) -> Bool {
        
        guard let fileIndex = self.files.firstIndex(where: { $0.fileURL == fileURL }) else { return false }
        
        var didUpdate = false
        for matchIndex in self.files[fileIndex].matches.indices {
            didUpdate = self.files[fileIndex]
                .matches[matchIndex]
                .updateRange(editedRange: editedRange, changeInLength: changeInLength, length: length) || didUpdate
        }
        
        return didUpdate
    }
}


private extension FolderFind.Match {
    
    /// Updates the match range after text editing.
    ///
    /// - Parameters:
    ///   - editedRange: The range edited in the current text.
    ///   - changeInLength: The length delta from the text edit.
    ///   - length: The current text length after editing.
    /// - Returns: `true` if the range was updated.
    mutating func updateRange(editedRange: NSRange, changeInLength: Int, length: Int) -> Bool {
        
        let oldRange = self.range
        let oldEditedLength = max(editedRange.length - changeInLength, 0)
        let oldEditedRange = NSRange(location: editedRange.location, length: oldEditedLength)
        let newLowerBound = Self.updatedLowerBound(of: self.range, oldEditedRange: oldEditedRange,
                                                   editedRange: editedRange, changeInLength: changeInLength)
        let newUpperBound = Self.updatedUpperBound(of: self.range, oldEditedRange: oldEditedRange,
                                                   editedRange: editedRange, changeInLength: changeInLength)
        let lowerBound = min(max(newLowerBound, 0), length)
        let upperBound = min(max(newUpperBound, lowerBound), length)
        
        self.range = NSRange(lowerBound..<upperBound)
        
        return self.range != oldRange
    }
    
    
    /// Returns the updated lower bound after text editing.
    ///
    /// - Parameters:
    ///   - range: The range to update.
    ///   - oldEditedRange: The edited range in the previous text.
    ///   - editedRange: The edited range in the current text.
    ///   - changeInLength: The length delta from the text edit.
    /// - Returns: The updated lower bound.
    private static func updatedLowerBound(of range: NSRange, oldEditedRange: NSRange, editedRange: NSRange, changeInLength: Int) -> Int {
        
        switch range.lowerBound {
            case ..<oldEditedRange.lowerBound:
                range.location
            case oldEditedRange.upperBound:
                editedRange.upperBound
            case oldEditedRange.upperBound...:
                range.location + changeInLength
            default:
                editedRange.location
        }
    }
    
    
    /// Returns the updated upper bound after text editing.
    ///
    /// - Parameters:
    ///   - range: The range to update.
    ///   - oldEditedRange: The edited range in the previous text.
    ///   - editedRange: The edited range in the current text.
    ///   - changeInLength: The length delta from the text edit.
    /// - Returns: The updated upper bound.
    private static func updatedUpperBound(of range: NSRange, oldEditedRange: NSRange, editedRange: NSRange, changeInLength: Int) -> Int {
        
        switch range.upperBound {
            case ..<oldEditedRange.location:
                range.upperBound
            case oldEditedRange.lowerBound:
                editedRange.location
            case oldEditedRange.upperBound...:
                range.upperBound + changeInLength
            default:
                editedRange.upperBound
        }
    }
}
