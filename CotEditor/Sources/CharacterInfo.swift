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
//  © 2015-2024 1024jp
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

private enum EmojiVariationSelector: UInt32 {
    
    case text = 0xFE0E
    case emoji = 0xFE0F
    
    
    var label: String {
        
        switch self {
            case .emoji:
                String(localized: "EmojiVariationSelector.emoji.label",
                       defaultValue: "Emoji Style",
                       table: "Character",
                       comment: "label for the Unicode variation selector that forces to draw the character in the emoji style")
            case .text:
                String(localized: "EmojiVariationSelector.text.label",
                       defaultValue: "Text Style",
                       table: "Character",
                       comment: "label for the Unicode variation selector that forces to draw the character in the text style")
        }
    }
}


private enum SkinToneModifier: UInt32 {
    
    case type12 = 0x1F3FB  // 🏻 Light
    case type3 = 0x1F3FC   // 🏼 Medium Light
    case type4 = 0x1F3FD   // 🏽 Medium
    case type5 = 0x1F3FE   // 🏾 Medium Dark
    case type6 = 0x1F3FF   // 🏿 Dark
    
    
    var label: String {
        
        switch self {
            case .type12:
                String(localized: "SkinToneModifier.type12.label",
                       defaultValue: "Skin Tone I-II",
                       table: "Character",
                       comment: "label for Unicode emoji modifier applying the skin tone to the character")
            case .type3:
                String(localized: "SkinToneModifier.type3.label",
                       defaultValue: "Skin Tone III",
                       table: "Character",
                       comment: "label for Unicode emoji modifier applying the skin tone to the character")
            case .type4:
                String(localized: "SkinToneModifier.type4.label",
                       defaultValue: "Skin Tone IV",
                       table: "Character",
                       comment: "label for Unicode emoji modifier applying the skin tone to the character")
            case .type5:
                String(localized: "SkinToneModifier.type5.label",
                       defaultValue: "Skin Tone V",
                       table: "Character",
                       comment: "label for Unicode emoji modifier applying the skin tone to the character")
            case .type6:
                String(localized: "SkinToneModifier.type6.label",
                       defaultValue: "Skin Tone VI",
                       table: "Character",
                       comment: "label for Unicode emoji modifier applying the skin tone to the character")
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
            return String(localized: "<a letter consisting of \(unicodes.count) characters>",
                          table: "Character",
                          comment: "%lld is always 2 or more.")
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


private extension Unicode.Scalar {
    
    var variantDescription: String? {
        
        if let selector = EmojiVariationSelector(rawValue: self.value) {
            selector.label
            
        } else if let modifier = SkinToneModifier(rawValue: self.value) {
            modifier.label
            
        } else if self.properties.isVariationSelector {
            String(localized: "Variant",
                   table: "Character",
                   comment: "label for general Unicode variation selectors")
            
        } else {
            nil
        }
    }
}
