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
import OSLog
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
    
    
    var fileURL: URL
    let isDirectory: Bool
    var name: String
    var kind: Kind
    var isHidden: Bool
    var isWritable: Bool
    var isAlias: Bool
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
        
        self.fileURL = fileURL.standardizedFileURL
        self.isDirectory = isDirectory
        self.name = fileURL.lastPathComponent
        self.kind = Kind(filename: self.name, isDirectory: isDirectory)
        self.isHidden = fileURL.lastPathComponent.starts(with: ".")
        self.isWritable = true
        self.isAlias = false
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
        
        let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .isHiddenKey, .isWritableKey, .isAliasFileKey])
        
        self.fileURL = fileURL.standardizedFileURL
        self.isDirectory = resourceValues.isDirectory ?? false
        self.name = fileURL.lastPathComponent
        self.isHidden = resourceValues.isHidden ?? false
        self.isWritable = resourceValues.isWritable ?? true
        self.isAlias = resourceValues.isAliasFile ?? false
        
        self.kind = if self.isAlias, (try? URL(resolvingAliasFileAt: fileURL).resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            .folder
        } else {
            Kind(filename: self.name, isDirectory: self.isDirectory)
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
    
    
    /// Updates `.kind` with current filename.
    mutating func invalidateKind() {
        
        guard !(self.isAlias && self.kind == .folder) else { return }
        
        self.kind = Kind(filename: self.name, isDirectory: self.isDirectory)
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


// MARK: FileNode

final class FileNode {
    
    private(set) var file: File
    private(set) weak var parent: FileNode?
    
    private var cachedChildren: [FileNode]?
    
    
    /// Initializes a file node instance.
    ///
    /// - Parameters:
    ///   - file: The file metadata.
    ///   - parent: The parent node in the tree, or `nil` if this is a root node.
    init(file: File, parent: FileNode? = nil) {
        
        self.file = file
        self.parent = parent
    }
    
    
    /// The children of the node by reading them lazily.
    var children: [FileNode]? {
        
        if self.file.isDirectory, self.cachedChildren == nil {
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
    
    
    /// The sort order for display.
    private nonisolated static let sortOrder: [KeyPathComparator<FileNode>] = [
        KeyPathComparator(\.file.isFolder, comparator: BoolComparator()),
        KeyPathComparator(\.file.name, comparator: .localizedStandard)
    ]
    
    
    /// Reads the contents of the directory at the receiver's `fileURL`.
    ///
    /// - Returns: The child nodes, or `nil` if the receiver is not a directory.
    private func readChildren() throws -> [FileNode] {
        
        assert(self.file.isDirectory)
        
        return try FileManager.default
            .contentsOfDirectory(at: self.file.fileURL, includingPropertiesForKeys: [.isDirectoryKey, .isWritableKey, .isAliasFileKey, .isHiddenKey])
            .filter { $0.lastPathComponent != ".DS_Store" }
            .map { try File(at: $0) }
            .map { FileNode(file: $0, parent: self) }
            .sorted(using: Self.sortOrder)
    }
}


extension FileNode: Equatable {
    
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        
        lhs.file.isDirectory == rhs.file.isDirectory &&
        lhs.file.name == rhs.file.name &&
        lhs.parents.map(\.file.name) == rhs.parents.map(\.file.name) &&
        lhs.file.isWritable == rhs.file.isWritable
    }
}


extension FileNode: Hashable {
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(self.file.fileURL)
    }
}


extension FileNode: CustomDebugStringConvertible {
    
    var debugDescription: String {
        
        "\(type(of: self))(name: \(self.file.name), isDirectory: \(self.file.isDirectory))"
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
        
        if fileURL == self.file.fileURL { return self }
        
        guard
            let children = inCache ? self.cachedChildren : self.children,
            self.file.fileURL.isAncestor(of: fileURL)
        else { return nil }
        
        if let node = children.first(where: { $0.file.fileURL == fileURL }) {
            return node
        }
        
        guard let child = children.first(where: { $0.file.fileURL.isAncestor(of: fileURL) }) else { return nil }
        
        return child.node(at: fileURL, inCache: inCache)
    }
    
    
    /// Synchronizes the file node tree with changes at a given file URL.
    ///
    /// This method traverses the node tree recursively to locate the node corresponding to the specified `fileURL`,
    /// updating the cached children as needed to reflect changes in the file system.
    ///
    /// - Parameter fileURL: The file URL where a change occurred.
    /// - Returns: The node updated, or `nil` if the tree did not change.
    func invalidateChildren(at fileURL: URL) -> FileNode? {
        
        guard
            fileURL.lastPathComponent != ".DS_Store",
            self.file.isDirectory,
            let children = self.cachedChildren
        else { return nil }
        
        guard fileURL.deletingLastPathComponent() == self.file.fileURL else {
            return children
                .compactMap { $0.invalidateChildren(at: fileURL) }
                .first
        }
        
        if fileURL.isReachable {
            if let child = children.first(where: { $0.file.fileURL == fileURL }) {
                guard (try? child.file.invalidateResources()) == true else { return nil }
                return child
                
            } else {
                // -> The fileURL is added.
                guard let file = try? File(at: fileURL) else {
                    assertionFailure(); return self
                }
                self.addNode(FileNode(file: file, parent: self))
                return self
            }
            
        } else {
            if let index = children.firstIndex(where: { $0.file.fileURL.lastPathComponent == fileURL.lastPathComponent }) {
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
        
        let keepsHidden = self.file.isHidden && !self.file.name.starts(with: ".")
        
        self.file.name = fileURL.lastPathComponent
        self.file.fileURL = fileURL.standardizedFileURL
        self.file.invalidateKind()
        if !keepsHidden {
            self.file.isHidden = self.file.name.starts(with: ".")
        }
        
        self.moveChildren(to: self.file.fileURL)
    }
    
    
    /// Renames and updates related properties.
    ///
    /// - Parameter newName: The new name to change.
    func rename(with newName: String) {
        
        assert(!newName.isEmpty)
        
        let keepsHidden = self.file.isHidden && !self.file.name.starts(with: ".")
        
        self.file.name = newName
        self.file.fileURL = self.file.fileURL.deletingLastPathComponent()
            .appending(path: newName, directoryHint: self.file.isDirectory ? .isDirectory : .notDirectory)
        self.file.invalidateKind()
        if !keepsHidden {
            self.file.isHidden = newName.starts(with: ".")
        }
        
        self.parent?.cachedChildren?.sort(using: Self.sortOrder)
    }
    
    
    /// Moves to a new node.
    ///
    /// - Parameters:
    ///   - parent: The new parent node.
    func move(to parent: FileNode) {
        
        assert(parent.file.isDirectory)
        
        self.parent?.cachedChildren?.removeFirst(self)
        
        parent.addNode(self)
        self.parent = parent
        
        self.file.fileURL = parent.file.fileURL.appending(component: self.file.name).standardizedFileURL
        
        self.moveChildren(to: self.file.fileURL)
    }
    
    
    /// Adds a node at the receiver.
    ///
    /// - Parameter node: The file node to add.
    func addNode(_ node: FileNode) {
        
        assert(self.file.isDirectory)
        
        self.cachedChildren?.append(node)
        self.cachedChildren?.sort(using: Self.sortOrder)
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
            child.file.fileURL = fileURL.appending(component: child.file.name)
            child.moveChildren(to: self.file.fileURL)
        }
    }
}


// MARK: File.Kind

extension File.Kind {
    
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
