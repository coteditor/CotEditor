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
    
    // Keep localized encoding name lookup and sorting together because concurrent calls can crash in Foundation.
    @Suite(.serialized) struct LocalizedNameTests {
        
        @Test(arguments: [String.Encoding.utf8, .shiftJIS, .iso2022JP])
        func encodingName(encoding: String.Encoding) {
            
            let localizedName = String.localizedName(of: encoding)
            
            #expect(String.Encoding(localizedName: localizedName) == encoding)
        }
        
        
        @Test func invalidEncodingName() {
            
            #expect(String.Encoding(localizedName: "") == nil)
            #expect(String.Encoding(localizedName: "🐕") == nil)
        }
        
        
        /// Checks the sorted encoding list, which also looks up localized encoding names.
        @Test func sortedAvailableStringEncodings() {
            
            let encodings = String.sortedAvailableStringEncodings
            let compact = encodings.compactMap(\.self)
            
            #expect(encodings.contains(nil))
            #expect(compact.count == String.availableStringEncodings.count)
        }
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
    
    
    /// Checks the characters that stop `data(using:allowLossyConversion:)`.
    ///
    /// - Parameters:
    ///   - string: The string to encode.
    ///   - encoding: The text encoding to convert to.
    ///   - bytes: The expected bytes.
    @Test(arguments: [
        ("あ\u{3099}", String.Encoding.shiftJIS, [0x3F]),
        ("a\u{0301}\u{0301}b", String.Encoding.isoLatin1, [0xE1, 0x3F, 0x62]),
        ("\u{FFFE}a", String.Encoding(cfEncoding: CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)), [0x3F, 0x61]),
    ] as [(String, String.Encoding, [UInt8])])
    func lossyData(string: String, encoding: String.Encoding, bytes: [UInt8]) {
        
        #expect(string.lossyData(using: encoding) == Data(bytes))
    }
}
