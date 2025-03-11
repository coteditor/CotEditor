//
//  Unicode.Scalar+Information.swift
//  CharacterInfo
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2025 1024jp
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

public extension Unicode.Scalar {
    
    /// The code point string in format like `U+000F`.
    var codePoint: String {
        
        String(format: "U+%04tX", self.value)
    }
    
    
    /// The code point pair in UTF-16 surrogate pair.
    var surrogateCodePoints: (lead: String, trail: String)? {
        
        guard self.isSurrogatePair else { return nil }
        
        return (String(format: "U+%04X", UTF16.leadSurrogate(self)),
                String(format: "U+%04X", UTF16.trailSurrogate(self)))
    }
    
    
    /// The Unicode name.
    var name: String? {
        
        self.properties.nameAlias
            ?? self.properties.name
            ?? self.controlCharacterName  // get control character name from special table
    }
    
    
    /// The Unicode block name defined in the Unicode.
    var blockName: String? {
        
        self.value.blockName
    }
    
    
    /// The localized Unicode block name.
    var localizedBlockName: String? {
        
        guard let blockName else { return nil }
        
        return localizeBlockName(blockName) ?? blockName
    }
}


extension Unicode.Scalar {
    
    /// Boolean value indicating whether character becomes a surrogate pair in UTF-16.
    var isSurrogatePair: Bool {
        
        (UTF16.width(self) == 2)
    }
}
