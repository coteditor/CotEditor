//
//  FinderTagTests.swift
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

struct FinderTagTests {
    
    @Test func parseTagsFromExtendedAttributeData() throws {
        
        let data = try Self.userTagsData(["Red\n6", "Plain", "Unknown\n99"])
        
        let tags = FinderTag.tags(data: data)
        
        #expect(tags == [
            FinderTag(name: "Red", color: .red),
            FinderTag(name: "Plain"),
            FinderTag(name: "Unknown"),
        ])
    }
    
    
    @Test func parseTagsFromInvalidExtendedAttributeData() {
        
        let tags = FinderTag.tags(data: Data("not a plist".utf8))
        
        #expect(tags.isEmpty)
    }
    
    
    private static func userTagsData(_ tags: [String]) throws -> Data {
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        return try encoder.encode(tags)
    }
}
