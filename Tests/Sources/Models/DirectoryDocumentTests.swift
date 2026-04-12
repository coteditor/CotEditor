//
//  DirectoryDocumentTests.swift
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
import URLUtils
@testable import CotEditor

struct DirectoryDocumentTests {
    
    @Test @MainActor func movingFolderToDestinationWithExistingNameUsesActualDestinationURL() throws {
        
        let urls = try self.makeMoveConflictTree()
        defer { try? FileManager.default.removeItem(at: urls.rootURL) }
        
        let document = DirectoryDocument()
        document.fileURL = urls.rootURL
        try document.read(from: urls.rootURL, ofType: "public.folder")
        
        let rootNode = try #require(document.fileNode)
        let movingNode = try #require(rootNode.node(at: urls.folderURL))
        let destinationNode = try #require(rootNode.node(at: urls.destinationURL))
        let leafNode = try #require(rootNode.node(at: urls.leafURL))
        let expectedURL = urls.destinationURL.appending(component: movingNode.file.name).appendingUniqueNumber().standardizedFileURL
        
        try document.moveItem(at: movingNode, to: destinationNode)
        
        #expect(movingNode.parent === destinationNode)
        #expect(self.path(of: movingNode.file.fileURL) == self.path(of: expectedURL))
        #expect(self.path(of: leafNode.file.fileURL) == self.path(of: expectedURL.appending(path: "child/leaf.txt", directoryHint: .notDirectory)))
        #expect(FileManager.default.fileExists(atPath: expectedURL.path(percentEncoded: false)))
    }
    
    
    // MARK: Private Methods
    
    private func makeMoveConflictTree() throws -> (rootURL: URL, folderURL: URL, destinationURL: URL, leafURL: URL) {
        
        let rootURL = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let folderURL = rootURL.appending(path: "folder", directoryHint: .isDirectory)
        let childFolderURL = folderURL.appending(path: "child", directoryHint: .isDirectory)
        let leafURL = childFolderURL.appending(path: "leaf.txt", directoryHint: .notDirectory)
        let destinationURL = rootURL.appending(path: "destination", directoryHint: .isDirectory)
        let conflictingURL = destinationURL.appending(path: "folder", directoryHint: .isDirectory)
        
        try FileManager.default.createDirectory(at: childFolderURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: conflictingURL, withIntermediateDirectories: true)
        try Data().write(to: leafURL)
        
        return (rootURL, folderURL, destinationURL, leafURL)
    }
    
    
    private func path(of url: URL) -> String {
        
        NSString(string: url.standardizedFileURL.path(percentEncoded: false)).standardizingPath
    }
}
