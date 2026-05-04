//
//  FileAttributesTests.swift
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

struct FileAttributesTests {
    
    @Test func initializeFromFileAttributeDictionary() throws {
        
        let creationDate = Date(timeIntervalSince1970: 1_000)
        let modificationDate = Date(timeIntervalSince1970: 2_000)
        let userTags = try Self.userTagsData(["Green\n2", "None"])
        let dictionary: [FileAttributeKey: Any] = [
            .creationDate: creationDate,
            .modificationDate: modificationDate,
            .size: Int64(123),
            .posixPermissions: Int16(0o640),
            .ownerAccountName: "coteditor",
            .extendedAttributes: [ExtendedFileAttributeName.userTags: userTags],
        ]
        
        let attributes = FileAttributes(dictionary: dictionary)
        
        #expect(attributes.creationDate == creationDate)
        #expect(attributes.modificationDate == modificationDate)
        #expect(attributes.size == 123)
        #expect(attributes.permissions == FilePermissions(mask: 0o640))
        #expect(attributes.owner == "coteditor")
        #expect(attributes.tags == [
            FinderTag(name: "Green", color: .green),
            FinderTag(name: "None"),
        ])
    }
    
    private static func userTagsData(_ tags: [String]) throws -> Data {
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        return try encoder.encode(tags)
    }
}
