//
//  DocumentTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-27.
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

import AppKit
import UniformTypeIdentifiers
import Testing
@testable import CotEditor

@MainActor struct DocumentTests {
    
    @Test(arguments: ["script", "Makefile", ".zshrc"])
    func setSyntaxUsesTextForExtensionlessDocuments(documentName: String) {
        
        let document = Document()
        document.fileURL = URL(filePath: NSTemporaryDirectory()).appending(component: documentName)
        
        document.setSyntax(name: "Shell Script")
        
        #expect(document.fileType == UTType.plainText.identifier)
    }
    
    
    @Test func setSyntaxUsesSyntaxTypeForExtensionfulDocuments() throws {
        
        let document = Document()
        document.fileURL = URL(filePath: NSTemporaryDirectory()).appending(component: "script.sh")
        let shellScript = try #require(UTType(filenameExtension: "sh"))
        
        document.setSyntax(name: "Shell Script")
        
        #expect(document.fileType == shellScript.identifier)
    }
    
    
    @Test func setSyntaxKeepsExistingFilenameTypeForExtensionfulDocuments() throws {
        
        let document = Document()
        document.fileURL = URL(filePath: NSTemporaryDirectory()).appending(component: "README.txt")
        let plainText = try #require(UTType(filenameExtension: "txt"))
        
        document.setSyntax(name: SyntaxName.markdown)
        
        #expect(document.fileType == plainText.identifier)
    }
    
    
    @Test func setSyntaxUsesSyntaxTypeForUntitledDocuments() throws {
        
        let document = Document()
        let shellScript = try #require(UTType(filenameExtension: "sh"))
        
        document.setSyntax(name: "Shell Script")
        
        #expect(document.fileType == shellScript.identifier)
    }
    
    
    @Test func fileTypeUpdatesWhenDocumentNameChanges() async throws {
        
        let document = Document()
        let shellScript = try #require(UTType(filenameExtension: "sh"))
        
        document.setSyntax(name: "Shell Script")
        #expect(document.fileType == shellScript.identifier)
        
        document.fileURL = URL(filePath: NSTemporaryDirectory()).appending(component: "script")
        await Task.yield()
        
        #expect(document.fileType == UTType.plainText.identifier)
        
        document.fileURL = URL(filePath: NSTemporaryDirectory()).appending(component: "script.sh")
        await Task.yield()
        
        #expect(document.fileType == shellScript.identifier)
    }
    
    
    @Test func setSyntaxFallsBackToPlainText() {
        
        let document = Document()
        
        document.setSyntax(name: SyntaxName.none)
        
        #expect(document.fileType == UTType.plainText.identifier)
    }
}
