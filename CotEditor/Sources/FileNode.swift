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
import FilePermissions

struct FileNode: Equatable, Sendable {
    
    var name: String
    var paths: [String]
    var children: [FileNode]?
    var isDirectory: Bool
    var permissions: FilePermissions
    var fileURL: URL
    
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
        self.isDirectory = fileWrapper.isDirectory
        self.fileURL = fileURL
        self.permissions = FilePermissions(mask: fileWrapper.fileAttributes[FileAttributeKey.posixPermissions] as? Int16 ?? 0)
        
        if fileWrapper.isDirectory {
            self.children = fileWrapper.fileWrappers?
                .compactMap { FileNode(fileWrapper: $0.value, paths: paths + [filename], fileURL: fileURL.appending(component: $0.key)) }
                .sorted(using: SortDescriptor(\.name, comparator: .localizedStandard))
                .sorted(using: SortDescriptor(\.isDirectory))
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


extension [FileNode] {
    
    func recursivelyFilter(_ isIncluded: (FileNode) -> Bool) -> [FileNode] {
        
        self.filter(isIncluded).map {
            var tree = $0
            tree.children = tree.children?.recursivelyFilter(isIncluded)
            return tree
        }
    }
}
