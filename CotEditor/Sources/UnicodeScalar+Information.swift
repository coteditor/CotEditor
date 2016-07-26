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
    
    /// initialize only if code point is in valid range for a UnicodeScalar
    init?(codePoint: UInt32) {
        
        let surrogateRange = UInt32(0xD800)...UInt32(0xDFFF)  // high- and low-surrogate code points are not valid Unicode scalar values
        let codeSpaceEdge: UInt32 = 0x10FFFF  // value is outside of Unicode codespace
        
        guard !surrogateRange.contains(codePoint) && codePoint <= codeSpaceEdge else { return nil }
        
        self.init(codePoint)
    }
    
    
    /// code point string in format like `U+000F`
    var codePoint: String {
        
        return String(format: "U+%04tX", self.value)
    }
    
    
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
