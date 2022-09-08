//
//  String+Normalization.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-08-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2022 1024jp
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

enum UnicodeNormalizationForm: String {
    
    case nfd
    case nfc
    case nfkd
    case nfkc
    case nfkcCasefold
    case modifiedNFD
    case modifiedNFC
    
    static let standardForms: [Self] = [.nfd, .nfc, .nfkd, .nfkc, .nfkcCasefold]
    static let modifiedForms: [Self] = [.modifiedNFD, .modifiedNFC]
    
    
    private static let localizationTable = "UnicodeNormalization"
    
    
    /// Localized name.
    var localizedName: String {
        
        let key: String
        switch self {
            case .nfd:
                key = "NFD"
            case .nfc:
                key = "NFC"
            case .nfkd:
                key = "NFKD"
            case .nfkc:
                key = "NFKC"
            case .nfkcCasefold:
                key = "NFKC Casefold"
            case .modifiedNFD:
                key = "Modified NFD"
            case .modifiedNFC:
                key = "Modified NFC"
        }
        return key.localized(tableName: Self.localizationTable)
    }
    
    
    /// Localized description for user.
    var localizedDescription: String {
        
        let table = Self.localizationTable
        switch self {
            case .nfd:
                return "Canonical Decomposition"
                    .localized(tableName: table, comment: "description for NFD")
            case .nfc:
                return "Canonical Decomposition, followed by Canonical Composition"
                    .localized(tableName: table, comment: "description for NFC")
            case .nfkd:
                return "Compatibility Decomposition"
                    .localized(tableName: table, comment: "description for NFKD")
            case .nfkc:
                return "Compatibility Decomposition, followed by Canonical Composition"
                    .localized(tableName: table, comment: "description for NFKC")
            case .nfkcCasefold:
                return "Applying NFKC, CaseFolding, and removal of default-ignorable code points"
                    .localized(tableName: table, comment: "description for NFKD Casefold")
            case .modifiedNFD:
                return "Unofficial NFD-based normalization form used in HFS+"
                    .localized(tableName: table, comment: "description for Modified NFD")
            case .modifiedNFC:
                return "Unofficial NFC-based normalization form corresponding to Modified NFD"
                    .localized(tableName: table, comment: "description for Modified NFC")
        }
    }
}


extension StringProtocol {
    
    func normalize(in form: UnicodeNormalizationForm) -> String {
        
        switch form {
            case .nfd:
                return self.decomposedStringWithCanonicalMapping
            case .nfc:
                return self.precomposedStringWithCanonicalMapping
            case .nfkd:
                return self.decomposedStringWithCompatibilityMapping
            case .nfkc:
                return self.precomposedStringWithCompatibilityMapping
            case .nfkcCasefold:
                return self.precomposedStringWithCompatibilityMappingWithCasefold
            case .modifiedNFD:
                return String(self).decomposedStringWithHFSPlusMapping
            case .modifiedNFC:
                return String(self).precomposedStringWithHFSPlusMapping
        }
    }
    
}


extension StringProtocol {
    
    /// A string made by normalizing the receiver’s contents using the Unicode Normalization Form KC with Casefold a.k.a. NFKC_Casefold or NFKC_CF.
    var precomposedStringWithCompatibilityMappingWithCasefold: String {
        
        self.precomposedStringWithCompatibilityMapping
            .folding(options: .caseInsensitive, locale: nil)
    }
}


extension String {
    
    // MARK: Public Properties
    
    /// A string made by normalizing the receiver’s contents using the normalization form adopted by HFS+, a.k.a. Apple Modified NFC.
    var precomposedStringWithHFSPlusMapping: String {
        
        let exclusionCharacters = "\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}"
        let regex = try! NSRegularExpression(pattern: "[^" + exclusionCharacters + "]+")
        
        let mutable = NSMutableString(string: self)
        
        return regex.matches(in: self, range: self.nsRange)
            .map(\.range)
            .reversed()
            .reduce(into: mutable) { $0.replaceCharacters(in: $1, with: $0.substring(with: $1).precomposedStringWithCanonicalMapping) } as String
    }
    
    
    /// A string made by normalizing the receiver’s contents using the normalization form adopted by HFS+, a.k.a. Apple Modified NFD.
    var decomposedStringWithHFSPlusMapping: String {
        
        let length = CFStringGetMaximumSizeOfFileSystemRepresentation(self as CFString)
        var buffer = [CChar](repeating: 0, count: length)
        
        guard CFStringGetFileSystemRepresentation(self as CFString, &buffer, length) else { return self }
        
        return String(cString: buffer)
    }
    
}
