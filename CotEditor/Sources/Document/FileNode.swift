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
import OSLog
import UniformTypeIdentifiers
import URLUtils

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
    private(set) var isHidden: Bool
    private(set) var isWritable: Bool
    private(set) var isAlias: Bool
    private(set) var fileURL: URL
    private(set) weak var parent: FileNode?
    
    private var cachedChildren: [FileNode]?
    
    
    /// Initializes a file node instance.
    init(at fileURL: URL, isDirectory: Bool, parent: FileNode?, isWritable: Bool = true, isAlias: Bool = false) {
        
        self.isDirectory = isDirectory
        self.name = fileURL.lastPathComponent
        self.kind = Kind(filename: self.name, isDirectory: isDirectory)
        self.isHidden = fileURL.lastPathComponent.starts(with: ".")
        self.isWritable = isWritable
        self.isAlias = isAlias
        self.fileURL = fileURL.standardizedFileURL
        self.parent = parent
    }
    
    
    /// Initializes a file node instance by reading the information from the actual file.
    init(at fileURL: URL, parent: FileNode? = nil) throws {
        
        let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .isWritableKey, .isAliasFileKey, .isHiddenKey])
        
        self.isDirectory = resourceValues.isDirectory ?? false
        self.name = fileURL.lastPathComponent
        self.isHidden = resourceValues.isHidden ?? false
        self.isWritable = resourceValues.isWritable ?? true
        self.isAlias = resourceValues.isAliasFile ?? false
        self.fileURL = fileURL.standardizedFileURL
        self.parent = parent
        
        self.kind = if self.isAlias, (try? URL(resolvingAliasFileAt: fileURL).resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            .folder
        } else {
            Kind(filename: self.name, isDirectory: self.isDirectory)
        }
    }
    
    
    /// The children of the node by reading them lazily.
    var children: [FileNode]? {
        
        if self.cachedChildren == nil, self.isDirectory {
            do {
                self.cachedChildren = try self.readChildren()
            } catch {
                Logger.app.error("Failed reading folder contents: \(error)")
            }
        }
        return self.cachedChildren
    }
    
    
    /// The chain of the parents to the root node from the nearest.
    var parents: [FileNode] {
        
        if let parent {
            Array(sequence(first: parent, next: \.parent))
        } else {
            []
        }
    }
    
    
    /// Whether the receiver's `kind` is `.folder`.
    ///
    /// Unlike `.isDirectory` property, this property also returns `true` when the receiver is an alias linking to a folder.
    var isFolder: Bool {
        
        self.kind == .folder
    }
    
    
    /// The file URL by resolving any link and alias.
    var resolvedFileURL: URL {
        
        get throws {
            if self.isAlias {
                try URL(resolvingAliasFileAt: self.fileURL)
            } else {
                self.fileURL
            }
        }
    }
    
    
    /// Reads the contents of the directory at the receiver's `fileURL`.
    ///
    /// - Returns: The child nodes, or `nil` if the receiver is not a directory.
    private func readChildren() throws -> [FileNode] {
        
        assert(self.isDirectory)
        
        return try FileManager.default
            .contentsOfDirectory(at: self.fileURL, includingPropertiesForKeys: [.isDirectoryKey, .isWritableKey, .isAliasFileKey, .isHiddenKey])
            .filter { $0.lastPathComponent != ".DS_Store" }
            .map { try FileNode(at: $0, parent: self) }
            .sorted(using: SortDescriptor(\.name, comparator: .localizedStandard))
            .sorted(using: SortDescriptor(\.isFolder))
    }
    
    
    /// Updates `.kind` with current filename.
    private func invalidateKind() {
        
        guard !(self.isAlias && self.kind == .folder) else { return }
        
        self.kind = Kind(filename: self.name, isDirectory: self.isDirectory)
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


extension FileNode: CustomDebugStringConvertible {
    
    var debugDescription: String {
        
        "\(type(of: self))(name: \(self.name), isDirectory: \(self.isDirectory))"
    }
}


extension FileNode {
    
    /// Finds the node at the given `fileURL` in the node tree.
    ///
    ///  - Note: This method recursively reads child directories on storage during fining the node if the `inCache` flag is `false`.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL to find.
    ///   - inCache: If `true`, checks only cached children.
    /// - Returns: The file node found.
    func node(at fileURL: URL, inCache: Bool = false) -> FileNode? {
        
        let fileURL = fileURL.standardizedFileURL
        
        if fileURL == self.fileURL { return self }
        
        guard
            let children = inCache ? self.cachedChildren : self.children,
            self.fileURL.isAncestor(of: fileURL)
        else { return nil }
        
        if let node = children.first(where: { $0.fileURL == fileURL }) {
            return node
        }
        
        guard let child = children.first(where: { $0.fileURL.isAncestor(of: fileURL) }) else { return nil }
        
        return child.node(at: fileURL, inCache: inCache)
    }
    
    
    /// Invalidates file node tree.
    ///
    /// - Parameter fileURL: The URL of the file changed.
    /// - Returns: The node updated, or `nil` if the tree did not change.
    func invalidateChildren(at fileURL: URL) -> FileNode? {
        
        guard
            fileURL.lastPathComponent != ".DS_Store",
            self.isDirectory,
            let children = self.cachedChildren
        else { return nil }
        
        guard fileURL.deletingLastPathComponent() == self.fileURL else {
            return children
                .compactMap { $0.invalidateChildren(at: fileURL) }
                .first
        }
        
        if fileURL.isReachable {
            if children.contains(where: { $0.fileURL == fileURL }) {
                // -> The file structure is not changed.
                return nil
                
            } else {
                // -> The fileURL is added.
                guard let node = try? FileNode(at: fileURL, parent: self) else {
                    assertionFailure(); return self
                }
                self.addNode(node)
                return self
            }
            
        } else {
            if let index = children.firstIndex(where: { $0.fileURL.lastPathComponent == fileURL.lastPathComponent }) {
                // -> The file is deleted.
                self.cachedChildren?.remove(at: index)
                return self
                
            } else {
                // -> The change has probably been already processed by this app.
                return nil
            }
        }
    }

    
    /// Updates the related properties by assuming the receiver is moved to the given `fileURL`.
    ///
    /// - Parameter fileURL: The new file URL.
    func move(to fileURL: URL) {
        
        let keepsHidden = self.isHidden && !self.name.starts(with: ".")
        
        self.name = fileURL.lastPathComponent
        self.fileURL = fileURL.standardizedFileURL
        self.invalidateKind()
        if !keepsHidden {
            self.isHidden = self.name.starts(with: ".")
        }
        
        self.moveChildren(to: self.fileURL)
    }
    
    
    /// Renames and updates related properties.
    ///
    /// - Parameter newName: The new name to change.
    func rename(with newName: String) {
        
        assert(!newName.isEmpty)
        
        let keepsHidden = self.isHidden && !self.name.starts(with: ".")
        
        self.name = newName
        self.fileURL = self.fileURL.deletingLastPathComponent()
            .appending(path: newName, directoryHint: self.isDirectory ? .isDirectory : .notDirectory)
        self.invalidateKind()
        if !keepsHidden {
            self.isHidden = newName.starts(with: ".")
        }
        
        self.parent?.cachedChildren?.sort()
    }
    
    
    /// Moves to a new node.
    ///
    /// - Parameters:
    ///   - parent: The new parent node.
    func move(to parent: FileNode) {
        
        assert(parent.isDirectory)
        
        self.parent?.cachedChildren?.removeFirst(self)
        
        parent.addNode(self)
        self.parent = parent
        
        self.fileURL = parent.fileURL.appending(component: self.name).standardizedFileURL
        
        self.moveChildren(to: self.fileURL)
    }
    
    
    /// Adds a node at the receiver.
    ///
    /// - Parameter node: The file node to add.
    func addNode(_ node: FileNode) {
        
        assert(self.isDirectory)
        
        self.cachedChildren?.append(node)
        self.cachedChildren?.sort()
    }
    
    
    /// Deletes the receiver from the node tree.
    func delete() {
        
        self.parent?.cachedChildren?.removeFirst(self)
    }
    
    
    /// Recursively moves cached children to the file URL by just changing `fileURL`.
    ///
    /// - Parameter fileURL: The file URL where the children are placed.
    private func moveChildren(to fileURL: URL) {
        
        guard let children = self.cachedChildren else { return }
        
        for child in children {
            child.fileURL = fileURL.appending(component: child.name)
            child.moveChildren(to: self.fileURL)
        }
    }
}


private extension [FileNode] {
    
    /// Sorts items for display.
    mutating func sort() {
        
        self.sort(using: SortDescriptor(\.name, comparator: .localizedStandard))
        self.sort(using: SortDescriptor(\.isFolder))
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
            case .archive: if #available(macOS 15, *) { "zipper.page" } else { "doc.zipper" }
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
