//
//  Unicode.Scalar+Variant.swift
//  CharacterInfo
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

public extension Unicode.Scalar {
    
    /// The description about the Unicode variant selector if the scalar is a variant selector.
    var variantDescription: String? {
        
        if let selector = EmojiVariationSelector(rawValue: self.value) {
            selector.label
            
        } else if let modifier = SkinToneModifier(rawValue: self.value) {
            modifier.label
            
        } else if self.properties.isVariationSelector {
            String(localized: "Variant",
                   bundle: .module,
                   comment: "label for general Unicode variation selectors")
            
        } else {
            nil
        }
    }
}


private enum EmojiVariationSelector: UInt32 {
    
    case text = 0xFE0E
    case emoji = 0xFE0F
    
    
    var label: String {
        
        switch self {
            case .emoji:
                String(localized: "EmojiVariationSelector.emoji.label",
                       defaultValue: "Emoji Style",
                       bundle: .module,
                       comment: "label for the Unicode variation selector that forces to draw the character in the emoji style")
            case .text:
                String(localized: "EmojiVariationSelector.text.label",
                       defaultValue: "Text Style",
                       bundle: .module,
                       comment: "label for the Unicode variation selector that forces to draw the character in the text style")
        }
    }
}
