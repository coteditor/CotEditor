//
//  CharacterInfo.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-19.
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

private extension Unicode.Scalar {
    
    enum EmojiVariationSelector {
        
        static let text = Unicode.Scalar(0xFE0E)!
        static let emoji = Unicode.Scalar(0xFE0F)!
    }
    
    enum SkinToneModifier {
        
        static let type12 = Unicode.Scalar(0x1F3FB)!  // 🏻 Light
        static let type3 = Unicode.Scalar(0x1F3FC)!  // 🏼 Medium Light
        static let type4 = Unicode.Scalar(0x1F3FD)!  // 🏽 Medium
        static let type5 = Unicode.Scalar(0x1F3FE)!  // 🏾 Medium Dark
        static let type6 = Unicode.Scalar(0x1F3FF)!  // 🏿 Dark
    }
    
    
    var variantDescription: String? {
        
        switch self {
            case EmojiVariationSelector.emoji:
                return String(localized: "Emoji Style", table: "Unicode")
            case EmojiVariationSelector.text:
                return String(localized: "Text Style", table: "Unicode")
            case SkinToneModifier.type12:
                return String(localized: "Skin Tone I-II", table: "Unicode")
            case SkinToneModifier.type3:
                return String(localized: "Skin Tone III", table: "Unicode")
            case SkinToneModifier.type4:
                return String(localized: "Skin Tone IV", table: "Unicode")
            case SkinToneModifier.type5:
                return String(localized: "Skin Tone V", table: "Unicode")
            case SkinToneModifier.type6:
                return String(localized: "Skin Tone VI", table: "Unicode")
            case _ where self.properties.isVariationSelector:
                return String(localized: "Variant", table: "Unicode")
            default:
                return nil
        }
    }
}



// MARK: -

struct CharacterInfo {
    
    // MARK: Public Properties
    
    var character: Character
    
    
    // MARK: Public Methods
    
    var localizedDescription: String? {
        
        let unicodes = self.character.unicodeScalars
        if self.isComplex {
            return String(localized: "<a letter consisting of \(unicodes.count) characters>", table: "Unicode")
        }
        
        guard var unicodeName = unicodes.first?.name else { return nil }
        
        if self.isVariant, let variantDescription = unicodes.last?.variantDescription {
            unicodeName += String(localized: " (\(variantDescription))")
        }
        
        return unicodeName
    }
    
    
    var pictureCharacter: Character? {
        
        self.character.unicodeScalars.count == 1  // ignore CRLF
            ? self.character.unicodeScalars.first?.pictureRepresentation.flatMap(Character.init)
            : nil
    }
    
    
    var isComplex: Bool {
        
        self.character.unicodeScalars.count > 1 && !self.isVariant
    }
    
    
    // MARK: Private Methods
    
    private var isVariant: Bool {
        
        (self.character.unicodeScalars.count == 2 &&
         self.character.unicodeScalars.last?.variantDescription != nil)
    }
}



extension CharacterInfo: CustomStringConvertible {
    
    var description: String {
        
        String(self.character)
    }
}
