//
//  EncodingTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-16.
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

import Foundation
import Testing
@testable import CotEditor

struct EncodingTests {
    
    @Test func encodeYen() throws {
        
        // encodings listed in faq_about_yen_backslash.html
        let ascii = try #require(CFStringEncodings(rawValue: CFIndex(CFStringBuiltInEncodings.ASCII.rawValue)))
        let inHelpCFEncodings: [CFStringEncodings] = [
            .dosJapanese,
            .EUC_JP,              // Japanese (EUC)
            .EUC_TW,              // Traditional Chinese (EUC)
            .EUC_CN,              // Simplified Chinese (GB 2312)
            .EUC_KR,              // Korean (EUC)
            .dosKorean,           // Korean (Windows, DOS)
            .dosThai,             // Thai (Windows, DOS)
            .isoLatinThai,        // Thai (ISO 8859-11)
            
            .macArabic,           // Arabic (Mac OS)
            .isoLatinArabic,      // Arabic (ISO 8859-6)
            .macHebrew,           // Hebrew (Mac OS)
            .isoLatinGreek,       // Greek (ISO 8859-7)
            .macCyrillic,         // Cyrillic (Mac OS)
            .isoLatinCyrillic,    // Cyrillic (ISO 8859-5)
            .windowsCyrillic,     // Cyrillic (Windows)
            .macCentralEurRoman,  // Central European (Mac OS)
            .isoLatin2,           // Central European (ISO Latin 2)
            .isoLatin3,           // Western (ISO Latin 3)
            .isoLatin4,           // Central European (ISO Latin 4)
            .dosLatinUS,          // Latin-US (DOS)
            .windowsLatin2,       // Central European (Windows Latin 2)
            .isoLatin6,           // Nordic (ISO Latin 6)
            .isoLatin7,           // Baltic (ISO Latin 7)
            .isoLatin8,           // Celtic (ISO Latin 8)
            .isoLatin10,          // Romanian (ISO Latin 10)
            .dosRussian,          // Russian (DOS)
            ascii,                // Western (ASCII)
        ]
        let inHelpEncodings = inHelpCFEncodings
            .map(\.rawValue)
            .map(CFStringEncoding.init)
            .map(String.Encoding.init(cfEncoding:))
        let availableEncodings = DefaultSettings.encodings
            .filter { $0 != kCFStringEncodingInvalidId }
            .map(String.Encoding.init(cfEncoding:))
        let yenIncompatibleEncodings = availableEncodings
            .filter { !"¥".canBeConverted(to: $0) }
        
        for encoding in yenIncompatibleEncodings {
            #expect(inHelpEncodings.contains(encoding), "\(String.localizedName(of: encoding))")
        }
        for encoding in inHelpEncodings {
            #expect(availableEncodings.contains(encoding), "\(String.localizedName(of: encoding))")
        }
    }
}
