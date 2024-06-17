//
//  FileDropItemTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-10-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

import Testing
@testable import CotEditor

struct FileDropItemTests {
    
    @Test func emptyAvailability() {
        
        let item = FileDropItem()
        #expect(item.supports(extension: "JPG", scope: "foo"))
        #expect(item.supports(extension: "jpg", scope: nil))
        #expect(item.supports(extension: nil, scope: ""))
        #expect(item.supports(extension: nil, scope: nil))
    }
    
    
    @Test func extensionAvailability() {
        
        let item = FileDropItem(format: "", extensions: ["jpg", "JPEG"])
        #expect(item.supports(extension: "JPG", scope: "foo"))
        #expect(item.supports(extension: "JPG", scope: nil))
        #expect(!item.supports(extension: "gif", scope: "foo"))
        #expect(!item.supports(extension: nil, scope: "foo"))
        #expect(!item.supports(extension: nil, scope: nil))
    }
    
    
    @Test func scopeAvailability() {
        
        let item = FileDropItem(format: "", scope: "foo")
        #expect(item.supports(extension: "JPG", scope: "foo"))
        #expect(item.supports(extension: "gif", scope: "foo"))
        #expect(item.supports(extension: nil, scope: "foo"))
        #expect(!item.supports(extension: nil, scope: "bar"))
        #expect(!item.supports(extension: "JPG", scope: nil))
        #expect(!item.supports(extension: nil, scope: nil))
    }
    
    
    @Test func mixAvailability() {
        
        let item = FileDropItem(format: "", extensions: ["jpg", "JPEG"], scope: "foo")
        #expect(item.supports(extension: "JPG", scope: "foo"))
        #expect(item.supports(extension: "jpeg", scope: "foo"))
        #expect(!item.supports(extension: "gif", scope: "foo"))
        #expect(!item.supports(extension: nil, scope: "foo"))
        #expect(!item.supports(extension: nil, scope: "bar"))
        #expect(!item.supports(extension: "JPG", scope: nil))
        #expect(!item.supports(extension: nil, scope: nil))
    }
}
