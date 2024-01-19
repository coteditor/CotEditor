//
//  ShiftJISTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-01-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

final class ShiftJISTests: XCTestCase {
    
    func testIANACharSetNames() {
        
        XCTAssertEqual(ShiftJIS.shiftJIS.ianaCharSet, "shift_jis")
        XCTAssertEqual(ShiftJIS.shiftJIS_X0213.ianaCharSet, "Shift_JIS")
        XCTAssertEqual(ShiftJIS.macJapanese.ianaCharSet, "x-mac-japanese")
        XCTAssertEqual(ShiftJIS.dosJapanese.ianaCharSet, "cp932")
        
        XCTAssertEqual(ShiftJIS(ianaCharSetName: ShiftJIS.shiftJIS.ianaCharSet!), .shiftJIS)
        XCTAssertEqual(ShiftJIS(ianaCharSetName: ShiftJIS.shiftJIS_X0213.ianaCharSet!), .shiftJIS)
    }
    
    
    func testTildaEncoding() {
        
        XCTAssertEqual(ShiftJIS.shiftJIS.encode("~"), "?")
        XCTAssertEqual(ShiftJIS.shiftJIS_X0213.encode("~"), "〜")
        XCTAssertEqual(ShiftJIS.macJapanese.encode("~"), "~")
        XCTAssertEqual(ShiftJIS.dosJapanese.encode("~"), "~")
    }
    
    
    func testBackslashEncoding() {
        
        XCTAssertEqual(ShiftJIS.shiftJIS.encode("\\"), "＼")
        XCTAssertEqual(ShiftJIS.shiftJIS_X0213.encode("\\"), "＼")
        XCTAssertEqual(ShiftJIS.macJapanese.encode("\\"), "\\")
        XCTAssertEqual(ShiftJIS.dosJapanese.encode("\\"), "\\")
    }
    
    
    func testYenEncoding() {
        
        XCTAssertEqual(ShiftJIS.shiftJIS.encode("¥"), "¥")
        XCTAssertEqual(ShiftJIS.shiftJIS_X0213.encode("¥"), "¥")
        XCTAssertEqual(ShiftJIS.macJapanese.encode("¥"), "¥")
        XCTAssertEqual(ShiftJIS.dosJapanese.encode("¥"), "?")
    }
    
    
    func testYenConversion() {
        
        XCTAssertEqual("¥".convertYenSign(for: ShiftJIS.shiftJIS.encoding), "¥")
        XCTAssertEqual("¥".convertYenSign(for: ShiftJIS.shiftJIS_X0213.encoding), "¥")
        XCTAssertEqual("¥".convertYenSign(for: ShiftJIS.macJapanese.encoding), "¥")
        XCTAssertEqual("¥".convertYenSign(for: ShiftJIS.dosJapanese.encoding), "\\")
        
        ShiftJIS.allCases
            .forEach { XCTAssertEqual("¥".convertYenSign(for: $0.encoding) == "¥", $0.encode("¥") == "¥") }
    }
}


// MARK: -

private enum ShiftJIS: CaseIterable {
    
    case shiftJIS        // Japanese (Shift JIS)
    case shiftJIS_X0213  // Japanese (Shift JIS X0213)
    case macJapanese     // Japanese (Mac OS)
    case dosJapanese     // Japanese (Windows, DOS)
    
    
    var cfEncodings: CFStringEncodings {
        
        switch self {
            case .shiftJIS: .shiftJIS
            case .dosJapanese: .dosJapanese
            case .shiftJIS_X0213: .shiftJIS_X0213
            case .macJapanese: .macJapanese
        }
    }
    
    
    var cfEncoding: CFStringEncoding {
        
        CFStringEncoding(self.cfEncodings.rawValue)
    }
    
    
    var encoding: String.Encoding {
        
        String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(self.cfEncoding))
    }
    
    
    var ianaCharSet: String? {
        
        CFStringConvertEncodingToIANACharSetName(self.cfEncoding) as String?
    }
    
    
    var localizedString: String {
        
        String.localizedName(of: self.encoding)
    }
    
    
    func encode(_ string: String) -> String? {
        
        String(data: string.data(using: self.encoding, allowLossyConversion: true)!, encoding: self.encoding)
    }
}


private extension ShiftJIS {
    
    init?(ianaCharSetName: String) {
        
        let encoding = CFStringConvertIANACharSetNameToEncoding(ianaCharSetName as CFString)
        
        guard let shiftJIS = Self.allCases.first(where: { $0.cfEncoding == encoding }) else { return nil }
        
        self = shiftJIS
    }
}
