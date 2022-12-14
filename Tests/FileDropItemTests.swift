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

import XCTest
@testable import CotEditor

final class FileDropItemTests: XCTestCase {

    func testAvailability() {
        
        let emptyItem = FileDropItem()
        XCTAssertTrue(emptyItem.supports(extension: "JPG", scope: "foo"))
        XCTAssertTrue(emptyItem.supports(extension: "jpg", scope: nil))
        XCTAssertTrue(emptyItem.supports(extension: nil, scope: ""))
        XCTAssertTrue(emptyItem.supports(extension: nil, scope: nil))
        
        let extensionItem = FileDropItem(format: "", extensions: ["jpg", "JPEG"])
        XCTAssertTrue(extensionItem.supports(extension: "JPG", scope: "foo"))
        XCTAssertTrue(extensionItem.supports(extension: "JPG", scope: nil))
        XCTAssertFalse(extensionItem.supports(extension: "gif", scope: "foo"))
        XCTAssertFalse(extensionItem.supports(extension: nil, scope: "foo"))
        XCTAssertFalse(extensionItem.supports(extension: nil, scope: nil))
        
        let scopeItem = FileDropItem(format: "", scope: "foo")
        XCTAssertTrue(scopeItem.supports(extension: "JPG", scope: "foo"))
        XCTAssertTrue(scopeItem.supports(extension: "gif", scope: "foo"))
        XCTAssertTrue(scopeItem.supports(extension: nil, scope: "foo"))
        XCTAssertFalse(scopeItem.supports(extension: nil, scope: "bar"))
        XCTAssertFalse(scopeItem.supports(extension: "JPG", scope: nil))
        XCTAssertFalse(scopeItem.supports(extension: nil, scope: nil))
        
        let item = FileDropItem(format: "", extensions: ["jpg", "JPEG"], scope: "foo")
        XCTAssertTrue(item.supports(extension: "JPG", scope: "foo"))
        XCTAssertTrue(item.supports(extension: "jpeg", scope: "foo"))
        XCTAssertFalse(item.supports(extension: "gif", scope: "foo"))
        XCTAssertFalse(item.supports(extension: nil, scope: "foo"))
        XCTAssertFalse(item.supports(extension: nil, scope: "bar"))
        XCTAssertFalse(item.supports(extension: "JPG", scope: nil))
        XCTAssertFalse(item.supports(extension: nil, scope: nil))
    }
}
