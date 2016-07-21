/*
 
 CharacterInfo.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-11-19.
 
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

struct SkinToneEmojiModifier {
    
    static let type12 = UnicodeScalar(0x1F3FB)  // 🏻 Light
    static let type3  = UnicodeScalar(0x1F3FC)  // 🏼 Medium Light
    static let type4  = UnicodeScalar(0x1F3FD)  // 🏽 Medium
    static let type5  = UnicodeScalar(0x1F3FE)  // 🏾 Medium Dark
    static let type6  = UnicodeScalar(0x1F3FF)  // 🏿 Dark
}


extension UnicodeScalar {
    
    // variant selectors
    static let textSequence = UnicodeScalar(0xFE0E)
    static let emojiSequence = UnicodeScalar(0xFE0F)
    
    var isVariantSelector: Bool {
        
        let codePoint = self.value
        return ((codePoint >= 0x180B && codePoint <= 0x180D) ||
                (codePoint >= 0xFE00 && codePoint <= 0xFE0F) ||
                (codePoint >= 0xE0100 && codePoint <= 0xE01EF))
    }
    
}


// MARK:

class CharacterInfo: CustomDebugStringConvertible {  // TODO: struct?
    
    // MARK: Public Properties

    let string: String
    let pictureString: String?
    let unicodes: [CEUnicodeCharacter]
    let isComplex: Bool
    
    
    // MARK: Private Properties
    
    private let variationSelectorAdditional: String?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init?(string: String) {
        
        guard string.numberOfComposedCharacters() == 1 || string == "\r\n" else { return nil }
        // -> Number of String.characters.count and numberOfComposedCharacters are different.
        
        self.string = string
        self.unicodes = string.unicodes
        
        // check variation selector
        var additional: String?
        var isComplex = false
        if self.unicodes.count ==  2 {
            let scalar = UnicodeScalar(unicodes.last!.character)
            
            switch (scalar) {
            case UnicodeScalar.emojiSequence:
                additional = "Emoji Style"
                
            case UnicodeScalar.textSequence:
                additional = "Text Style"
                
            case SkinToneEmojiModifier.type12:
                additional = "Skin Tone I-II"
                
            case SkinToneEmojiModifier.type3:
                additional = "Skin Tone III"
                
            case SkinToneEmojiModifier.type4:
                additional = "Skin Tone IV"
                
            case SkinToneEmojiModifier.type5:
                additional = "Skin Tone V"
                
            case SkinToneEmojiModifier.type6:
                additional = "Skin Tone VI"
            default:
                if scalar.isVariantSelector {
                    additional = "Variant"
                } else {
                    isComplex = true
                }
            }
            
        } else if self.unicodes.count > 2 {
            isComplex = true
        }
        self.variationSelectorAdditional = additional
        self.isComplex = isComplex
        
        var pictureString: String?
        if self.unicodes.count == 1 {  // ignore CR/LF
            if let pictureCharacter = self.unicodes.first?.pictureCharacter, pictureCharacter != 0 {
                let scalar = UnicodeScalar(pictureCharacter)
                pictureString = String(scalar)
            }
        }
        self.pictureString = pictureString
    }
    
    
    var debugDescription: String {
        
        return "<\(self): \(self.string)>"
    }
    
    
    
    // MARK: Public Properties
    
    /// create human-readable description
    lazy var localizedDescription: String = {
        
        // number of characters message
        if self.isComplex {
            return String(format: NSLocalizedString("<a letter consisting of %d characters>", tableName: "Unicode", comment: ""), self.unicodes.count)
        }
        
        // unicode character name
        var unicodeName = self.unicodes.first!.name
        if let additional = self.variationSelectorAdditional {
            unicodeName += " (" + NSLocalizedString(additional, tableName: "Unicode", comment: "") + ")"
        }
        
        return unicodeName
    }()
    
}



private extension String {
    
    /// devide given string into UnicodeCharacter objects
    var unicodes: [CEUnicodeCharacter] {
        
        return self.unicodeScalars.map { CEUnicodeCharacter(character: $0.value) }
    }
    
}
