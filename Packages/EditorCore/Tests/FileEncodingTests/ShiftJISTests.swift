//
//  ShiftJISTests.swift
//  FileEncodingTests
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

import Foundation
import Testing
@testable import FileEncoding

struct ShiftJISTests {
    
    @Test func ianaCharSetNames() {
        
        #expect(ShiftJIS.shiftJIS.ianaCharSet == "shift_jis")
        #expect(ShiftJIS.shiftJIS_X0213.ianaCharSet == "Shift_JIS")
        #expect(ShiftJIS.macJapanese.ianaCharSet == "x-mac-japanese")
        #expect(ShiftJIS.dosJapanese.ianaCharSet == "cp932")
        
        #expect(ShiftJIS(ianaCharSetName: ShiftJIS.shiftJIS.ianaCharSet!) == .shiftJIS)
        #expect(ShiftJIS(ianaCharSetName: ShiftJIS.shiftJIS_X0213.ianaCharSet!) == .shiftJIS)
    }
    
    
    @Test func encodeTilde() {
        
        #expect(ShiftJIS.shiftJIS.encode("~") == "?")
        #expect(ShiftJIS.shiftJIS_X0213.encode("~") == "〜")
        #expect(ShiftJIS.macJapanese.encode("~") == "~")
        #expect(ShiftJIS.dosJapanese.encode("~") == "~")
    }
    
    
    @Test func encodeBackslash() {
        
        #expect(ShiftJIS.shiftJIS.encode("\\") == "＼")
        #expect(ShiftJIS.shiftJIS_X0213.encode("\\") == "＼")
        #expect(ShiftJIS.macJapanese.encode("\\") == "\\")
        #expect(ShiftJIS.dosJapanese.encode("\\") == "\\")
    }
    
    
    @Test func encodeYen() {
        
        #expect(ShiftJIS.shiftJIS.encode("¥") == "¥")
        #expect(ShiftJIS.shiftJIS_X0213.encode("¥") == "¥")
        #expect(ShiftJIS.macJapanese.encode("¥") == "¥")
        #expect(ShiftJIS.dosJapanese.encode("¥") == "?")
    }
    
    
    @Test func convertYen() {
        
        #expect("¥".convertYenSign(for: ShiftJIS.shiftJIS.encoding) == "¥")
        #expect("¥".convertYenSign(for: ShiftJIS.shiftJIS_X0213.encoding) == "¥")
        #expect("¥".convertYenSign(for: ShiftJIS.macJapanese.encoding) == "¥")
        #expect("¥".convertYenSign(for: ShiftJIS.dosJapanese.encoding) == "\\")
    }
    
    
    @Test(arguments: ShiftJIS.allCases)
    private func convertYen(shiftJIS: ShiftJIS) {
        
        #expect(("¥".convertYenSign(for: shiftJIS.encoding) == "¥") == (shiftJIS.encode("¥") == "¥"))
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
