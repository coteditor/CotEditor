//
//  FolderTextSearch.swift
//  TextFind
//
//  CotEditor
//  https://coteditor.com
//
//  ---------------------------------------------------------------------------
//
//  © 2026 sdraeger
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
import FileEncoding
import StringUtils
import UniformTypeIdentifiers

public enum FolderTextSearch {
    
    public struct Options: Equatable, Sendable {
        
        public static let defaultEncodingCandidates: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .utf32,
            .utf32LittleEndian,
            .utf32BigEndian,
            .isoLatin1,
            .windowsCP1252,
            .shiftJIS,
        ]
        
        public var includesHiddenFiles: Bool
        public var followsPackageDirectories: Bool
        public var maximumFileSize: Int
        public var maximumLineLength: Int
        public var allowedFilenameExtensions: Set<String>?
        public var excludedDirectoryNames: Set<String>
        public var encodingCandidates: [String.Encoding]
        
        
        public init(includesHiddenFiles: Bool = false,
                    followsPackageDirectories: Bool = false,
                    maximumFileSize: Int = 10 * 1024 * 1024,
                    maximumLineLength: Int = 1024,
                    allowedFilenameExtensions: Set<String>? = nil,
                    excludedDirectoryNames: Set<String> = [".git", ".hg", ".svn"],
                    encodingCandidates: [String.Encoding] = Self.defaultEncodingCandidates)
        {
            self.includesHiddenFiles = includesHiddenFiles
            self.followsPackageDirectories = followsPackageDirectories
            self.maximumFileSize = maximumFileSize
            self.maximumLineLength = maximumLineLength
            self.allowedFilenameExtensions = allowedFilenameExtensions.map {
                Set($0.map(Self.normalizedPathExtension))
            }
            self.excludedDirectoryNames = excludedDirectoryNames
            self.encodingCandidates = encodingCandidates
        }
        
        
        fileprivate static func normalizedPathExtension(_ pathExtension: String) -> String {
            
            pathExtension.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()
        }
    }
    
    
    public struct Match: Equatable, Identifiable, Sendable {
        
        public struct ID: Hashable, Sendable {
            
            public var filePath: String
            public var location: Int
            public var length: Int
        }
        
        
        public var fileURL: URL
        public var range: NSRange
        public var lineNumber: Int
        public var lineFragmentRange: NSRange
        public var inlineLocation: Int
        public var lineString: String
        
        
        public var id: ID {
            
            ID(filePath: self.fileURL.standardizedFileURL.path,
               location: self.range.location,
               length: self.range.length)
        }
        
        
        public init(fileURL: URL, range: NSRange, lineNumber: Int, lineFragmentRange: NSRange, inlineLocation: Int, lineString: String) {
            
            self.fileURL = fileURL
            self.range = range
            self.lineNumber = lineNumber
            self.lineFragmentRange = lineFragmentRange
            self.inlineLocation = inlineLocation
            self.lineString = lineString
        }
    }
    
    
    // MARK: Public Methods
    
    public static func matches(in rootURL: URL,
                               findString: String,
                               mode: TextFind.Mode,
                               options: Options = Options()) async throws -> [Match]
    {
        try await Task.detached(priority: .userInitiated) {
            try Self.search(rootURL: rootURL, findString: findString, mode: mode, options: options)
        }.value
    }
    
    
    // MARK: Private Methods
    
    private static let resourceKeys: [URLResourceKey] = [
        .contentTypeKey,
        .fileSizeKey,
        .isDirectoryKey,
        .isHiddenKey,
        .isPackageKey,
        .isRegularFileKey,
    ]
    
    
    private static func search(rootURL: URL, findString: String, mode: TextFind.Mode, options: Options) throws -> [Match] {
        
        _ = try TextFind(for: "", findString: findString, mode: mode)
        
        let fileURLs = try Self.fileURLs(in: rootURL, options: options)
        var matches: [Match] = []
        
        for fileURL in fileURLs {
            try Task.checkCancellation()
            guard let string = Self.string(at: fileURL, options: options) else { continue }
            
            let textFind = try TextFind(for: string, findString: findString, mode: mode)
            var isCancelled = false
            textFind.findAll { ranges, stop in
                guard let matchedRange = ranges.first else { return }
                
                if Task.isCancelled {
                    isCancelled = true
                    stop = true
                    return
                }
                
                matches.append(Self.match(fileURL: fileURL, string: string, range: matchedRange, options: options))
            }
            
            if isCancelled {
                throw CancellationError()
            }
        }
        
        return matches.sorted { lhs, rhs in
            let lhsPath = lhs.fileURL.standardizedFileURL.path
            let rhsPath = rhs.fileURL.standardizedFileURL.path
            if lhsPath != rhsPath {
                return lhsPath.localizedStandardCompare(rhsPath) == .orderedAscending
            }
            return lhs.range.location < rhs.range.location
        }
    }
    
    
    private static func fileURLs(in rootURL: URL, options: Options) throws -> [URL] {
        
        let rootURL = rootURL.standardizedFileURL
        let rootResourceValues = try rootURL.resourceValues(forKeys: Set(Self.resourceKeys))
        
        guard rootResourceValues.isDirectory == true else {
            return Self.acceptsFile(rootURL, values: rootResourceValues, options: options) ? [rootURL] : []
        }
        
        let enumerationOptions: FileManager.DirectoryEnumerationOptions = options.includesHiddenFiles ? [] : [.skipsHiddenFiles]
        guard let enumerator = FileManager.default.enumerator(at: rootURL,
                                                              includingPropertiesForKeys: Self.resourceKeys,
                                                              options: enumerationOptions,
                                                              errorHandler: { _, _ in true })
        else { return [] }
        
        var fileURLs: [URL] = []
        for case let fileURL as URL in enumerator {
            try Task.checkCancellation()
            
            let resourceValues = try fileURL.resourceValues(forKeys: Set(Self.resourceKeys))
            if resourceValues.isDirectory == true {
                if Self.skipsDirectory(fileURL, values: resourceValues, options: options) {
                    enumerator.skipDescendants()
                }
                continue
            }
            
            if Self.acceptsFile(fileURL, values: resourceValues, options: options) {
                fileURLs.append(fileURL)
            }
        }
        
        return fileURLs
    }
    
    
    private static func skipsDirectory(_ fileURL: URL, values: URLResourceValues, options: Options) -> Bool {
        
        if options.excludedDirectoryNames.contains(fileURL.lastPathComponent) {
            return true
        }
        if !options.followsPackageDirectories, values.isPackage == true {
            return true
        }
        
        return false
    }
    
    
    private static func acceptsFile(_ fileURL: URL, values: URLResourceValues, options: Options) -> Bool {
        
        if !options.includesHiddenFiles, values.isHidden == true {
            return false
        }
        if values.isRegularFile != true {
            return false
        }
        if let fileSize = values.fileSize, fileSize > options.maximumFileSize {
            return false
        }
        if let allowedFilenameExtensions = options.allowedFilenameExtensions,
           !allowedFilenameExtensions.contains(Options.normalizedPathExtension(fileURL.pathExtension))
        {
            return false
        }
        if let contentType = values.contentType,
           [.archive, .audio, .image, .movie].contains(where: contentType.conforms(to:))
        {
            return false
        }
        
        return true
    }
    
    
    private static func string(at fileURL: URL, options: Options) -> String? {
        
        guard let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe),
              data.count <= options.maximumFileSize,
              !Self.mayBeBinary(data)
        else { return nil }
        
        let decodingOptions = String.DetectionOptions(candidates: options.encodingCandidates,
                                                      considersDeclaration: true)
        
        return try? String.string(data: data, decodingStrategy: .automatic(decodingOptions)).0
    }
    
    
    private static func mayBeBinary(_ data: Data) -> Bool {
        
        data.prefix(4096).contains(0)
    }
    
    
    private static func match(fileURL: URL, string: String, range: NSRange, options: Options) -> Match {
        
        let nsString = string as NSString
        let lineContentsRange = nsString.lineContentsRange(for: range)
        let lineFragmentRange = lineContentsRange.clamped(around: range, maxLength: max(options.maximumLineLength, 1))
        let lineString = nsString.substring(with: lineFragmentRange)
        let lineNumber = string.lineNumber(at: range.location)
        let inlineLocation = range.location - lineFragmentRange.location
        
        return Match(fileURL: fileURL,
                     range: range,
                     lineNumber: lineNumber,
                     lineFragmentRange: lineFragmentRange,
                     inlineLocation: inlineLocation,
                     lineString: lineString)
    }
}
