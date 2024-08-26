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
    
    
    let isDirectory: Bool
    private(set) var name: String
    private(set) var kind: Kind
    private(set) var isWritable: Bool
    private(set) var fileURL: URL
    private(set) weak var parent: FileNode?
    
    var isHidden: Bool  { self.name.starts(with: ".") }
    
    private var _children: [FileNode]?
    
    
    /// Initializes a file node instance.
    init(at fileURL: URL, isDirectory: Bool, parent: FileNode?) {
        
        self.isDirectory = isDirectory
        self.name = fileURL.lastPathComponent
        self.kind = Kind(filename: self.name, isDirectory: isDirectory)
        self.isWritable = true
        self.fileURL = fileURL
        self.parent = parent
    }
    
    
    /// Initializes a file node instance by reading the information from the actual file.
    init(at fileURL: URL, parent: FileNode? = nil) throws {
        
        let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .isWritableKey])
        
        self.isDirectory = resourceValues.isDirectory ?? false
        self.name = fileURL.lastPathComponent
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
            .filter { $0.lastPathComponent != ".DS_Store" }
            .map { try FileNode(at: $0, parent: self) }
            .sorted(using: SortDescriptor(\.name, comparator: .localizedStandard))
            .sorted(using: SortDescriptor(\.isDirectory))
    }
}


extension FileNode: Equatable {
    
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        
        lhs.isDirectory == rhs.isDirectory &&
        lhs.name == rhs.name &&
        lhs.parents.map(\.name) == rhs.parents.map(\.name) &&
        lhs.isWritable == rhs.isWritable
    }
}


extension FileNode: Hashable {
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(self.fileURL)
    }
}


extension FileNode: Identifiable {
    
    var id: [String]  { self.parents.map(\.name) + [self.name] }
}


extension FileNode {
    
    /// The chain of the parents to the root node from the nearest.
    private var parents: [FileNode] {
        
        if let parent {
            Array(sequence(first: parent, next: \.parent))
        } else {
            []
        }
    }
    
    
    func move(to fileURL: URL) {
        
        self.name = fileURL.lastPathComponent
        self.kind = Kind(filename: self.name, isDirectory: self.isDirectory)
        self.fileURL = fileURL
        
        self._children = nil
    }
    
    
    /// Invalidates file node tree.
    ///
    /// - Parameter fileURL: The URL of the file changed.
    /// - Returns: Whether the file tree actually updated.
    func invalidateChildren(at fileURL: URL) -> Bool {
        
        guard
            self.isDirectory,
            let children = self._children
        else { return false }
        
        if fileURL.deletingLastPathComponent() == self.fileURL {
            // -> The given fileURL is in this node.
            if let index = children.firstIndex(where: { $0.fileURL == fileURL }) {
                if (try? fileURL.checkResourceIsReachable()) == true {
                    return false
                } else {
                    // -> The file is deleted.
                    self._children?.remove(at: index)
                    return true
                }
                
            } else {
                // just invalidate all children
                self._children = nil
                return true
            }
            
        } else {
            return children.contains { $0.invalidateChildren(at: fileURL) }
        }
    }

    
    /// Renames and updates related properties.
    ///
    /// - Parameter newName: The new name to change.
    func rename(with newName: String) {
        
        assert(!newName.isEmpty)
        
        self.name = newName
        self.kind = Kind(filename: newName, isDirectory: self.isDirectory)
        self.fileURL = self.fileURL.deletingLastPathComponent().appending(path: newName)
        
        self.parent?._children?.sort()
    }
    
    
    /// Adds a node at the receiver.
    ///
    /// - Parameter node: The file node to add.
    func addNode(_ node: FileNode) {
        
        assert(self.isDirectory)
        
        self._children?.append(node)
        self._children?.sort()
    }
    
    
    /// Deletes the receiver from the node tree.
    func delete() {
        
        guard
            let parent,
            let index = parent.children?.firstIndex(of: self)
        else { return assertionFailure() }
        
        parent._children?.remove(at: index)
    }
}


private extension [FileNode] {
    
    /// Sorts items for display.
    mutating func sort() {
        
        self.sort(using: SortDescriptor(\.name, comparator: .localizedStandard))
        self.sort(using: SortDescriptor(\.isDirectory))
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
