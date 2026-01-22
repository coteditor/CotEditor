//
//  Syntax+FileWrapper.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 2025 on 2026-01-01.
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

/// Support for reading and writing `Syntax` as a package.
///
/// Package file structure:
///
/// ```
/// Swift.cotsyntax/
/// ├─ Info.json
/// ├─ Edit.json
/// └─ Regex/
///     ├─ Highlights.json
///     └─ Outlines.json
/// ```
extension Syntax {
    
    struct Info: Equatable, Sendable, Codable {
        
        var kind: Kind?
        var fileMap: FileMap?
        var metadata: Metadata?
    }
    
    
    struct Edit: Equatable, Sendable, Codable {
        
        var comment: Comment?
        var completions: [String]?
    }
    
    
    private enum Filename {
        
        static let info = "Info.json"
        static let edit = "Edit.json"
        
        static let regex = "Regex"
        static let highlights = "Highlights.json"
        static let outlines = "Outlines.json"
    }
    
    
    /// Creates a `Syntax` by decoding a package `FileWrapper`.
    ///
    /// - Parameters:
    ///   - fileWrapper: The root directory wrapper of a `.cotsyntax` package.
    /// - Throws: `CocoaError(.fileReadCorruptFile)` if required files are missing or JSON decoding fails.
    public init(fileWrapper: FileWrapper) throws {
        
        guard let infoData = fileWrapper.fileWrappers?[Filename.info]?.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let decoder = JSONDecoder()
        
        let info = try decoder.decode(Info.self, from: infoData)
        self.kind = info.kind ?? .general
        self.fileMap = info.fileMap ?? .init()
        self.metadata = info.metadata ?? .init()
        
        guard let editData = fileWrapper.fileWrappers?[Filename.edit]?.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let edit = try decoder.decode(Edit.self, from: editData)
        self.commentDelimiters = edit.comment ?? .init()
        self.completions = edit.completions ?? []
        
        // load regex-based definition
        if let wrapper = fileWrapper.fileWrappers?[Filename.regex] {
            self.highlights = if let data = wrapper.fileWrappers?[Filename.highlights]?.regularFileContents {
                try decoder.decode([SyntaxType: [Highlight]].self, from: data)
            } else {
                [:]
            }
            
            self.outlines = if let data = wrapper.fileWrappers?[Filename.outlines]?.regularFileContents {
                try decoder.decode([Outline].self, from: data)
            } else {
                []
            }
        } else {
            self.highlights = [:]
            self.outlines = []
        }
    }
    
    
    /// Serializes the receiver into a package `FileWrapper` representing a `.cotsyntax` package.
    public var fileWrapper: FileWrapper {
        
        get throws {
            let fileWrapper = FileWrapper(directoryWithFileWrappers: [:])
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            
            let info = Info(kind: self.kind, fileMap: self.fileMap, metadata: self.metadata)
            let infoData = try encoder.encode(info)
            fileWrapper.addRegularFile(withContents: infoData, preferredFilename: Filename.info)
            
            let edit = Edit(comment: self.commentDelimiters,
                            completions: self.completions.isEmpty ? nil : self.completions)
            let editData = try encoder.encode(edit)
            fileWrapper.addRegularFile(withContents: editData, preferredFilename: Filename.edit)
            
            if !self.highlights.flatMap(\.value).isEmpty || !self.outlines.isEmpty {
                let regexWrapper = FileWrapper(directoryWithFileWrappers: [:])
                regexWrapper.preferredFilename = Filename.regex
                
                if !self.highlights.flatMap(\.value).isEmpty {
                    let data = try encoder.encode(self.highlights)
                    regexWrapper.addRegularFile(withContents: data, preferredFilename: Filename.highlights)
                }
                if !self.outlines.isEmpty {
                    let data = try encoder.encode(self.outlines)
                    regexWrapper.addRegularFile(withContents: data, preferredFilename: Filename.outlines)
                }
                fileWrapper.addFileWrapper(regexWrapper)
            }
            
            return fileWrapper
        }
    }
}


public extension Syntax.FileMap {
    
    struct InvalidError: Error {
        
        var filename: String
        var underlyingError: any Error
    }
    
    
    /// Creates a `Syntax.FileMap` by reading a `.cotsyntax` package on disk.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL pointing to the root directory of a .cotsynta package.
    /// - Throws: A `CocoaError` or decoding error if the file cannot be read or the JSON is invalid.
    init?(contentsOf fileURL: URL) throws {
        
        let url = fileURL.appending(component: Syntax.Filename.info)
        let data = try Data(contentsOf: url)
        let info = try JSONDecoder().decode(Syntax.Info.self, from: data)
        
        guard let fileMap = info.fileMap else { return nil }
        
        self = fileMap
    }
    
    
    /// Loads Syntax.FileMap of the given files.
    ///
    /// - Parameters:
    ///   - urls: File URLs of CotEditor's syntax definition files to load.
    ///   - ignoresInvalidData: If `true`, just ignores invalid files and continues scanning, otherwise throws an `InvalidError`.
    /// - Returns: Valid Syntax.FileMaps.
    static func load(at urls: [URL], ignoresInvalidData: Bool = false) throws -> [String: Syntax.FileMap] {
        
        try urls.reduce(into: [:]) { maps, url in
            let map: Syntax.FileMap
            do {
                map = try Syntax.FileMap(contentsOf: url) ?? .init()
            } catch {
                if ignoresInvalidData {
                    return
                } else {
                    throw InvalidError(filename: url.lastPathComponent, underlyingError: error)
                }
            }
            
            let syntaxName = url.deletingPathExtension().lastPathComponent
            maps[syntaxName] = map
        }
    }
}
