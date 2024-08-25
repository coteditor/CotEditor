//
//  FileNode.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

final class FileNode {
    
    enum Kind {
        
        case folder
        case general
        case archive
        case image
        case movie
        case audio
    }
    
    
    var name: String
    var isDirectory: Bool
    var kind: Kind
    var isWritable: Bool
    var fileURL: URL
    weak var parent: FileNode?
    
    var isHidden: Bool  { self.name.starts(with: ".") }
    var directoryURL: URL  { self.isDirectory ? self.fileURL : self.fileURL.deletingLastPathComponent() }
    
    private var _children: [FileNode]?
    
    
    init(at fileURL: URL, parent: FileNode? = nil) throws {
        
        let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .isWritableKey])
        
        self.name = fileURL.lastPathComponent
        self.isDirectory = resourceValues.isDirectory ?? false
        self.kind = Kind(filename: self.name, isDirectory: self.isDirectory)
        self.isWritable = resourceValues.isWritable ?? true
        self.fileURL = fileURL
        self.parent = parent
    }
    
    
    /// The children of the node by reading them lazily.
    var children: [FileNode]? {
        
        if self._children == nil, self.isDirectory {
            self._children = try? self.readChildren()
        }
        return self._children
    }
    
    
    /// Reads the contents of the directory at the receiver's `fileURL`.
    ///
    /// - Returns: The child nodes, or `nil` if the receiver is not a directory.
    private func readChildren() throws -> [FileNode] {
        
        assert(self.isDirectory)
        
        return try FileManager.default
            .contentsOfDirectory(at: self.fileURL, includingPropertiesForKeys: [.isDirectoryKey, .isWritableKey])
            .map { try FileNode(at: $0, parent: self) }
            .sorted(using: SortDescriptor(\.name, comparator: .localizedStandard))
            .sorted(using: SortDescriptor(\.isDirectory))
    }
}


extension FileNode: Equatable {
    
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        
        lhs.name == rhs.name &&
        lhs.isDirectory == rhs.isDirectory &&
        lhs.parents.map(\.name) == rhs.parents.map(\.name) &&
        lhs.children?.map(\.name) == rhs.children?.map(\.name) &&
        lhs.isWritable == rhs.isWritable
    }
}


extension FileNode: Identifiable {
    
    var id: [String]  { self.parents.map(\.name) + [self.name] }
}


extension FileNode {
    
    /// The chain of the parents to the root node from the nearest.
    private var parents: [FileNode]  {
        
        if let parent {
            Array(sequence(first: parent, next: \.parent))
        } else {
            []
        }
    }
    
    
    /// Returns a file node with the given ID in the receiver's tree if exists.
    ///
    /// - Parameter id: The identifier of the node to find.
    /// - Returns: A found file node.
    func node<Value: Equatable>(with value: Value, keyPath: KeyPath<FileNode, Value>) -> FileNode? {
        
        (self[keyPath: keyPath] == value) ? self : self.children?
            .lazy
            .compactMap { $0.node(with: value, keyPath: keyPath) }
            .first
    }
}


// MARK: FileNode.Kind

extension FileNode.Kind {
    
    init(filename: String, isDirectory: Bool) {
        
        if isDirectory {
            self = .folder
            return
        }
        
        guard
            let filenameExtension = filename.pathExtension,
            let uti = UTType(filenameExtension: filenameExtension)
        else {
            self = .general
            return
        }
        
        if uti.conforms(to: .plainText) || uti.conforms(to: .xml) {
            self = .general
        } else if uti.conforms(to: .image) {
            self = .image
        } else if uti.conforms(to: .movie) {
            self = .movie
        } else if uti.conforms(to: .audio) {
            self = .audio
        } else if uti.conforms(to: .archive) {
            self = .archive
        } else {
            self = .general
        }
    }
    
    
    /// The system symbol name for label image.
    var symbolName: String {
        
        switch self {
            case .folder: "folder"
            case .general: "doc"
            case .archive: "zipper.page"
            case .image: "photo"
            case .movie: "film"
            case .audio: "music.note"
        }
    }
    
    
    /// The label.
    var label: String {
        
        switch self {
            case .folder:
                String(localized: "FileNode.Kind.folder.label", defaultValue: "Folder", table: "Document",
                       comment: "accessibility description for icon in file browser")
            case .general:
                String(localized: "FileNode.Kind.general.label", defaultValue: "Document", table: "Document",
                       comment: "accessibility description for icon in file browser")
            case .archive:
                String(localized: "FileNode.Kind.archive.label", defaultValue: "Archive", table: "Document",
                       comment: "accessibility description for icon in file browser")
            case .image:
                String(localized: "FileNode.Kind.image.label", defaultValue: "Image", table: "Document",
                       comment: "accessibility description for icon in file browser")
            case .movie:
                String(localized: "FileNode.Kind.movie.label", defaultValue: "Movie", table: "Document",
                       comment: "accessibility description for icon in file browser")
            case .audio:
                String(localized: "FileNode.Kind.audio.label", defaultValue: "Audio", table: "Document",
                       comment: "accessibility description for icon in file browser")
        }
    }
}
