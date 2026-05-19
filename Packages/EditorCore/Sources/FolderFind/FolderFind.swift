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
import DocumentFile

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
        
        public var includesHiddenItems: Bool
        public var excludedNames: Set<String>
        public var maximumLineLength: Int
        public var decodingOptions: String.DetectionOptions
        
        
        /// Initializes folder find options.
        ///
        /// - Parameters:
        ///   - includesHiddenItems: Whether hidden files and folders should be included.
        ///   - excludedNames: File or folder names to exclude from traversal.
        ///   - maximumLineLength: The maximum UTF-16 length of each line fragment in results.
        ///   - decodingOptions: The text decoding options to use for reading files.
        public init(
            includesHiddenItems: Bool = false,
            excludedNames: Set<String> = [".DS_Store", ".git"],
            maximumLineLength: Int = 1024,
            decodingOptions: String.DetectionOptions = .init(candidates: [.utf8], considersDeclaration: true)
        ) {
            assert(maximumLineLength > 0)
            
            self.includesHiddenItems = includesHiddenItems
            self.excludedNames = excludedNames
            self.maximumLineLength = maximumLineLength
            self.decodingOptions = decodingOptions
        }
    }
    
    
    public struct Candidate: Equatable, Sendable {
        
        public var fileURL: URL
        public var contentType: UTType
        public var isDirectory: Bool
        public var isHidden: Bool
        public var isAlias: Bool
        
        static let metadataResourceKeys = File.metadataResourceKeys
        
        
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
            self.isAlias = resourceValues.isAliasFile ?? false
        }
    }
    
    
    public struct Summary: Equatable, Sendable {
        
        public var findString: String
        public var files: [FileResult]
        public var searchedFileCount: Int
        public var skippedFileCount: Int
        
        /// The number of files that contain matches.
        public var matchedFileCount: Int  { self.files.count }
        
        
        /// The number of matches found in all files.
        public var matchCount: Int {
            
            self.files.map(\.matches.count).reduce(0, +)
        }
    }
    
    
    public struct FileResult: Equatable, Identifiable, Sendable {
        
        public var fileURL: URL
        public var filename: String
        public var directoryPathComponents: [String]
        public var matches: [Match]
        
        /// The stable identity of the file result.
        public var id: URL  { self.fileURL }
    }
    
    
    public struct Match: Equatable, Identifiable, Sendable {
        
        public var range: NSRange
        public var line: String
        public var rangeInLine: NSRange
        
        /// The stable identity of the match in a file result.
        public var id: NSRange  { self.range }
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
    ///   - isIncluded: The predicate to determine whether a file candidate should be searched.
    /// - Returns: The search summary.
    /// - Throws: `TextFind.Error` for invalid queries, or `CancellationError` if the task is cancelled.
    public static func find(in rootURL: URL, query: Query, options: Options = .init(), isIncluded: @escaping @Sendable (Candidate) -> Bool = Self.isSearchableText) async throws -> Summary {
        
        // validate the query before traversing the folder
        try query.validate()
        
        var search = Search(rootURL: rootURL, query: query, options: options, isIncluded: isIncluded)
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
}
