//
//  Unicode.Scalar+Information.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2020 1024jp
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

extension Unicode.Scalar {
    
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
        
        return self.value.unicodeName
    }
    
    
    /// Unicode block name
    var blockName: String? {
        
        return self.value.blockName
    }
    
    
    /// Localized and sanitized unicode block name
    var localizedBlockName: String? {
        
        guard let blockName = self.blockName else { return nil }
        
        return UInt32.appleUnicodeBlockName(for: blockName).localized(tableName: "Unicode")
    }
    
}



// MARK: -

// implement Unicode functions at UInt32 level in order to cover single surrogate characters that are not allowed by Unicode.Scalar

extension UInt32 {
    
    /// get Unicode name
    var unicodeName: String? {
        
        let scalar = Unicode.Scalar(self)
        
        // get Unicode name from property
        if let properties = scalar?.properties,
           let name = properties.nameAlias ?? properties.name
        {
            return name
        }
        
        // get control character name from special table
        if let name = scalar?.controlCharacterName {
            return name
        }
        
        // create single surrogate character by ownself
        if let codeUnit = UTF16.CodeUnit(exactly: self) {
            if UTF16.isLeadSurrogate(codeUnit) {
                return "<lead surrogate-" + String(format: "%04X", self) + ">"
            }
            if UTF16.isTrailSurrogate(codeUnit) {
                return "<tail surrogate-" + String(format: "%04X", self) + ">"
            }
        }
        
        return nil
    }
    
    
    /// Unicode block name
    var blockName: String? {
        
        return UInt32.blockNameTable.first { $0.key.contains(self) }?.value
    }
    
    
    /// sanitize block name for localization
    static func appleUnicodeBlockName(for blockName: String) -> String {
        
        // -> This is actually a dirty workaround to make the block name the same as the Apple's block naming rule.
        //    Otherwise, we cannot localize block names correctly. (2015-11)
        
        return blockName
            .replacingOccurrences(of: " ([A-Z])$", with: "-$1", options: .regularExpression)
            .replacingOccurrences(of: "Mathematical", with: "Math")
            .replacingOccurrences(of: "Supplement", with: "Supp.")
            .replacingOccurrences(of: "Description", with: "Desc.")
    }
    
}
