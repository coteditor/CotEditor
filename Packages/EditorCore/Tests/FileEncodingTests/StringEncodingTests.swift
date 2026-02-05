//
//  StringEncodingTests.swift
//  FileEncodingTests
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
@testable import FileEncoding

struct StringEncodingTests {
    
    @Test func ianaCharsetName() {
        
        #expect(String.Encoding.utf8.ianaCharSetName == "utf-8")
        #expect(String.Encoding.isoLatin1.ianaCharSetName == "iso-8859-1")
    }
    
    
    @Test func encodeXattr() {
        
        let utf8Data = Data("utf-8;134217984".utf8)
        
        #expect(String.Encoding.utf8.xattrEncodingData == utf8Data)
        #expect(utf8Data.decodingXattrEncoding == .utf8)
        #expect(Data("utf-8".utf8).decodingXattrEncoding == .utf8)
        
        
        let eucJPData = Data("euc-jp;2336".utf8)
        
        #expect(String.Encoding.japaneseEUC.xattrEncodingData == eucJPData)
        #expect(eucJPData.decodingXattrEncoding == .japaneseEUC)
        #expect(Data("euc-jp".utf8).decodingXattrEncoding == .japaneseEUC)
    }
}
