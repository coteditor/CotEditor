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
import StringUtils
import URLUtils

final class FileNode {

    struct FilterState {
        
        var matchedRange: NSRange?
        var hasMatchedDescendant: Bool
    }
    
    
    private(set) var file: File
    private(set) weak var parent: FileNode?
    private(set) var filterState: FilterState?
    
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
    
    
    /// The chain of the parents to the root node from the nearest.
    var parents: [FileNode] {
        
        if let parent {
            Array(sequence(first: parent, next: \.parent))
        } else {
            []
        }
    }
    
    
    /// The children of the node by reading them lazily.
    var children: [FileNode]? {
        
        if self.file.isDirectory, self.cachedChildren == nil {
            do {
                // read synchronously for the immediate return
                self.cachedChildren = try Self.readChildFiles(at: self.file.fileURL)
                    .map { FileNode(file: $0, parent: self) }
            } catch {
                Logger.app.error("Failed reading folder contents: \(error)")
            }
        }
        return self.cachedChildren
    }
    
    
    /// Returns the receiver’s children filtered according to the current filter and hidden-file setting.
    ///
    /// - Parameters:
    ///   - includesHiddenNodes: If `false` hidden files and folders are excluded.
    /// - Returns: An array of `FileNode`, or `nil` if no children are available.
    func filteredChildren(includesHiddenNodes: Bool) -> [FileNode]? {
        
        let children = includesHiddenNodes
            ? self.children
            : self.children?.filter { !$0.file.isHidden }
        
        guard
            let children, !children.isEmpty,
            self.filterState != nil,
            !sequence(first: self, next: \.parent).contains(where: { $0.filterState?.matchedRange != nil })
        else { return children }
        
        return children.filter { $0.filterState.map { $0.hasMatchedDescendant || $0.matchedRange != nil } ?? false }
    }
    
    
    /// The sort order for display.
    private nonisolated static let sortOrder: [KeyPathComparator<FileNode>] = [
        KeyPathComparator(\.file.isFolder, comparator: BoolComparator()),
        KeyPathComparator(\.file.name, comparator: .localizedStandard),
    ]
    
    /// The sort order for display.
    private nonisolated static let fileSortOrder: [KeyPathComparator<File>] = [
        KeyPathComparator(\.isFolder, comparator: BoolComparator()),
        KeyPathComparator(\.name, comparator: .localizedStandard),
    ]
    
    
    /// Determines whether a filename should be ignored.
    ///
    /// - Parameter filename: The name of the file to evaluate.
    /// - Returns: `true` if the file should be skipped.
    private nonisolated static func accepts(filename: String) -> Bool {
        
        ![".DS_Store", ".git"].contains(filename)
    }
    
    
    /// Reads and returns the immediate child files for the given directory URL.
    ///
    /// - Parameters:
    ///   - fileURL: The directory URL whose contents should be read.
    /// - Returns: An array of `File` objects representing the accepted child items, sorted for display.
    /// - Throws: An error if reading the directory contents or initializing `File` metadata fails.
    private nonisolated static func readChildFiles(at fileURL: URL) throws -> [File] {
        
        try FileManager.default
            .contentsOfDirectory(at: fileURL, includingPropertiesForKeys: Array(File.resourceValues))
            .filter { Self.accepts(filename: $0.lastPathComponent) }
            .map { try File(at: $0) }
            .sorted(using: Self.fileSortOrder)
    }
}


extension FileNode: Equatable {
    
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        
        lhs.file.isDirectory == rhs.file.isDirectory &&
        lhs.file.name == rhs.file.name &&
        lhs.file.isWritable == rhs.file.isWritable &&
        lhs.parents.map(\.file.name) == rhs.parents.map(\.file.name)
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
            Self.accepts(filename: fileURL.lastPathComponent),
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
                let file: File
                do {
                    file = try File(at: fileURL)
                } catch {
                    Logger.app.error("Failed reading file metadata: \(error)")
                    return self
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
    
    
    /// Updates this node’s filter state based on a search string and whether any descendant matched.
    ///
    /// - Parameters:
    ///   - searchString: The text to search for within the file name. 
    ///   - hasMatchedDescendant: `true` if any descendant of this node matched the search string; otherwise, `false`.
    /// - Returns: `true` if this node’s name directly matches `searchString`; otherwise, `false`.
    @discardableResult func updateFilter(with searchString: String, hasMatchedDescendant: Bool) -> Bool {
        
        let match: NSRange = (self.parent == nil)
            ? .notFound
            : (self.file.name as NSString).range(of: searchString, options: .caseInsensitive)
        let isMatched = !match.isNotFound
        
        self.filterState = FilterState(matchedRange: isMatched ? match : nil,
                                       hasMatchedDescendant: hasMatchedDescendant)
        
        return isMatched
    }
    
    
    /// Recursively searches the receiver and its descendants for names matching the given string.
    ///
    /// - Note: This method updates the `filterState` property of each visited node.
    ///
    /// - Parameters:
    ///   - searchString: The text to search for within the file name.
    ///   - includesHiddenFiles: If `true`, includes hidden files and folders in the search.
    /// - Returns: An array of nodes that match the search string within this subtree.
    /// - Throws: `CancellationError` or errors on file reading.
    @discardableResult func filter(with searchString: String, includesHiddenFiles: Bool) async throws -> [FileNode] {
        
        assert(!searchString.isEmpty)
        
        try Task.checkCancellation()
        
        var matchedDescendants: [FileNode] = []
        if self.file.isDirectory {
            // async read files in background
            if self.cachedChildren == nil {
                let fileURL = self.file.fileURL
                self.cachedChildren = try await Task.detached(priority: .userInitiated) { @Sendable in  // explicit @Sendable for a Swift-side bug (2025-10, Xcode 26.1, Swift 6.2.1)
                    try Self.readChildFiles(at: fileURL)
                }
                .value
                .map { FileNode(file: $0, parent: self) }
            }
            
            if let children {
                for child in children where includesHiddenFiles || !child.file.isHidden {
                    matchedDescendants += try await child.filter(with: searchString, includesHiddenFiles: includesHiddenFiles)
                }
            }
        }
        
        let isMatched = self.updateFilter(with: searchString, hasMatchedDescendant: !matchedDescendants.isEmpty)
        
        return isMatched ? ([self] + matchedDescendants) : matchedDescendants
    }
    
    
    /// Recursively sets `nil` to `filterState` of the receiver and its descendants.
    func removeFilterStates() {
        
        self.filterState = nil
        self.cachedChildren?.forEach {
            $0.removeFilterStates()
        }
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
