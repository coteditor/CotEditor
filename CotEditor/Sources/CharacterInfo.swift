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
    
    // presentation selectors
    static let textSequence = Unicode.Scalar(0xFE0E)!
    static let emojiSequence = Unicode.Scalar(0xFE0F)!
    
    
    enum SkinToneModifier {
        
        static let type12 = Unicode.Scalar(0x1F3FB)!  // 🏻 Light
        static let type3 = Unicode.Scalar(0x1F3FC)!  // 🏼 Medium Light
        static let type4 = Unicode.Scalar(0x1F3FD)!  // 🏽 Medium
        static let type5 = Unicode.Scalar(0x1F3FE)!  // 🏾 Medium Dark
        static let type6 = Unicode.Scalar(0x1F3FF)!  // 🏿 Dark
    }
    
}



// MARK: -

struct CharacterInfo {
    
    enum `Error`: Swift.Error {
        
        case notSingleCharacter
    }
    
    
    // MARK: Public Properties
    
    let string: String
    let pictureString: String?
    let isComplex: Bool
    let localizedDescription: String
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(string: String) throws {
        
        guard string.compareCount(with: 1) == .equal else {
            throw Error.notSingleCharacter
        }
        
        let unicodes = string.unicodeScalars
        
        self.string = string
        
        // check variation selector
        let additional: String? = {
            guard unicodes.count == 2, let lastUnicode = unicodes.last else { return nil }
            
            switch lastUnicode {
                case Unicode.Scalar.emojiSequence:
                    return "Emoji Style"
                case Unicode.Scalar.textSequence:
                    return "Text Style"
                case Unicode.Scalar.SkinToneModifier.type12:
                    return "Skin Tone I-II"
                case Unicode.Scalar.SkinToneModifier.type3:
                    return "Skin Tone III"
                case Unicode.Scalar.SkinToneModifier.type4:
                    return "Skin Tone IV"
                case Unicode.Scalar.SkinToneModifier.type5:
                    return "Skin Tone V"
                case Unicode.Scalar.SkinToneModifier.type6:
                    return "Skin Tone VI"
                case let unicode where unicode.properties.isVariationSelector:
                    return "Variant"
                default:
                    return nil
            }
        }()
        let isComplex = (unicodes.count > 1 && additional == nil)
        
        self.isComplex = isComplex
        
        self.pictureString = unicodes.count == 1  // ignore CRLF
            ? unicodes.first?.pictureRepresentation.flatMap { String($0) }
            : nil
        
        self.localizedDescription = {
            // number of characters message
            if isComplex {
                return String(format: "<a letter consisting of %d characters>".localized(tableName: "Unicode"), unicodes.count)
            }
            
            // unicode character name
            guard var unicodeName = unicodes.first?.name else { return string }
            
            if let additional = additional {
                unicodeName += " (" + additional.localized(tableName: "Unicode") + ")"
            }
            
            return unicodeName
        }()
    }
    
}



extension CharacterInfo: CustomStringConvertible {
    
    var description: String {
        
        return self.string
    }
    
}
