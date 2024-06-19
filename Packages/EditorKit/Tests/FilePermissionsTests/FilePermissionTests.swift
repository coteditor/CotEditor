//
//  FilePermissionTests.swift
//  FilePermissionTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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
@testable import FilePermissions

struct FilePermissionTests {
    
    @Test func filePermissions() {
        
        #expect(FilePermissions(mask: 0o777).mask == 0o777)
        #expect(FilePermissions(mask: 0o643).mask == 0o643)
        
        #expect(FilePermissions(mask: 0o777).symbolic == "rwxrwxrwx")
        #expect(FilePermissions(mask: 0o643).symbolic == "rw-r---wx")
        
        #expect(FilePermissions(mask: 0o777).description == "rwxrwxrwx")
        #expect(FilePermissions(mask: 0o643).description == "rw-r---wx")
    }
    
    
    @Test func formatStyle() {
        
        #expect(FilePermissions(mask: 0o777).formatted(.filePermissions(.full)) == "777 (-rwxrwxrwx)")
        #expect(FilePermissions(mask: 0o643).formatted(.filePermissions(.full)) == "643 (-rw-r---wx)")
        
        #expect(FilePermissions(mask: 0o643).formatted(.filePermissions(.octal)) == "643")
        #expect(FilePermissions(mask: 0o643).formatted() == "643 (-rw-r---wx)")
        #expect(FilePermissions(mask: 0o643).formatted(.filePermissions) == "643 (-rw-r---wx)")
    }
    
    
    @Test func calculate() {
        
        var permissions = FilePermissions(mask: 0o644)
        permissions.user.insert(.execute)
        
        #expect(permissions.user.contains(.execute))
        #expect(permissions.mask == 0o744)
    }
}
