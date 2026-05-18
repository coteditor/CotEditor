//
//  FolderTextSearchTests.swift
//  TextFindTests
//
//  CotEditor
//  https://coteditor.com
//
//  ---------------------------------------------------------------------------
//
//  © 2026 sdraeger
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
@testable import TextFind

struct FolderTextSearchTests {
    
    @Test func searchRecursivelyFindsTextMatches() async throws {
        
        let rootURL = FileManager.default.temporaryDirectory
            .appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        let nestedURL = rootURL.appending(component: "Nested", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: nestedURL, withIntermediateDirectories: true)
        
        let firstURL = rootURL.appending(component: "first.txt")
        let secondURL = nestedURL.appending(component: "second.md")
        try "alpha\nNeedle beta\n".write(to: firstURL, atomically: true, encoding: .utf8)
        try "prefix needle suffix\n".write(to: secondURL, atomically: true, encoding: .utf8)
        
        let matches = try await FolderTextSearch.matches(in: rootURL,
                                                         findString: "needle",
                                                         mode: .textual(options: .caseInsensitive, fullWord: false))
        
        #expect(matches.map { $0.fileURL.lastPathComponent } == ["first.txt", "second.md"])
        #expect(matches.map(\.lineNumber) == [2, 1])
        #expect(matches.map(\.inlineLocation) == [0, 7])
        #expect(matches.map(\.lineString) == ["Needle beta", "prefix needle suffix"])
    }
}
