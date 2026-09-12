//
//  StringEncodingIANACharSetTests.swift
//  FileEncodingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-09-11.
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

struct StringEncodingIANACharSetTests {
    
    @Test func ianaCharsetName() {
        
        #expect(String.Encoding(ianaCharSetName: "iso-8859-2") == .isoLatin2)
        
        #expect(String.Encoding.utf8.ianaCharSetName == "utf-8")
        #expect(String.Encoding.isoLatin1.ianaCharSetName == "iso-8859-1")
    }
    
    
    /// Checks names that both IANA initializers resolve to the same encoding.
    ///
    /// - Parameters:
    ///   - name: The charset name to look up.
    ///   - encoding: The expected encoding.
    @available(macOS 26.4, *)
    @Test(arguments: [
        ("UTF-8", String.Encoding.utf8),
        ("uTf-8", .utf8),
        ("ISO-8859-2", .isoLatin2),
        ("iso-2022-jp", .iso2022JP),
    ])
    func matchingIANACharSetNames(name: String, encoding: String.Encoding) {
        
        #expect(String.Encoding(ianaCharSetName: name) == encoding)
        #expect(String.Encoding(ianaName: name) == encoding)
    }
    
    
    /// Checks charset names supported by the independent initializer but not by Foundation.
    ///
    /// - Parameters:
    ///   - name: The charset name to look up.
    ///   - cfEncoding: The expected Core Foundation encoding.
    @available(macOS 26.4, *)
    @Test(arguments: [
        ("GB18030", CFStringEncodings.GB_18030_2000),
        ("Big5", .big5),
        ("KOI8-R", .KOI8_R),
        ("ISO-8859-15", .isoLatin9),
        ("cp932", .dosJapanese),
        ("x-mac-japanese", .macJapanese),
    ])
    func additionalIANACharSetNames(name: String, cfEncoding: CFStringEncodings) {
        
        let encoding = String.Encoding(cfEncoding: CFStringEncoding(cfEncoding.rawValue))
        
        #expect(String.Encoding(ianaCharSetName: name) == encoding)
        #expect(String.Encoding(ianaName: name) == nil)
    }
    
    
    /// Checks aliases accepted by Foundation but not by the independent initializer.
    ///
    /// - Parameter name: An alias of ISO Latin 1.
    @available(macOS 26.4, *)
    @Test(arguments: ["latin1", "csISOLatin1"])
    func foundationIANACharSetAliases(name: String) {
        
        #expect(String.Encoding(ianaCharSetName: name) == nil)
        #expect(String.Encoding(ianaName: name) == .isoLatin1)
    }
    
    
    /// Checks that the initializers select different Shift JIS variants.
    ///
    /// - Parameter name: A case variant of the Shift JIS charset name.
    /// - Throws: If the independent initializer cannot resolve the name.
    @available(macOS 26.4, *)
    @Test(arguments: ["shift_jis", "Shift_JIS", "SHIFT_JIS"])
    func shiftJISIANACharSetNames(name: String) throws {
        
        let encoding = try #require(String.Encoding(ianaCharSetName: name))
        let cfEncoding = CFStringEncodings(rawValue: CFIndex(encoding.cfEncoding))
        
        // Either Core Foundation Shift JIS variant can be the first name match.
        #expect(cfEncoding == .shiftJIS || cfEncoding == .shiftJIS_X0213)
        // Foundation's .shiftJIS corresponds to Windows CP932.
        #expect(String.Encoding(ianaName: name) == .shiftJIS)
    }
    
    
    /// Checks that both IANA initializers reject invalid names.
    ///
    /// - Parameter name: An invalid charset name.
    @available(macOS 26.4, *)
    @Test(arguments: ["", "🐕", "not-an-encoding"])
    func invalidIANACharSetNames(name: String) {
        
        #expect(String.Encoding(ianaCharSetName: name) == nil)
        #expect(String.Encoding(ianaName: name) == nil)
    }
}
