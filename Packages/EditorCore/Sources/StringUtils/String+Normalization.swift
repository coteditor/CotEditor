//
//  String+Normalization.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-08-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2026 1024jp
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

public enum UnicodeNormalizationForm: String, Sendable, CaseIterable {
    
    case nfd
    case nfc
    case nfkd
    case nfkc
    case nfkcCaseFold
    case modifiedNFD
    case modifiedNFC
    
    public static let standardForms: [Self] = [.nfd, .nfc, .nfkd, .nfkc, .nfkcCaseFold]
    public static let modifiedForms: [Self] = [.modifiedNFD, .modifiedNFC]
}


public extension StringProtocol {
    
    /// Returns a string created by normalizing the string using the specified form.
    ///
    /// - Parameter form: The Unicode normalization form.
    /// - Returns: A normalized string.
    func normalizing(in form: UnicodeNormalizationForm) -> String {
        
        switch form {
            case .nfd:
                self.decomposedStringWithCanonicalMapping
            case .nfc:
                self.precomposedStringWithCanonicalMapping
            case .nfkd:
                self.decomposedStringWithCompatibilityMapping
            case .nfkc:
                self.precomposedStringWithCompatibilityMapping
            case .nfkcCaseFold:
                String(self).precomposedStringWithCompatibilityMappingWithCaseFold
            case .modifiedNFD:
                String(self).decomposedStringWithHFSPlusMapping
            case .modifiedNFC:
                String(self).precomposedStringWithHFSPlusMapping
        }
    }
}


// MARK: -

extension String {
    
    /// A string made by normalizing the receiver’s content using the Unicode Normalization Form KC with case-fold a.k.a. `NFKC_Casefold` or `NFKC_CF`.
    var precomposedStringWithCompatibilityMappingWithCaseFold: String {
        
        self.removingDefaultIgnorableCodePoints
            .precomposedStringWithCompatibilityMapping
            .folding(options: .caseInsensitive, locale: nil)
            .precomposedStringWithCanonicalMapping
            .removingDefaultIgnorableCodePoints
    }
    
    
    /// A string made by removing default-ignorable code points from the receiver’s content.
    private var removingDefaultIgnorableCodePoints: String {
        
        self.replacing(/\p{Default_Ignorable_Code_Point}+/.matchingSemantics(.unicodeScalar), with: "")
    }
}


extension String {
    
    /// A string made by normalizing the receiver’s content using the normalization form adopted by HFS+, a.k.a. Apple Modified NFC.
    var precomposedStringWithHFSPlusMapping: String {
        
        self.replacing(/\P{Full_Composition_Exclusion}+/.matchingSemantics(.unicodeScalar),
                       with: \.output.precomposedStringWithCanonicalMapping)
    }
    
    
    /// A string made by normalizing the receiver’s content using the normalization form adopted by HFS+, a.k.a. Apple Modified NFD.
    var decomposedStringWithHFSPlusMapping: String {
        
        let length = CFStringGetMaximumSizeOfFileSystemRepresentation(self as CFString)
        
        return withUnsafeTemporaryAllocation(of: CChar.self, capacity: length) { buffer in
            guard unsafe CFStringGetFileSystemRepresentation(self as CFString, buffer.baseAddress, buffer.count) else { return self }
            
            return unsafe String(validatingCString: buffer.baseAddress!) ?? self
        }
    }
}
