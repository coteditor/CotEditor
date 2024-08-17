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
import FilePermissions

struct FileNode: Equatable {
    
    enum Kind {
        
        case folder
        case general
        case archive
        case image
        case movie
        case audio
    }
    
    
    var name: String
    var paths: [String]
    var children: [FileNode]?
    var kind: Kind
    var permissions: FilePermissions
    var fileURL: URL
    
    var isDirectory: Bool  { self.kind == .folder }
    var isHidden: Bool  { self.name.starts(with: ".") }
    var isWritable: Bool { self.permissions.user.contains(.write) }
    var directoryURL: URL  { self.isDirectory ? self.fileURL : self.fileURL.deletingLastPathComponent() }
}


extension FileNode: Hashable {
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(self.id)
    }
}


extension FileNode: Identifiable {
    
    var id: [String]  { self.paths + [self.name] }
}


extension FileNode {
    
    init?(fileWrapper: FileWrapper, paths: [String] = [], fileURL: URL) {
        
        guard let filename = fileWrapper.filename else { return nil }
        
        self.name = filename
        self.paths = paths
        self.fileURL = fileURL
        self.permissions = FilePermissions(mask: fileWrapper.fileAttributes[FileAttributeKey.posixPermissions] as? Int16 ?? 0)
        self.kind = fileWrapper.isDirectory ? .folder : Kind(filenameExtension: filename.pathExtension)
        
        if fileWrapper.isDirectory {
            self.children = fileWrapper.fileWrappers?
                .compactMap { FileNode(fileWrapper: $0.value, paths: paths + [filename], fileURL: fileURL.appending(component: $0.key)) }
                .sorted(using: SortDescriptor(\.name, comparator: .localizedStandard))
                .sorted(using: SortDescriptor(\.isDirectory))
        }
    }
    
    
    /// Returns the parent of the given node in the node tree.
    ///
    /// - Parameter node: The child node.
    /// - Returns: The parent node.
    func parent(of node: FileNode) -> FileNode? {
        
        guard let children else { return nil }
        
        if children.contains(node) { return self }
        
        return children.lazy
            .compactMap { $0.parent(of: node) }
            .first
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


extension [FileNode] {
    
    func recursivelyFilter(_ isIncluded: (FileNode) -> Bool) -> [FileNode] {
        
        self.filter(isIncluded).map {
            var tree = $0
            tree.children = tree.children?.recursivelyFilter(isIncluded)
            return tree
        }
    }
}


// MARK: FileNode.Kind

extension FileNode.Kind {
    
    init(filenameExtension: String?) {
        
        guard
            let filenameExtension,
            let uti = UTType(filenameExtension: filenameExtension)
        else {
            self = .general
            return
        }
        
        if uti.conforms(to: .plainText) == true {
            self = .general
        } else if uti.conforms(to: .image) == true {
            self = .image
        } else if uti.conforms(to: .movie) == true {
            self = .movie
        } else if uti.conforms(to: .audio) == true {
            self = .audio
        } else if uti.conforms(to: .archive) == true {
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
