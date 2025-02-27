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
//  © 2016-2025 1024jp
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
    
    
    @Test func createItemReplacementDirectory() throws {
        
        #expect(throws: Never.self) { try URL.itemReplacementDirectory }
    }
}
