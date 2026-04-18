//
//  PortableSettingsDocumentTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-18.
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
import SemanticVersioning
import SyntaxFormat
@testable import CotEditor

@MainActor struct PortableSettingsDocumentTests {
    
    @Test func settingsArchiveRoundTripKeepsCustomSyntaxPackage() throws {
        
        let archiveURL = try self.createSettingsArchive()
        defer { try? FileManager.default.removeItem(at: archiveURL.deletingLastPathComponent()) }
        
        let document = try PortableSettingsDocument(contentsOf: archiveURL)
        let payload = try #require(document.syntaxes["Sample.cotsyntax"])
        let fileWrapper = try #require(payload as? FileWrapper)
        let syntax = try Syntax(payload: fileWrapper, type: .cotSyntax)
        
        #expect(document.bundledSettings[.syntaxes] == ["Sample.cotsyntax"])
        #expect(fileWrapper.fileWrappers?["Info.json"]?.regularFileContents != nil)
        #expect(syntax.kind == .code)
        #expect(syntax.fileMap.extensions == ["sample"])
    }
    
    
    // MARK: Private Methods
    
    private func createSettingsArchive() throws -> URL {
        
        let info = PortableSettingsDocument.Info(date: .now, version: Version(7, 0, 0))
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        let defaultsData = try PropertyListSerialization.data(fromPropertyList: [:], format: .xml, options: 0)
        let syntaxInfoData = Data("""
            {
              "kind" : "code",
              "fileMap" : {
                "extensions" : [
                  "sample"
                ]
              }
            }
            """.utf8)
        
        let archive = FileWrapper(directoryWithFileWrappers: [
            "Info.plist": FileWrapper(regularFileWithContents: try encoder.encode(info)),
            "Defaults.plist": FileWrapper(regularFileWithContents: defaultsData),
            "Syntaxes": FileWrapper(directoryWithFileWrappers: [
                "Sample.cotsyntax": FileWrapper(directoryWithFileWrappers: [
                    "Info.json": FileWrapper(regularFileWithContents: syntaxInfoData),
                ]),
            ]),
        ])
        
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        let archiveURL = directoryURL.appendingPathComponent("Settings").appendingPathExtension("cotsettings")
        try archive.write(to: archiveURL, options: .atomic, originalContentsURL: nil)
        
        return archiveURL
    }
}
