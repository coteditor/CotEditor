/*
 
 UnicodeScalar+Information.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-07-26.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation
import ICU

extension UnicodeScalar {
    
    /// code point string in format like `U+000F`
    var codePoint: String {
        
        return String(format: "U+%04tX", self.value)
    }
    
    
    /// code point pair in UTF-16 surrogate pair
    var surrogateCodePoints: [String]? {
        
        guard self.isSurrogatePair else { return nil }
        
        return [String(format: "U+%04X", UTF16.leadSurrogate(self)),
                String(format: "U+%04X", UTF16.trailSurrogate(self))]
    }
    
    
    /// if character becomes a surrogate pair in UTF-16
    var isSurrogatePair: Bool {
        
        return (UTF16.width(self) == 2)
    }
    
    
    /// Unicode name
    var name: String? {
        
        return UTF32Char(self.value).unicodeName
    }
    
    
    /// Unicode category name just returned from the ICU function
    var categoryName: String? {
        
        return UTF32Char(self.value).categoryName
    }
    
    
    /// Unicode block name just returned from the ICU function
    var blockName: String? {
        
        return UTF32Char(self.value).blockName
    }
    
    
    /// Localized and sanitized unicode block name
    var localizedBlockName: String? {
        
        guard let blockName = self.blockName else { return nil }
        
        return NSLocalizedString(sanitize(blockName: blockName), tableName: "Unicode", comment: "")
    }
    
}



// MARK: -

// Implemented Unicode functions at UTF32Char level in order to cover single surrogate character that is not allowed by UnicodeScalar

extension UTF32Char {
    
    /// get Unicode name
    var unicodeName: String? {
        
        if let name = self.controlCharacterName {
            return name
        }
        
        return self.name(for: U_UNICODE_CHAR_NAME) ?? self.name(for: U_EXTENDED_CHAR_NAME)
        // -> `U_UNICODE_CHAR_NAME` returns modern Unicode name however it doesn't support surrogate character names.
        //    `U_EXTENDED_CHAR_NAME` returns lowercase name within angle brackets like "<lead surrogate-D83D>".
        //    Therefore, we combinate `U_UNICODE_CHAR_NAME` and `U_EXTENDED_CHAR_NAME`.
    }
    
    
    /// Unicode category name just returned from the ICU function
    var categoryName: String? {
        
        return self.property(for: UCHAR_GENERAL_CATEGORY)
    }
    
    
    /// Unicode block name just returned from the ICU function
    var blockName: String? {
        
        return self.property(for: UCHAR_BLOCK)
    }
    
    
    
    // MARK: Private Methods
    
    /// get character name with name type
    private func name(for type: UCharNameChoice) -> String? {
        
        var buffer = [CChar](repeating: 0, count: 128)
        var error = U_ZERO_ERROR
        u_charName(UChar32(self), type, &buffer, 128, &error)
        
        guard error == U_ZERO_ERROR,
            let name = String(utf8String: buffer), !name.isEmpty else { return nil }
        
        return name
    }
    
    
    /// get Unicode property for property key
    private func property(for property: UProperty) -> String? {
        
        let prop = u_getIntPropertyValue(UChar32(self), property)
        guard let name = u_getPropertyValueName(property, prop, U_LONG_PROPERTY_NAME) else { return nil }
        
        return String(cString: name).replacingOccurrences(of: "_", with: " ")
    }
    
}



// MARK: - Block Name Sanitizing

/// sanitize block name for localization
private func sanitize(blockName: String) -> String {
    
    // -> This is actually a dirty workaround to make the block name the same as the Apple's block naming rule.
    //    Otherwise, we cannot localize block name correctly. (2015-11 by 1024jp)
    
    return blockName
        .replacingOccurrences(of: " ([A-Z])$", with: "-$1", options: .regularExpression)
        .replacingOccurrences(of: "Extension-", with: "Ext. ")
        .replacingOccurrences(of: " And ", with: " and ")
        .replacingOccurrences(of: " For ", with: " for ")
        .replacingOccurrences(of: " Mathematical ", with: " Math ")
        .replacingOccurrences(of: "Supplementary ", with: "Supp. ")
        .replacingOccurrences(of: "Latin 1", with: "Latin-1")  // only for "Latin-1
}


/// check which block names will be lozalized (only for test use)
private func testUnicodeBlockNameLocalization(for language: String = "ja") {
    
    let bundleURL = Bundle.main.url(forResource: language, withExtension: "lproj")!
    let bundle = Bundle(url: bundleURL)
    
    for index in 0..<UBLOCK_COUNT.rawValue {
        let blockNameChars = u_getPropertyValueName(UCHAR_BLOCK, index, U_LONG_PROPERTY_NAME)!
        
        var blockName = String(cString: blockNameChars).replacingOccurrences(of: "_", with: " ")  // sanitize
        blockName = sanitize(blockName: blockName)
        
        let localizedBlockName = bundle?.localizedString(forKey: blockName, value: nil, table: "Unicode")
        
        print((localizedBlockName == blockName) ? "⚠️" : "  ", blockName, localizedBlockName!, separator: "\t")
    }
}
