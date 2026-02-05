//
//  URLExtensionsTests.swift
//  URLUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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
@testable import URLUtils

struct URLExtensionsTests {
    
    @Test func createRelativeURL() {
        
        let url = URL(filePath: "/foo/bar/file.txt")
        let baseURL = URL(filePath: "/foo/buz/file.txt")
        
        #expect(url.path(relativeTo: baseURL) == "../bar/file.txt")
    }
    
    
    @Test func createRelativeURL2() {
        
        let url = URL(filePath: "/file1.txt")
        let baseURL = URL(filePath: "/file2.txt")
        
        #expect(url.path(relativeTo: baseURL) == "file1.txt")
    }
    
    
    @Test func createRelativeURLWithSameURLs() {
        
        let url = URL(filePath: "/file1.txt")
        let baseURL = URL(filePath: "/file1.txt")
        
        #expect(url.path(relativeTo: baseURL) == "file1.txt")
    }
    
    
    @Test func createRelativeURLWithDirectoryURLs() {
        
        let url = URL(filePath: "Dog/Cow/Cat/file1.txt")
        #expect(url.path(relativeTo: URL(filePath: "Dog/Cow", directoryHint: .isDirectory)) == "Cat/file1.txt")
        #expect(url.path(relativeTo: URL(filePath: "Dog/Cow/", directoryHint: .isDirectory)) == "Cat/file1.txt")
        #expect(url.path(relativeTo: URL(filePath: "Dog/Cow/Cat", directoryHint: .isDirectory)) == "file1.txt")
        #expect(url.path(relativeTo: URL(filePath: "", directoryHint: .isDirectory)) == "Dog/Cow/Cat/file1.txt")
        
        let url2 = URL(filePath: "file1.txt")
        #expect(url2.path(relativeTo: URL(filePath: "", directoryHint: .isDirectory)) == "file1.txt")
        #expect(url2.path(relativeTo: URL(filePath: "Dog", directoryHint: .isDirectory)) == "../file1.txt")
    }
    
    
    @Test func ancestor() throws {
        
        let leaf = URL(filePath: "/Dog/Cow/Cat")
        let parent = leaf.deletingLastPathComponent()
        
        #expect(parent.isAncestor(of: leaf))
        #expect(!parent.isAncestor(of: URL(filePath: "/Dog/Cow 1/Cat")))
        #expect(!leaf.isAncestor(of: leaf))
    }
    
    
    @Test func firstUniqueDirectoryURL() {
        
        let urls: [URL] = [
            URL(string: "Dog/Cow/file.txt")!,
            URL(string: "Dog/Sheep/file.txt")!,
        ]
        
        #expect(URL(string: "Dog/Cow/file copy.txt")!.firstUniqueDirectoryURL(in: urls) == nil)
        #expect(URL(string: "Cat/Cow/file.txt")!.firstUniqueDirectoryURL(in: urls) == URL(string: "Cat/"))
        #expect(URL(string: "Dog/Pig/file.txt")!.firstUniqueDirectoryURL(in: urls) == URL(string: "Dog/Pig/"))
    }
    
    
    @Test func appendingUniqueNumber() throws {
        
        let directory = try TemporaryDirectory()
        defer { directory.cleanup() }
        
        let base = directory.url.appending(component: "file.txt")
        
        #expect(base.appendingUniqueNumber().lastPathComponent == "file.txt")
        
        try Data().write(to: base)
        #expect(base.appendingUniqueNumber().lastPathComponent == "file 2.txt")
        
        let numbered = directory.url.appending(component: "file 2.txt")
        try Data().write(to: numbered)
        #expect(base.appendingUniqueNumber().lastPathComponent == "file 3.txt")
        #expect(numbered.appendingUniqueNumber().lastPathComponent == "file 3.txt")
    }
    
    
    @Test func appendingUniqueNumberWithFormat() throws {
        
        let directory = try TemporaryDirectory()
        defer { directory.cleanup() }
        
        let format = NumberingFormat({ "\($0) copy" }, numbered: { "\($0) copy \($1)" })
        let base = directory.url.appending(component: "doc.txt")
        let baseCopy = directory.url.appending(component: "doc copy.txt")
        
        #expect(base.appendingUniqueNumber(format: format).lastPathComponent == "doc copy.txt")
        
        try Data().write(to: baseCopy)
        #expect(base.appendingUniqueNumber(format: format).lastPathComponent == "doc copy 2.txt")
    }
    
    
    @Test func createIntermediateDirectories() throws {
        
        let directory = try TemporaryDirectory()
        defer { directory.cleanup() }
        
        let fileURL = directory.url.appending(path: "a/b/c/file.txt")
        let directoryURL = directory.url.appending(path: "a/b/c", directoryHint: .isDirectory)
        
        try FileManager.default.createIntermediateDirectories(to: fileURL)
        
        #expect(FileManager.default.fileExists(atPath: directoryURL.path))
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }
}


private struct TemporaryDirectory {
    
    let url: URL
    
    
    init() throws {
        
        let url = FileManager.default.temporaryDirectory
            .appending(component: "coteditor-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        
        self.url = url
    }
    
    
    func cleanup() {
        
        try? FileManager.default.removeItem(at: self.url)
    }
}
