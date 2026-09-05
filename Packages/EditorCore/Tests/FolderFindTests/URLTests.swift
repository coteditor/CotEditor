//
//  URLTests.swift
//  FolderFindTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-09-05.
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
import FileEncoding
@testable import FolderFind

struct URLTests {
    
    @Test func plainTextIsNotBinary() throws {
        
        let url = try Self.makeTemporaryFile(Data("needle\n".utf8))
        defer { try? FileManager.default.removeItem(at: url) }
        
        #expect(try !url.isBinary)
    }
    
    
    @Test func emptyFileIsNotBinary() throws {
        
        let url = try Self.makeTemporaryFile(Data())
        defer { try? FileManager.default.removeItem(at: url) }
        
        #expect(try !url.isBinary)
    }
    
    
    @Test func nulByteWithinLeadingBytesIsBinary() throws {
        
        let url = try Self.makeTemporaryFile(Data(repeating: 0x61, count: 8_191) + Data([0x00]))
        defer { try? FileManager.default.removeItem(at: url) }
        
        #expect(try url.isBinary)
    }
    
    
    @Test func nulByteBeyondLeadingBytesIsNotBinary() throws {
        
        let url = try Self.makeTemporaryFile(Data(repeating: 0x61, count: 8_192) + Data([0x00]))
        defer { try? FileManager.default.removeItem(at: url) }
        
        #expect(try !url.isBinary)
    }
    
    
    @Test(arguments: Unicode.BOM.allCases)
    func textWithByteOrderMarkIsNotBinary(bom: Unicode.BOM) throws {
        
        let url = try Self.makeTemporaryFile(Data(bom.sequence) + Data([0x00, 0x61, 0x00, 0x62]))
        defer { try? FileManager.default.removeItem(at: url) }
        
        #expect(try !url.isBinary)
    }
    
    
    @Test func binaryPropertyListIsBinary() throws {
        
        let propertyList = ["key": "value"]
        let encoder = PropertyListEncoder()
        
        encoder.outputFormat = .binary
        let binaryURL = try Self.makeTemporaryFile(encoder.encode(propertyList))
        
        encoder.outputFormat = .xml
        let xmlURL = try Self.makeTemporaryFile(encoder.encode(propertyList))
        
        defer {
            try? FileManager.default.removeItem(at: binaryURL)
            try? FileManager.default.removeItem(at: xmlURL)
        }
        
        #expect(try binaryURL.isBinary)
        #expect(try !xmlURL.isBinary)
    }
    
    
    @Test func missingFileThrows() {
        
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        
        #expect(throws: (any Error).self) { try url.isBinary }
    }
    
    
    // MARK: Private Methods
    
    /// Writes the given data to a new temporary file.
    ///
    /// - Parameter data: The file contents.
    /// - Returns: The created file URL.
    private static func makeTemporaryFile(_ data: Data) throws -> URL {
        
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try data.write(to: url)
        
        return url
    }
}
