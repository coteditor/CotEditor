//
//  FileNodeTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-12.
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

import Foundation
import Testing
@testable import CotEditor

struct FileNodeTests {
    
    @Test func renamingFolderUpdatesCachedDescendantURLs() throws {
        
        let urls = try self.makeDirectoryTree()
        defer { try? FileManager.default.removeItem(at: urls.rootURL) }
        
        let rootNode = FileNode(file: try File(at: urls.rootURL))
        let folderNode = try #require(rootNode.node(at: urls.folderURL))
        let childNode = try #require(rootNode.node(at: urls.childFolderURL))
        let leafNode = try #require(rootNode.node(at: urls.leafURL))
        
        folderNode.rename(with: "renamed")
        
        let renamedFolderURL = urls.rootURL.appending(path: "renamed", directoryHint: .isDirectory).standardizedFileURL
        
        #expect(self.path(of: folderNode.file.fileURL) == self.path(of: renamedFolderURL))
        #expect(self.path(of: childNode.file.fileURL) == self.path(of: renamedFolderURL.appending(path: "child", directoryHint: .isDirectory)))
        #expect(self.path(of: leafNode.file.fileURL) == self.path(of: renamedFolderURL.appending(path: "child/leaf.txt", directoryHint: .notDirectory)))
    }
    
    
    @Test func movingFolderUpdatesNestedDescendantURLs() throws {
        
        let urls = try self.makeDirectoryTree()
        defer { try? FileManager.default.removeItem(at: urls.rootURL) }
        
        let rootNode = FileNode(file: try File(at: urls.rootURL))
        let folderNode = try #require(rootNode.node(at: urls.folderURL))
        let destinationNode = try #require(rootNode.node(at: urls.destinationURL))
        let childNode = try #require(rootNode.node(at: urls.childFolderURL))
        let leafNode = try #require(rootNode.node(at: urls.leafURL))
        
        folderNode.move(to: destinationNode)
        
        let movedFolderURL = urls.destinationURL.appending(path: "folder", directoryHint: .isDirectory).standardizedFileURL
        
        #expect(folderNode.parent === destinationNode)
        #expect(self.path(of: folderNode.file.fileURL) == self.path(of: movedFolderURL))
        #expect(self.path(of: childNode.file.fileURL) == self.path(of: movedFolderURL.appending(path: "child", directoryHint: .isDirectory)))
        #expect(self.path(of: leafNode.file.fileURL) == self.path(of: movedFolderURL.appending(path: "child/leaf.txt", directoryHint: .notDirectory)))
    }
    
    
    // MARK: Private Methods
    
    private struct DirectoryTree {
        
        var rootURL: URL
        var folderURL: URL
        var childFolderURL: URL
        var leafURL: URL
        var destinationURL: URL
    }
    
    
    private func makeDirectoryTree() throws -> DirectoryTree {
        
        let rootURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let folderURL = rootURL.appending(path: "folder", directoryHint: .isDirectory)
        let childFolderURL = folderURL.appending(path: "child", directoryHint: .isDirectory)
        let leafURL = childFolderURL.appending(path: "leaf.txt", directoryHint: .notDirectory)
        let destinationURL = rootURL.appending(path: "destination", directoryHint: .isDirectory)
        
        try FileManager.default.createDirectory(at: childFolderURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        try Data().write(to: leafURL)
        
        return DirectoryTree(rootURL: rootURL, folderURL: folderURL, childFolderURL: childFolderURL, leafURL: leafURL, destinationURL: destinationURL)
    }
    
    
    private func path(of url: URL) -> String {
        
        NSString(string: url.standardizedFileURL.path(percentEncoded: false)).standardizingPath
    }
}
