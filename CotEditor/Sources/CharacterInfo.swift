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
//  © 2015-2021 1024jp
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
        
        guard self.properties.isVariationSelector else { return nil }
        
        switch self {
            case EmojiVariationSelector.emoji:
                return "Emoji Style"
            case EmojiVariationSelector.text:
                return "Text Style"
            case SkinToneModifier.type12:
                return "Skin Tone I-II"
            case SkinToneModifier.type3:
                return "Skin Tone III"
            case SkinToneModifier.type4:
                return "Skin Tone IV"
            case SkinToneModifier.type5:
                return "Skin Tone V"
            case SkinToneModifier.type6:
                return "Skin Tone VI"
            default:
                return "Variant"
        }
    }
    
}



// MARK: -

struct CharacterInfo {
    
    // MARK: Public Properties
    
    let character: Character
    let isComplex: Bool
    let pictureString: String?
    let localizedDescription: String
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(_ character: Character) {
        
        let unicodes = character.unicodeScalars
        let isVariant = (unicodes.count == 2 && unicodes.last!.properties.isVariationSelector)
        let isComplex = (unicodes.count > 1 && !isVariant)
        
        self.character = character
        self.isComplex = isComplex
        
        self.pictureString = unicodes.count == 1  // ignore CRLF
            ? unicodes.first?.pictureRepresentation.flatMap { String($0) }
            : nil
        
        self.localizedDescription = {
            if isComplex {
                return String(format: "<a letter consisting of %d characters>".localized(tableName: "Unicode"), unicodes.count)
            }
            
            guard var unicodeName = unicodes.first?.name else { return String(character) }
            
            if isVariant, let variantDescription = unicodes.last?.variantDescription {
                unicodeName += " (" + variantDescription.localized(tableName: "Unicode") + ")"
            }
            
            return unicodeName
        }()
    }
    
}



extension CharacterInfo: CustomStringConvertible {
    
    var description: String {
        
        String(self.character)
    }
    
}
