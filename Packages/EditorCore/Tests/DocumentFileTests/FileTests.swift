//
//  FileTests.swift
//  DocumentFileTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-04.
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
@testable import DocumentFile

struct FileTests {
    
    @Test func initializeFileWithoutReadingDisk() {
        
        let fileURL = URL(filePath: "/tmp/.script.ts", directoryHint: .notDirectory)
        let file = File(at: fileURL, isDirectory: false)
        
        #expect(file.name == ".script.ts")
        #expect(file.fileURL == fileURL.standardizedFileURL)
        #expect(!file.isDirectory)
        #expect(file.isHidden)
        #expect(file.isWritable)
        #expect(!file.isAlias)
        #expect(file.kind == .general)
        #expect(file.tags.isEmpty)
    }
    
    
    @Test func initializeDirectoryWithoutReadingDisk() {
        
        let fileURL = URL(filePath: "/tmp/Folder", directoryHint: .isDirectory)
        let file = File(at: fileURL, isDirectory: true)
        
        #expect(file.isDirectory)
        #expect(file.kind == .folder)
        #expect(file.isFolder)
    }
    
    
    @Test func invalidateKindUpdatesFromCurrentFilename() {
        
        var file = File(at: URL(filePath: "/tmp/plain.txt", directoryHint: .notDirectory), isDirectory: false)
        
        file.fileURL = URL(filePath: "/tmp/image.png", directoryHint: .notDirectory)
        file.invalidateKind()
        
        #expect(file.kind == .image)
    }
    
    
    @Test func invalidateKindKeepsFolderAliasKind() {
        
        var file = File(at: URL(filePath: "/tmp/folder alias", directoryHint: .notDirectory), isDirectory: false)
        
        file.isAlias = true
        file.kind = .folder
        file.fileURL = URL(filePath: "/tmp/folder alias.png", directoryHint: .notDirectory)
        file.invalidateKind()
        
        #expect(file.kind == .folder)
    }
}
