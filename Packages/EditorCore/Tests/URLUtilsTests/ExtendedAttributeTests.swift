//
//  ExtendedAttributeTests.swift
//  URLUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-05.
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
@testable import URLUtils

actor ExtendedAttributeTests {
    
    @Test func setAndGetExtendedAttribute() throws {
        
        let file = try TemporaryFile()
        defer { file.cleanup() }
        
        let name = "com.coteditor.test." + UUID().uuidString
        let data = Data([0x01, 0x02, 0x03])
        
        try file.url.setExtendedAttribute(data: data, for: name)
        let result = try file.url.extendedAttribute(for: name)
        
        #expect(result == data)
    }
    
    
    @Test func removeExtendedAttribute() throws {
        
        let file = try TemporaryFile()
        defer { file.cleanup() }
        
        let name = "com.coteditor.test." + UUID().uuidString
        let data = Data([0x0A])
        
        try file.url.setExtendedAttribute(data: data, for: name)
        try file.url.setExtendedAttribute(data: nil, for: name)
        
        #expect(throws: POSIXError.self) {
            try file.url.extendedAttribute(for: name)
        }
    }
    
    
    @Test func missingExtendedAttribute() throws {
        
        let file = try TemporaryFile()
        defer { file.cleanup() }
        
        let name = "com.coteditor.test." + UUID().uuidString
        
        #expect(throws: POSIXError.self) {
            try file.url.extendedAttribute(for: name)
        }
    }
}


private struct TemporaryFile {
    
    let url: URL
    
    private let directoryURL: URL
    
    
    init() throws {
        
        let directoryURL = FileManager.default.temporaryDirectory
            .appending(component: "coteditor-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        let url = directoryURL.appending(component: "test.txt")
        try Data().write(to: url)
        
        self.url = url
        self.directoryURL = directoryURL
    }
    
    
    func cleanup() {
        
        try? FileManager.default.removeItem(at: self.directoryURL)
    }
}
