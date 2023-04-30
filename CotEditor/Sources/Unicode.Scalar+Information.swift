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
//  © 2015-2023 1024jp
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
    
    /// Code point string in format like `U+000F`.
    var codePoint: String {
        
        String(format: "U+%04tX", self.value)
    }
    
    
    /// Code point pair in UTF-16 surrogate pair.
    var surrogateCodePoints: (lead: String, trail: String)? {
        
        guard self.isSurrogatePair else { return nil }
        
        return (String(format: "U+%04X", UTF16.leadSurrogate(self)),
                String(format: "U+%04X", UTF16.trailSurrogate(self)))
    }
    
    
    /// Boolean value indicating whether character becomes a surrogate pair in UTF-16.
    var isSurrogatePair: Bool {
        
        (UTF16.width(self) == 2)
    }
    
    
    /// Unicode name.
    var name: String? {
        
        self.properties.nameAlias
            ?? self.properties.name
            ?? self.controlCharacterName  // get control character name from special table
    }
    
    
    /// Unicode block name.
    var blockName: String? {
        
        self.value.blockName
    }
    
    
    /// Localized and sanitized unicode block name.
    var localizedBlockName: String? {
        
        guard let blockName else { return nil }
        
        // -> This is actually a dirty workaround to make the block name the same as the Apple's block naming rule.
        //    Otherwise, we cannot localize block names correctly. (2015-11)
        let key = blockName
            .replacingOccurrences(of: " ([A-Z])$", with: "-$1", options: .regularExpression)
            .replacingOccurrences(of: "Description", with: "Desc.")
        
        return String(localized: String.LocalizationValue(key), table: "Unicode")
    }
}



// MARK: -

extension UTF32.CodeUnit {
    
    /// Return Unicode name.
    ///
    /// Implemented at UTF32.CodeUnit level in order to cover single surrogate characters
    /// that are not allowed by Unicode.Scalar.
    var unicodeName: String? {
        
        if let name = Unicode.Scalar(self)?.name {
            return name
        }
        
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
}
