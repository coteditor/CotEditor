//
//  FormattersTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2018 1024jp
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

final class FormattersTests: XCTestCase {
    
    func testFilePermissions() {
        
        XCTAssertEqual(FilePermissions(mask: 0o777).mask, 0o777)
        XCTAssertEqual(FilePermissions(mask: 0o643).mask, 0o643)
        
        XCTAssertEqual(FilePermissions(mask: 0o777).humanReadable, "rwxrwxrwx")
        XCTAssertEqual(FilePermissions(mask: 0o643).humanReadable, "rw-r---wx")
    }
    

    func testFilePermissionsFormatter() {
        
        let formatter = FilePermissionsFormatter()
        
        XCTAssertEqual(formatter.string(for: 0o777 as NSNumber), "777 (-rwxrwxrwx)")
        XCTAssertEqual(formatter.string(for: 0o643 as NSNumber), "643 (-rw-r---wx)")
    }

}
