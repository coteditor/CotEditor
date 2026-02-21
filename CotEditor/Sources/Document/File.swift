//
//  File.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 2025 on 2025-10-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2025 1024jp
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
import URLUtils

struct File: Equatable {
    
    enum Kind {
        
        case folder
        case general
        case archive
        case image
        case movie
        case audio
    }
    
    
    nonisolated static let resourceValues: Set<URLResourceKey> = [.isDirectoryKey, .isHiddenKey, .isWritableKey, .isAliasFileKey, .contentTypeKey]
    
    var name: String
    var fileURL: URL
    let isDirectory: Bool
    var isHidden: Bool
    var isWritable: Bool
    var isAlias: Bool
    var kind: Kind
    var tags: [FinderTag]
    
    
    /// Initializes a file instance with basic information.
    ///
    /// This initializer creates a file node given a URL and directory flag, without reading from disk.
    /// It is designed to add a new node upon a user request.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL for the node.
    ///   - isDirectory: Whether the node represents a directory.
    init(at fileURL: URL, isDirectory: Bool) {
        
        self.name = fileURL.lastPathComponent
        self.fileURL = fileURL.standardizedFileURL
        self.isDirectory = isDirectory
        self.isHidden = fileURL.lastPathComponent.starts(with: ".")
        self.isWritable = true
        self.isAlias = false
        self.kind = Kind(pathExtension: fileURL.pathExtension, isDirectory: isDirectory)
        self.tags = []
    }
    
    
    /// Initializes a file instance by reading metadata from disk.
    ///
    /// This initializer loads and inspects the file or directory at the given URL, reading resource values and tags.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL for the node.
    /// - Throws: An error if the file's resource values cannot be loaded.
    init(at fileURL: URL) throws {
        
        let resourceValues = try fileURL.resourceValues(forKeys: Self.resourceValues)
        
        self.name = fileURL.lastPathComponent
        self.fileURL = fileURL.standardizedFileURL
        self.isDirectory = resourceValues.isDirectory ?? false
        self.isHidden = resourceValues.isHidden ?? false
        self.isWritable = resourceValues.isWritable ?? true
        self.isAlias = resourceValues.isAliasFile ?? false
        
        self.kind = if self.isAlias, (try? URL(resolvingAliasFileAt: fileURL).isDirectory) == true {
            .folder
        } else {
            Kind(type: resourceValues.contentType, isDirectory: self.isDirectory)
        }
        
        self.tags = (try? fileURL.extendedAttribute(for: FileExtendedAttributeName.userTags))
            .map(FinderTag.tags(data:)) ?? []
    }
    
    
    /// Whether the receiver's `kind` is `.folder`.
    ///
    /// Unlike `.isDirectory` property, this property also returns `true` when the receiver is an alias linking to a folder.
    var isFolder: Bool {
        
        self.kind == .folder
    }
    
    
    /// Updates `.kind` with current filename.
    mutating func invalidateKind() {
        
        guard !(self.isAlias && self.kind == .folder) else { return }
        
        self.kind = Kind(pathExtension: self.fileURL.pathExtension, isDirectory: self.isDirectory)
    }
    
    
    /// Updates resource values by reading the file.
    ///
    /// - Returns: Whether the related file resources actually changed.
    @discardableResult mutating func invalidateResources() throws -> Bool {
        
        let resourceValues = try self.fileURL.resourceValues(forKeys: [.isHiddenKey, .isAliasFileKey, .isWritableKey])
        
        let isHidden = resourceValues.isHidden ?? false
        let isWritable = resourceValues.isWritable ?? true
        let tags = (try? self.fileURL.extendedAttribute(for: FileExtendedAttributeName.userTags))
            .map(FinderTag.tags(data:)) ?? []
        
        var didChange = false
        
        if self.isHidden != isHidden {
            self.isHidden = isHidden
            didChange = true
        }
        if self.isWritable != isWritable {
            self.isWritable = isWritable
            didChange = true
        }
        if self.tags != tags {
            self.tags = tags
            didChange = true
        }
        
        return didChange
    }
}


// MARK: File.Kind

extension File.Kind {
    
    init(pathExtension: String, isDirectory: Bool) {
        
        if isDirectory {
            self = .folder
            return
        }
        
        self.init(type: UTType(filenameExtension: pathExtension), isDirectory: isDirectory)
    }
    
    
    init(type: UTType?, isDirectory: Bool) {
        
        if isDirectory {
            self = .folder
            return
        }
        
        guard let type else {
            self = .general
            return
        }
        
        if type.conforms(to: .plainText) || type.conforms(to: .xml) {
            self = .general
        } else if type.conforms(to: .image) {
            self = .image
        } else if type.conforms(to: .movie), type != .mpeg2TransportStream {  // .ts (possibly a TypeScript file) extension can be mapped to MPEG-2 transport stream.
            self = .movie
        } else if type.conforms(to: .audio) {
            self = .audio
        } else if type.conforms(to: .archive) {
            self = .archive
        } else {
            self = .general
        }
    }
    
    
    /// The system symbol name for label image.
    var symbolName: String {
        
        switch self {
            case .folder: "folder"
            case .general: "document"
            case .archive: "zipper.page"
            case .image: "photo"
            case .movie: "film"
            case .audio: "music.note"
        }
    }
    
    
    /// The localized label.
    var label: String {
        
        switch self {
            case .folder:
                String(localized: "File.Kind.folder.label", defaultValue: "Folder", table: "Document")
            case .general:
                String(localized: "File.Kind.general.label", defaultValue: "Document", table: "Document")
            case .archive:
                String(localized: "File.Kind.archive.label", defaultValue: "Archive", table: "Document")
            case .image:
                String(localized: "File.Kind.image.label", defaultValue: "Image", table: "Document")
            case .movie:
                String(localized: "File.Kind.movie.label", defaultValue: "Movie", table: "Document")
            case .audio:
                String(localized: "File.Kind.audio.label", defaultValue: "Audio", table: "Document")
        }
    }
}
