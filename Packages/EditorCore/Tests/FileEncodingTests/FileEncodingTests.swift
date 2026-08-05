//
//  FileEncodingTests.swift
//  FileEncodingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-08-05.
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
@testable import FileEncoding

struct FileEncodingTests {
    
    /// Tests file encodings that include a BOM.
    ///
    /// - Parameter fileEncoding: The file encoding to test.
    @Test(arguments: [
        FileEncoding(encoding: .utf8, withUTF8BOM: true),
        FileEncoding(encoding: .utf16),
        FileEncoding(encoding: .utf32),
    ])
    func hasBOM(fileEncoding: FileEncoding) {
        
        #expect(fileEncoding.hasBOM)
    }
    
    
    /// Tests file encodings that do not include a BOM.
    ///
    /// - Parameter encoding: The string encoding to test.
    @Test(arguments: [
        String.Encoding.utf8,
        .utf16BigEndian,
        .utf16LittleEndian,
        .utf32BigEndian,
        .utf32LittleEndian,
        .shiftJIS,
    ])
    func hasNoBOM(encoding: String.Encoding) {
        
        #expect(!FileEncoding(encoding: encoding).hasBOM)
    }
}
